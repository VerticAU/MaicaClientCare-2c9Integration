public class Tc9BreakProc extends AbstractProcessor implements Database.Batchable<SObject> {

    public String batchId;

    public Tc9BreakProc() {
    }

    public Tc9BreakProc(String batchId) {
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
                'AND maica_cc__Start_Time__c != NULL ' +
                'AND maica_cc__End_Time__c != NULL ' +
                'AND Timesheet_Entry_2C9__c = NULL ' +
                'AND Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL' +
                ')' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        for (SObject record : records) {
            Response response = new Tc9BreakProc().process(
                    new Map<String, Object>{
                            'tsId' => record.Id,
                            'bcId' => ('' + bc?.getJobId()).left(15),
                            'resourceId' => ((maica_cc__Timesheet__c) record).maica_cc__Resource__c
                    }
            );
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public override Response process(Request request) {
        this.request = request;
        if (String.isNotBlank(this.request.getString('batchId'))) {
            String jobId = Database.executeBatch(new Tc9BreakProc(this.request.getString('batchId')), 1);
            this.response.put('jobId', jobId);
        } else {
            try {
                this.processBreak();
            } catch (Exception e) {
                maica_cc__Log__c logVar = new maica_cc__Log__c(
                        maica_cc__Details__c = e.getMessage() + '\n' + e.getStackTraceString(),
                        maica_cc__Job_Id__c = this.request.getString('bcId'),
                        maica_cc__Source__c = 'Break TSEs Process',
                        maica_cc__Type__c = 'Error',
                        maica_cc__Processor__c = 'Tc9BreakProc',
                        maica_cc__Payload__c = JSON.serialize(new Map<String, Object>{
                                'tsId' => this.request.getString('tsId')
                        })
                );
                insert logVar;
            }
        }
        return this.response;
    }

    private void processBreak() {
        Datetime startTime;
        Datetime endTime;
        String tsId = this.request.getRequiredString('tsId');
        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        String resourceId = this.request.getRequiredString('resourceId');
        String breakProcessMode = Utils.objects.defaultIfNull(setting.Break_Processor_Mode__c, 'Reference Unavailability');

        List<maica_cc__Timesheet_Entry__c> TSEs = [
                SELECT Id, maica_cc__Start_Time__c, maica_cc__End_Time__c,
                        Merged_Timesheet_Entry__c, Merge_Target_Timesheet_Entry__c,
                        Break_1_End__c, Break_1_Start__c, Break_2_Start__c, Break_2_End__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :tsId
                AND maica_cc__Start_Time__c != NULL
                AND maica_cc__End_Time__c != NULL
                AND Timesheet_Entry_2C9__c = NULL
                AND Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL
                ORDER BY maica_cc__Start_Time__c ASC
        ];

        for (maica_cc__Timesheet_Entry__c tse : TSEs) {
            startTime = startTime == null || startTime > tse.maica_cc__Start_Time__c ? tse.maica_cc__Start_Time__c : startTime;
            endTime = endTime == null || endTime < tse.maica_cc__End_Time__c ? tse.maica_cc__End_Time__c : endTime;
        }

        List<maica_cc__Unavailability__c> unavailabilityList = [
                SELECT Id, maica_cc__Unavailable_From__c, maica_cc__Unavailable_To__c
                FROM maica_cc__Unavailability__c
                WHERE (maica_cc__Type__c = 'Appointment Break'
                OR maica_cc__Type__c = 'Unpaid Break')
                AND maica_cc__Resource__c = :resourceId
                AND maica_cc__Unavailable_From__c >= :startTime
                AND maica_cc__Unavailable_To__c <= :endTime
                ORDER BY maica_cc__Unavailable_From__c ASC
        ];

        List<maica_cc__Timesheet_Entry__c> TSEsToUpdate = new List<maica_cc__Timesheet_Entry__c>();
        Map<String, List<SObject>> sourceTSEsByMergedTSEMap = Utils.sObjects.getSObjectsListByAnyFieldMap(TSEs, maica_cc__Timesheet_Entry__c.Merge_Target_Timesheet_Entry__c);

        for (maica_cc__Timesheet_Entry__c tse : TSEs) {
            if ('Fill Gaps'.equals(breakProcessMode) && tse.Merged_Timesheet_Entry__c == true) {
                List<maica_cc__Timesheet_Entry__c> relatedTSEs = sourceTSEsByMergedTSEMap.get(tse.Id);
                if (relatedTSEs.size() > 1) {
                    for (maica_cc__Timesheet_Entry__c sourceTSE : relatedTSEs) {
                        if (tse.Break_1_Start__c == null) {
                            tse.Break_1_Start__c = sourceTSE.maica_cc__End_Time__c.time();
                        } else if (tse.Break_1_End__c == null) {
                            tse.Break_1_End__c = sourceTSE.maica_cc__Start_Time__c.time();
                            if (relatedTSEs.size() > 2) {
                                tse.Break_2_Start__c = sourceTSE.maica_cc__End_Time__c.time();
                            }
                        } else if (tse.Break_2_Start__c != null && tse.Break_2_End__c == null) {
                            tse.Break_2_End__c = sourceTSE.maica_cc__Start_Time__c.time();
                        }
                    }
                    TSEsToUpdate.add(tse);
                }
            }
            if ('Reference Unavailability'.equals(breakProcessMode) && String.isBlank(tse.Merge_Target_Timesheet_Entry__c)) {
                for (maica_cc__Unavailability__c unavailability : unavailabilityList) {
                    if (unavailability.maica_cc__Unavailable_From__c >= tse.maica_cc__Start_Time__c && unavailability.maica_cc__Unavailable_To__c <= tse.maica_cc__End_Time__c) {
                        if (tse.Break_1_Start__c == null && tse.Break_1_End__c == null) {
                            tse.Break_1_Start__c = unavailability.maica_cc__Unavailable_From__c.time();
                            tse.Break_1_End__c = unavailability.maica_cc__Unavailable_To__c.time();

                        } else if (tse.Break_2_Start__c == null && tse.Break_2_End__c == null) {
                            tse.Break_2_Start__c = unavailability.maica_cc__Unavailable_From__c.time();
                            tse.Break_2_End__c = unavailability.maica_cc__Unavailable_To__c.time();
                        }
                    }
                }
                if(tse.Break_1_Start__c != null){
                    TSEsToUpdate.add(tse);
                }
            }
        }

        if (TSEsToUpdate.size() > 0) {
            update TSEsToUpdate;
        }
    }
}