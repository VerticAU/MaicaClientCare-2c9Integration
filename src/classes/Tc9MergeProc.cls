public class Tc9MergeProc extends AbstractProcessor implements Database.Batchable<SObject> {

    private String batchId;
    private UnitOfWork uow = new UnitOfWork(
            new List<SObjectType>{
                    maica_cc__Timesheet_Entry__c.SObjectType
            }
    );

    public Tc9MergeProc(){}
    public Tc9MergeProc(String batchId){
        this.batchId = batchId;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('' +
                'SELECT Id, maica_cc__Resource__c ' +
                'FROM maica_cc__Timesheet__c ' +
                'WHERE maica_cc__Status__c = \'Approved\' ' +
                'AND Id IN (' +
                'SELECT maica_cc__Timesheet__c ' +
                'FROM maica_cc__Timesheet_Entry__c ' +
                'WHERE Batch__c = :batchId ' +
                'AND Timesheet_Entry_2C9__c = NULL ' +
                'AND Merged_Timesheet_Entry__c = FALSE ' +
                'AND (Merge_Target_Timesheet_Entry__c = NULL OR Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL) ' +
                ')' +
                '');
    }

    public void execute(Database.BatchableContext BC, List<SObject> records) {
        for (SObject record : records) {
            Response response = new Tc9MergeProc().process(
                    new Map<String, Object>{
                            'tsId' => record.Id,
                            'resourceId' => ((maica_cc__Timesheet__c) record).maica_cc__Resource__c
                    }
            );
        }
    }

    public void finish(Database.BatchableContext BC) {}

    public override Response process(Request request) {
        this.request = request;
        if (this.request.getBoolean('isScheduled') == true) {
            Database.executeBatch(new Tc9MergeProc(this.request.getRequiredString('batchId')), 1);
        } else {
            this.processMerge();
        }
        return this.response;
    }

    private void processMerge() {
        String tsId = this.request.getRequiredString('tsId');
        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        Decimal mergeThreshold = Utils.objects.defaultIfNull(setting.Merge_Threshold__c, 60);
        List<maica_cc__Timesheet_Entry__c> mergedTSEs = new List<maica_cc__Timesheet_Entry__c>();

        List<maica_cc__Timesheet_Entry__c> mergedTSEsToDelete = [
                SELECT Id, maica_cc__Start_Time__c, maica_cc__End_Time__c,
                        maica_cc__Appointment__r.Allowance_Type__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :tsId
                AND Merged_Timesheet_Entry__c = TRUE
                AND Timesheet_Entry_2C9__c = NULL
        ];
        delete mergedTSEsToDelete;

        List<maica_cc__Timesheet_Entry__c> sourceTimesheetEntries = [
                SELECT Id, maica_cc__Start_Time__c, maica_cc__End_Time__c,
                        maica_cc__Appointment__r.Allowance_Type__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :tsId
                AND Merge_Target_Timesheet_Entry__c = NULL
                AND maica_cc__Start_Time__c != NULL
                AND maica_cc__End_Time__c != NULL
                AND Timesheet_Entry_2C9__c = NULL
                ORDER BY maica_cc__Start_Time__c ASC
        ];

        maica_cc__Timesheet_Entry__c mergedTse;
        for (maica_cc__Timesheet_Entry__c currentTse : sourceTimesheetEntries) {
            if (mergedTse == null || ((currentTse.maica_cc__Start_Time__c.getTime() - mergedTse.maica_cc__End_Time__c.getTime()) / (1000 * 60) > mergeThreshold)) {
                mergedTse = new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = tsId,
                        maica_cc__Start_Time__c = currentTse.maica_cc__Start_Time__c,
                        maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c,
                        Merged_Timesheet_Entry__c = true,
                        Allowance_Type__c = currentTse.maica_cc__Appointment__r?.Allowance_Type__c
                );
                mergedTSEs.add(mergedTse);
                uow.registerNew(mergedTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merge_Target_Timesheet_Entry__c, mergedTse);
            } else {
                mergedTse.maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c;
                mergedTse.Allowance_Type__c = String.isBlank(mergedTse.Allowance_Type__c)
                        ? currentTse.maica_cc__Appointment__r?.Allowance_Type__c
                        : mergedTse.Allowance_Type__c;
                uow.registerUpsert(currentTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merge_Target_Timesheet_Entry__c, mergedTse);
            }
        }

        uow.commitWork();
        this.response.put('mergedTSEs', mergedTSEs);
    }
}