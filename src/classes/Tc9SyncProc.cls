public class Tc9SyncProc extends AbstractProcessor implements Database.Batchable<SObject>, Database.Stateful{

    public String batchId;
    public Batch__c batch;
    public maica_cc__Timesheet_Entry__c originalTse;

    public Tc9SyncProc() {
    }
    public Tc9SyncProc(String batchId) {
        this.batchId = batchId;
        this.batch = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
                WHERE Id = :batchId
        ],'No Batch__c with Id: ' + batchId);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM maica_cc__Timesheet_Entry__c ' +
                'WHERE Batch__c = :batchId ' +
                'AND maica_cc__Start_Time__c != NULL ' +
                'AND maica_cc__End_Time__c != NULL ' +
                'AND Timesheet_Entry_2C9__c = NULL ' +
                'AND Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        for (SObject record : records) {
            Response response = new Tc9SyncProc().process(
                    new Map<String, Object>{
                            'tseId' => record.Id,
                            'bcId' => ('' + bc?.getJobId()).left(15)
                    }
            );
        }
    }

    public void finish(Database.BatchableContext BC) {
        List<maica_cc__Timesheet_Entry__c> failedTSEs = [
                SELECT Id
                FROM maica_cc__Timesheet_Entry__c
                WHERE TC9_Sync_Status__c = 'Failed'
        ];
        if(failedTSEs.isEmpty()){
            this.batch.Status__c = 'Synced';
            this.batch.Sync_Date__c = Date.today();
            update this.batch;
        }
    }

    public override Response process(Request request) {
        this.request = request;
        if (String.isNotBlank(this.request.getString('batchId'))) {
            String jobId = Database.executeBatch(
                    new Tc9SyncProc(this.request.getString('batchId')),
                    Utils.objects.defaultIfNull(this.request.getInteger('batchSize'), 1)
            );
            this.response.put('jobId', jobId);
        } else {
            try {
                this.processSync();
            } catch (Exception e) {
                this.updateTSEs('Failed', e.getMessage() + '\n' + e.getStackTraceString(), null);
                insert new maica_cc__Log__c(
                        maica_cc__Details__c = e.getMessage() + '\n' + e.getStackTraceString(),
                        maica_cc__Job_Id__c = this.request.getString('bcId'),
                        maica_cc__Source__c = 'Sync TSEs Process',
                        maica_cc__Type__c = 'Error',
                        maica_cc__Processor__c = 'Tc9SyncProc',
                        maica_cc__Payload__c = JSON.serialize(new Map<String, Object>{
                                'tseId' => this.request.getString('tseId')
                        })
                );
            }
        }
        return this.response;
    }

    private void processSync() {
        String originalTseId = this.request.getRequiredString('tseId');
        this.originalTse = getOriginalTSE(originalTseId);
        if (String.isNotBlank(this.originalTse.Merge_Target_Timesheet_Entry__c)) {
            this.originalTse = getOriginalTSE(this.originalTse.Merge_Target_Timesheet_Entry__c);
            if (String.isNotBlank(this.originalTse.Timesheet_Entry_2C9__c)) return;
        }

        String payeeId = this.originalTse.maica_cc__Timesheet__r?.maica_cc__Resource__r?.Payee__c;
        String employeeId = this.originalTse.maica_cc__Timesheet__r?.maica_cc__Resource__r?.Employee__c;

        //get 2C9 Timesheet
        tc9_et__Timesheet__c timesheet2c9 = (tc9_et__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM tc9_et__Timesheet__c
                WHERE tc9_et__Approval_Status__c = 'New'
                AND tc9_et__Payee__c = :payeeId
                AND tc9_et__Employee__c = :employeeId
                AND tc9_et__Start_Date__c <= :this.originalTse.maica_cc__Start_Time__c.date()
                AND tc9_et__End_Date__c >= :this.originalTse.maica_cc__End_Time__c.date()
        ], 'No matched tc9_et__Timesheet__c for maica_cc__Timesheet_Entry__c with Id:' + originalTseId);
        //get 2C9 Assignment
        tc9_pr__Assignment__c assignment2c9 = (tc9_pr__Assignment__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM tc9_pr__Assignment__c
                WHERE tc9_pr__Status__c = 'Active'
                AND tc9_pr__Payee__c = :payeeId
                AND tc9_pr__Employee__c = :employeeId
        ], 'No matched tc9_pr__Assignment__c for maica_cc__Timesheet_Entry__c with Id:' + originalTseId);

        //create 2C9 Timesheet Entry
        tc9_et__Timesheet_Entry__c tse2c9 = new tc9_et__Timesheet_Entry__c(
                tc9_et__Payee__c = payeeId,
                tc9_et__Approval_Flag__c = true,
                tc9_et__Submitted_Flag__c = true,
                tc9_et__Employee__c = employeeId,
                tc9_et__Timesheet__c = timesheet2c9.Id,
                tc9_et__Assignment__c = assignment2c9.Id,
                tc9_et__Submitted_Date__c = Datetime.now(),
                tc9_et__Total_Hours__c = this.originalTse.Duration_Hours__c,
                tc9_et__Employee_Notes__c = this.originalTse.maica_cc__Notes__c,
                tc9_et__End_Date__c = this.originalTse.maica_cc__End_Time__c.date(),
                tc9_et__End_Time__c = this.originalTse.maica_cc__End_Time__c.time(),
                tc9_et__Start_Date__c = this.originalTse.maica_cc__Start_Time__c.date(),
                tc9_et__Start_Time__c = this.originalTse.maica_cc__Start_Time__c.time()
        );
        if (String.isNotBlank(this.originalTse.Allowance_Type__c)) {
            //get 2C9 Project Code
            tc9_pr__Project_Code__c projectCode2c9 = (tc9_pr__Project_Code__c) Utils.arrays.firstOrException([
                    SELECT Id
                    FROM tc9_pr__Project_Code__c
                    WHERE tc9_pr__Status__c = 'Active'
                    AND tc9_pr__Assignment__c = :assignment2c9.Id
                    AND tc9_et__Interpretation_Breakpoint_Type__c = 'Sleepover'
            ], 'No matched tc9_pr__Project_Code__c for maica_cc__Timesheet_Entry__c with Id:' + originalTseId);
            tse2c9.tc9_et__Timesheet_Activity__c = projectCode2c9.Id;
        }
        if (this.originalTse.Break_1_Start__c != null && this.originalTse.Break_1_End__c != null) {
            tse2c9.tc9_et__Break_1_Paid__c = 'Yes';
            tse2c9.tc9_et__Break_1_End_Time__c = this.originalTse.Break_1_End__c;
            tse2c9.tc9_et__Break_1_Total__c = this.originalTse.Break_1_Duration__c;
            tse2c9.tc9_et__Break_1_Start_Time__c = this.originalTse.Break_1_Start__c;
        }
        if (this.originalTse.Break_2_Start__c != null && this.originalTse.Break_2_End__c != null) {
            tse2c9.tc9_et__Break_2_Paid__c = 'Yes';
            tse2c9.tc9_et__Break_2_End_Time__c = this.originalTse.Break_2_End__c;
            tse2c9.tc9_et__Break_2_Total__c = this.originalTse.Break_2_Duration__c;
            tse2c9.tc9_et__Break_2_Start_Time__c = this.originalTse.Break_2_Start__c;
        }
        insert tse2c9;

        //TODO: create 2C9 Timesheet Item
