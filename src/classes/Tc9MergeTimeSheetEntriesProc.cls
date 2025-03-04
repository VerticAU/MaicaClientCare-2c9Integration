public class Tc9MergeTimeSheetEntriesProc extends AbstractProcessor {

    private UnitOfWork uow = new UnitOfWork(
            new List<SObjectType>{
                    maica_cc__Timesheet_Entry__c.SObjectType
            }
    );

    public override Response process(Request request) {
        this.request = request;
        this.doSubmit();
        return this.response;
    }

    private void doSubmit() {
        String tsId = this.request.getRequiredString('tsId');
        String resourceId = this.request.getRequiredString('resourceId');

        Datetime startTime;
        Datetime endTime;

        //TODO
//        maica_cc__Setting__c integrationSetting = maica_cc.MaicaSetting.integration;
//        Decimal mergeThreshold = Utils.objects.defaultIfNull(integrationSetting.Merge_Threshold__c, 60); //minutes
        Decimal mergeThreshold = 60;

        List<maica_cc__Timesheet_Entry__c> timesheetEntries = this.retrieveTimesheetEntries(tsId);

        if (timesheetEntries.size() > 0) {
            startTime = timesheetEntries[0].maica_cc__Start_Time__c;
            endTime = timesheetEntries[timesheetEntries.size() - 1].maica_cc__End_Time__c;
        }

        maica_cc__Timesheet_Entry__c mergedTse;
        List<maica_cc__Timesheet_Entry__c> mergedTses = new List<maica_cc__Timesheet_Entry__c>();

        for (maica_cc__Timesheet_Entry__c currentTse : timesheetEntries) {
            currentTse.TC9_Sync_Status__c = 'Merge Processed';
            currentTse.Sync_Failure_Details__c = null;
            if (mergedTse == null || ((currentTse.maica_cc__Start_Time__c.getTime() - mergedTse.maica_cc__End_Time__c.getTime()) / (1000 * 60) > mergeThreshold)) {
                mergedTse = new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = tsId,
                        maica_cc__Start_Time__c = currentTse.maica_cc__Start_Time__c,
                        maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c,
                        Merge_Processed__c = true
//                        Allowance_Type__c = currentTse.maica_cc__Appointment__r?.Allowance_Type__c
                );

                mergedTses.add(mergedTse);
                uow.registerNew(mergedTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merged_Timesheet_Entry__c, mergedTse);

            } else {
                //TODO: on/off based on the setting Break Processor Mode
//                if('Fill Gaps'.equals(integrationSetting.maica_cc__Break_Processor_Mode__c)){
                if (mergedTse.Break_1_Start__c == null && mergedTse.Break_1_End__c == null) {
                    mergedTse.Break_1_Start__c = mergedTse.maica_cc__End_Time__c.time();
                    mergedTse.Break_1_End__c = currentTse.maica_cc__Start_Time__c.time();
                } else if (mergedTse.Break_2_Start__c == null && mergedTse.Break_2_End__c == null) {
                    mergedTse.Break_2_Start__c = mergedTse.maica_cc__End_Time__c.time();
                    mergedTse.Break_2_End__c = currentTse.maica_cc__Start_Time__c.time();
                }
//                }

                mergedTse.maica_cc__End_Time__c = currentTse.maica_cc__End_Time__c;
//                mergedTse.Allowance_Type__c = String.isBlank(mergedTse.Allowance_Type__c)
//                        ? currentTse.maica_cc__Appointment__r?.Allowance_Type__c
//                        : mergedTse.Allowance_Type__c;

                uow.registerUpsert(currentTse);
                uow.registerHierarchy(currentTse, maica_cc__Timesheet_Entry__c.Merged_Timesheet_Entry__c, mergedTse);
            }
        }

        //TODO: on/off based on the setting Break Processor Mode
//        if ('Reference Unavailability'.equals(integrationSetting.maica_cc__Break_Processor_Mode__c)) {
        if (startTime != null && endTime != null) {
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

            for (maica_cc__Unavailability__c unavailability : unavailabilityList) {
                for (maica_cc__Timesheet_Entry__c tse : mergedTses) {
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
            }
        }
//        }

        try {
            uow.commitWork();
            this.response.put('mergedTses', mergedTses);
        } catch (Exception ex) {
            List<maica_cc__Timesheet_Entry__c> originalTses = this.retrieveTimesheetEntries(tsId);
            for (maica_cc__Timesheet_Entry__c originalTse : originalTses) {
                originalTse.TC9_Sync_Status__c = 'Merge Failed';
                originalTse.Sync_Failure_Details__c = ex.getMessage();
            }
            update originalTses;
        }
    }

    private List<maica_cc__Timesheet_Entry__c> retrieveTimesheetEntries(Id tsId) {
        //TODO: create Timesheet_Entry_2C9__c field
        String soql = '' +
                'SELECT Id, maica_cc__Start_Time__c, maica_cc__End_Time__c, maica_cc__Appointment__r.Allowance_Type__c\n' +
                'FROM maica_cc__Timesheet_Entry__c\n' +
                'WHERE maica_cc__Timesheet__c = :tsId\n' +
                'AND Merged_Timesheet_Entry__c = NULL\n' +
                'AND maica_cc__Start_Time__c != NULL\n' +
                'AND maica_cc__End_Time__c != NULL\n' +
                'AND maica_cc__End_Time__c < :today\n' +
                'AND Merge_Processed__c = FALSE\n' +
                'AND Timesheet_Entry_2C9__c = NULL\n' +
                'ORDER BY maica_cc__Start_Time__c ASC\n';

        return Tc9Service.query(soql, new Map<String, Object>{
                'tsId' => tsId,
                'today' => Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0))
        });
    }
}