public class Tc9MergeProc extends AbstractProcessor implements Database.Batchable<SObject> {
    public String batchId;

    public Tc9MergeProc() {
    }

    public Tc9MergeProc(String batchId) {
        this.batchId = batchId;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM maica_cc__Timesheet__c ' +
                'WHERE maica_cc__Status__c = \'Approved\' ' +
                'AND Id IN (' +
                'SELECT maica_cc__Timesheet__c ' +
                'FROM maica_cc__Timesheet_Entry__c ' +
                'WHERE Batch__c = :batchId ' +
                'AND maica_cc__End_Time__c != NULL ' +
                'AND maica_cc__Start_Time__c != NULL ' +
                'AND Merged_Timesheet_Entry__c = FALSE ' +
                'AND Timesheet_Entry_2C9__c = NULL ' +
                'AND Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL ' +
                ')' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        for (SObject record : records) {
            Response response = new Tc9MergeProc().process(
                    new Map<String, Object>{
                            'tsId' => record.Id,
                            'bcId' => ('' + bc?.getJobId()).left(15)
                    }
            );
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

    public override Response process(Request request) {
        this.request = request;
        if (String.isNotBlank(this.request.getString('batchId'))) {
            String jobId = Database.executeBatch(new Tc9MergeProc(this.request.getString('batchId')), 1);
            this.response.put('jobId', jobId);
        } else {
            try {
                this.processMerge();
            } catch (Exception e) {
                maica_cc__Log__c logVar = new maica_cc__Log__c(
                        maica_cc__Details__c = e.getMessage() + '\n' + e.getStackTraceString(),
                        maica_cc__Job_Id__c = this.request.getString('bcId'),
                        maica_cc__Source__c = 'Merge TSEs Process',
                        maica_cc__Type__c = 'Error',
                        maica_cc__Processor__c = 'Tc9MergeProc',
                        maica_cc__Payload__c = JSON.serialize(new Map<String, Object>{
                                'tsId' => this.request.getString('tsId')
                        })
                );
                insert logVar;
            }
        }
        return this.response;
    }

    private void processMerge() {
        UnitOfWork uow = new UnitOfWork(
                new List<SObjectType>{
                        maica_cc__Timesheet_Entry__c.SObjectType
                }
        );

        String tsId = this.request.getRequiredString('tsId');
        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        Decimal mergeThreshold = Utils.objects.defaultIfNull(setting.Merge_Threshold__c, 60);
        List<maica_cc__Timesheet_Entry__c> mergedTSEs = new List<maica_cc__Timesheet_Entry__c>();

        List<maica_cc__Timesheet_Entry__c> mergedTSEsToDelete = [
                SELECT Id
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :tsId
                AND Timesheet_Entry_2C9__c = NULL
                AND Merged_Timesheet_Entry__c = TRUE
        ];
        delete mergedTSEsToDelete;

        List<maica_cc__Timesheet_Entry__c> sourceTimesheetEntries = [
                SELECT Id, maica_cc__Start_Time__c, maica_cc__Notes__c,
                        maica_cc__End_Time__c, Allowance_Type__c, Batch__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :tsId
                AND maica_cc__End_Time__c != NULL
                AND Timesheet_Entry_2C9__c = NULL
                AND maica_cc__Start_Time__c != NULL
                AND Merge_Target_Timesheet_Entry__c = NULL
                ORDER BY maica_cc__Start_Time__c ASC
        ];

        maica_cc__Timesheet_Entry__c mergedTse;
        for (maica_cc__Timesheet_Entry__c currentTse : sourceTimesheetEntries) {
            if (mergedTse == null || ((currentTse.maica_cc__Start_Time__c.getTime() - mergedTse.maica_cc__End_Time__c.getTime()) / (1000 * 60) > mergeThreshold)) {
                mergedTse = new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = tsId,
                        Batch__c = currentTse.Batch__c,
                        Merged_Timesheet_Entry__c = true,
                        TC9_Sync_Status__c = 'Pending',
                        Allowance_Type__c = currentTse.Allowance_Type__c,
                        maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c,
                        maica_cc__Start_Time__c = currentTse.maica_cc__Start_Time__c,
                        maica_cc__Notes__c = String.isBlank(currentTse.maica_cc__Notes__c) ? '' : currentTse.maica_cc__Notes__c
                );
                mergedTSEs.add(mergedTse);
                uow.registerNew(mergedTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merge_Target_Timesheet_Entry__c, mergedTse);
            } else {
                mergedTse.maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c;
                mergedTse.Allowance_Type__c = String.isBlank(mergedTse.Allowance_Type__c)
                        ? currentTse.Allowance_Type__c
                        : mergedTse.Allowance_Type__c;
                mergedTse.maica_cc__Notes__c = mergedTse.maica_cc__Notes__c + (String.isBlank(currentTse.maica_cc__Notes__c) ? '' : currentTse.maica_cc__Notes__c);
                uow.registerUpsert(currentTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merge_Target_Timesheet_Entry__c, mergedTse);
            }
        }

        uow.commitWork();
        this.response.put('mergedTSEs', mergedTSEs);
    }
}