//        if ('Inactive Sleepover'.equals(this.originalTse.Allowance_Type__c) && this.originalTse.Break_1_Start__c != null) {
//            RecordType costCodeRecordType = (RecordType) Utils.arrays.firstOrNull([
//                    SELECT Id, DeveloperName
//                    FROM RecordType
//                    WHERE SobjectType = 'tc9_et__Timesheet_Item__c'
//                    AND DeveloperName = 'Cost_Code'
//            ]);
//
//            tc9_et__Timesheet_Item__c tsi2c9 = new tc9_et__Timesheet_Item__c(
//                    tc9_et__Timesheet__c = timesheet2c9.Id,
//                    tc9_bgl__Timesheet_Entry__c = tse2c9.Id,
//                    RecordTypeId = costCodeRecordType?.Id
//            );
//            insert tsi2c9;
//        }
        this.updateTSEs('Complete', null, tse2c9.Id);
    }

    private void updateTSEs(String status, String errorDetails, Id tse2C9Id) {
        if(this.originalTse != null){
            this.originalTse.TC9_Sync_Status__c = status;
            this.originalTse.Sync_Failure_Details__c = errorDetails;
            this.originalTse.Timesheet_Entry_2C9__c = tse2C9Id;
            update this.originalTse;

            if (this.originalTse.Merged_Timesheet_Entry__c) {
                List<maica_cc__Timesheet_Entry__c> sourceTSEs = [
                        SELECT Id
                        FROM maica_cc__Timesheet_Entry__c
                        WHERE Merge_Target_Timesheet_Entry__c = :this.originalTse.Id
                ];
                for (maica_cc__Timesheet_Entry__c tse : sourceTSEs) {
                    tse.TC9_Sync_Status__c = status;
                }
                update sourceTSEs;
            }
        }
    }

    private static maica_cc__Timesheet_Entry__c getOriginalTSE(Id tseId) {
        return (maica_cc__Timesheet_Entry__c) Utils.arrays.firstOrException([
                SELECT Id,
                        Break_1_End__c,
                        Break_2_End__c,
                        Break_2_Start__c,
                        Break_1_Start__c,
                        Allowance_Type__c,
                        Duration_Hours__c,
                        maica_cc__Notes__c,
                        Break_1_Duration__c,
                        Break_2_Duration__c,
                        maica_cc__End_Time__c,
                        Timesheet_Entry_2C9__c,
                        maica_cc__Start_Time__c,
                        Merged_Timesheet_Entry__c,
                        Merge_Target_Timesheet_Entry__c,
                        maica_cc__Timesheet__r.maica_cc__Resource__r.Payee__c,
                        maica_cc__Timesheet__r.maica_cc__Resource__r.Employee__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE Id = :tseId
        ], 'No maica_cc__Timesheet_Entry__c with Id: ' + tseId);
    }
}