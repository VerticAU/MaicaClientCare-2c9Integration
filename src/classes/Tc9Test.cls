@IsTest
private class Tc9Test {

    @TestSetup
    static void setup() {
        Batch__c batchVar = new Batch__c(
                Start_Date__c = Date.newInstance(2025, 3, 1),
                End_Date__c = Date.newInstance(2025, 3, 31)
        );
        insert batchVar;

        maica_cc__Setting__c setting = new maica_cc__Setting__c(
                maica_cc__API_Name__c = Tc9Service.TC9_SETTING,
                Merge_Threshold__c = 60,
                Is_Merge_Processor_Enabled__c = true
        );
        insert setting;

        Contact contact = new Contact(
                LastName = 'Test'
        );
        insert contact;

        tc9_pr__Schedule__c schedule = new tc9_pr__Schedule__c(
                Name = 'Test',
                tc9_pr__Period_Type__c = 'Monthly',
                tc9_pr__Split_Option__c = 'No Split'
        );
        insert schedule;

        Account accountVar = new Account(
                Name = 'Test',
                tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank',
                tc9_pr__Maximum_Payment_Distributions__c = '1',
                tc9_pr__Schedule__c = schedule.Id,
                RecordTypeId = ((SObject) Utils.arrays.firstOrNull([SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Payment Entity'])).Id
        );
        insert accountVar;

        tc9_pr__Payee__c payee = new tc9_pr__Payee__c(
                tc9_pr__Employee__c = contact.Id,
                tc9_pr__Payment_Entity__c = accountVar.Id,
                tc9_pr__Schedule__c = schedule.Id
        );
        insert payee;

        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c(
                tc9_pr__Status__c = 'Active',
                tc9_pr__Payee__c = payee.Id,
                tc9_pr__Employee__c = contact.Id,
                tc9_pr__Client__c = accountVar.Id,
                tc9_pr__Schedule__c = schedule.Id,
                tc9_pr__Payment_Entity__c = accountVar.Id,
                tc9_pr__Assignment_Start_Date__c = Date.newInstance(2025, 3, 1)
        );
        insert assignment;

        tc9_et__Timesheet__c ts2c9 = new tc9_et__Timesheet__c(
                tc9_et__Approval_Status__c = 'New',
                tc9_et__Payee__c = payee.Id,
                tc9_et__Employee__c = contact.Id,
                tc9_et__Start_Date__c = Date.newInstance(2025, 3, 1),
                tc9_et__End_Date__c = Date.newInstance(2025, 3, 31),
                tc9_et__Assignment__c = assignment.Id
        );
        insert ts2c9;

        tc9_pr__Project_Code__c code = new tc9_pr__Project_Code__c(
                tc9_pr__Status__c = 'Active',
                tc9_pr__Assignment__c = assignment.Id,
                tc9_et__Interpretation_Breakpoint_Type__c = 'Sleepover'
        );
        insert code;

        maica_cc__Resource__c resource = new maica_cc__Resource__c(
                Name = 'Test',
                maica_cc__User__c = UserInfo.getUserId(),
                maica_cc__Roster_Mode__c = 'Appointment',
                Payee__c = payee.Id,
                Employee__c = contact.Id,
                maica_cc__Resource_Type__c = 'Resource',
                maica_cc__Employment_Type__c = 'Full-time',
                maica_cc__Weekly_Hours_Limit__c = 50,
                maica_cc__Daily_Hours_Limit__c = 8,
                maica_cc__Weekly_Hours_Minimum__c = 40
        );
        insert resource;

        maica_cc__Timesheet__c timesheet = new maica_cc__Timesheet__c(
                maica_cc__Resource__c = resource.Id,
                maica_cc__Start_Date__c = Date.newInstance(2025, 3, 1),
                maica_cc__End_Date__c = Date.newInstance(2025, 3, 15),
                maica_cc__Status__c = 'Approved'
        );
        insert timesheet;

        List<maica_cc__Timesheet_Entry__c> timesheetEntries = new List<maica_cc__Timesheet_Entry__c>{
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 9, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 10, 0, 0),
                        Batch__c = batchVar.Id
                ),
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 11, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 12, 0, 0),
                        Allowance_Type__c = 'Inactive Sleepover',
                        Batch__c = batchVar.Id
                ),
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 13, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 14, 0, 0),
                        Allowance_Type__c = 'Inactive Sleepover',
                        Batch__c = batchVar.Id
                ),
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        Allowance_Type__c = 'Inactive Sleepover',
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 15, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 16, 0, 0),
                        Batch__c = batchVar.Id
                ),
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 17, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 18, 0, 0),
                        Batch__c = batchVar.Id
                ),
                new maica_cc__Timesheet_Entry__c(
                        maica_cc__Timesheet__c = timesheet.Id,
                        maica_cc__Start_Time__c = Datetime.newInstance(2025, 3, 1, 19, 0, 0),
                        maica_cc__End_Time__c = Datetime.newInstance(2025, 3, 1, 20, 0, 0),
                        Batch__c = batchVar.Id
                )
        };
        insert timesheetEntries;

        List<maica_cc__Unavailability__c> unavailabilityList = new List<maica_cc__Unavailability__c>{
                new maica_cc__Unavailability__c(
                        maica_cc__Resource__c = resource.Id,
                        maica_cc__Type__c = 'Appointment Break',
                        maica_cc__Unavailable_From__c = Datetime.newInstance(2025, 3, 1, 9, 20, 0),
                        maica_cc__Unavailable_To__c = Datetime.newInstance(2025, 3, 1, 9, 30, 0)
                ),
                new maica_cc__Unavailability__c(
                        maica_cc__Resource__c = resource.Id,
                        maica_cc__Type__c = 'Appointment Break',
                        maica_cc__Unavailable_From__c = Datetime.newInstance(2025, 3, 1, 9, 40, 0),
                        maica_cc__Unavailable_To__c = Datetime.newInstance(2025, 3, 1, 9, 50, 0)
                )
        };
        insert unavailabilityList;
    }

    @IsTest
    static void testGenerateProc() {
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        Response resp = new Tc9GenerateProc().process(new Map<String, Object>{
                'batch' => new AutoMapper().getSObjectAsMap(batchVar)
        });
        Assert.isNotNull(resp.get('batch'));
    }

    @IsTest
    static void testMergeBatch() {
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        Test.startTest();
        Response resp = new Tc9MergeProc().process(new Map<String, Object>{
                'batchId' => batchVar.Id
        });
        Test.stopTest();
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Log__c
        ]);
        Assert.isNull(log);
        Assert.isNotNull(resp.get('jobId'));
    }

    @IsTest
    static void testMergeProc() {
        maica_cc__Timesheet__c ts = (maica_cc__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Timesheet__c
        ], 'No maica_cc__Timesheet__c');
        Response resp = new Tc9MergeProc().process(new Map<String, Object>{
                'tsId' => ts.Id
        });
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Log__c
        ]);
        Assert.isNull(log);
        Assert.areNotEqual(null, resp.get('mergedTSEs'));
    }

    @IsTest
    static void testMergeProcCatch() {
        try {
            new Tc9MergeProc().process(new Map<String, Object>());
        } catch (Exception e) {
            maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrException([
                    SELECT Id
                    FROM maica_cc__Log__c
            ], 'No maica_cc__Log__c');
            Assert.isNotNull(log);
        }
    }

    @IsTest
    static void testBreakBatch() {
        maica_cc__Setting__c settingVar = (maica_cc__Setting__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Setting__c
                WHERE maica_cc__API_Name__c = :Tc9Service.TC9_SETTING
        ], 'No maica_cc__Setting__c with maica_cc__API_Name__c: ' + Tc9Service.TC9_SETTING);
        settingVar.Break_Processor_Mode__c = 'Fill Gaps';
        update settingVar;
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        maica_cc__Timesheet__c ts = (maica_cc__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Timesheet__c
        ], 'No maica_cc__Timesheet__c');
        new Tc9MergeProc().process(new Map<String, Object>{
                'tsId' => ts.Id
        });
        Test.startTest();
        Response resp = new Tc9BreakProc().process(new Map<String, Object>{
                'batchId' => batchVar.Id
        });
        Test.stopTest();
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Log__c
        ]);
        Assert.isNull(log);
        Assert.isNotNull(resp.get('jobId'));
    }

    @IsTest
    static void testBreakProc() {
        maica_cc__Timesheet__c ts = (maica_cc__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Timesheet__c
        ], 'No maica_cc__Timesheet__c');
        maica_cc__Resource__c res = (maica_cc__Resource__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Resource__c
        ], 'No maica_cc__Resource__c');
        Response resp = new Tc9BreakProc().process(new Map<String, Object>{
                'tsId' => ts.Id,
                'resourceId' => res.Id
        });
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Log__c
        ]);
        Assert.isNull(log);
        Assert.isTrue(resp.isValid);
    }

    @IsTest
    static void testBreakProcCatch() {
        try {
            new Tc9BreakProc().process(new Map<String, Object>());
        } catch (Exception e) {
            maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrException([
                    SELECT Id
                    FROM maica_cc__Log__c
            ], 'No maica_cc__Log__c');
            Assert.isNotNull(log);
        }
    }

    @IsTest
    static void testSyncBatch() {
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        maica_cc__Timesheet__c ts = (maica_cc__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Timesheet__c
        ], 'No maica_cc__Timesheet__c');
        maica_cc__Resource__c res = (maica_cc__Resource__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Resource__c
        ], 'No maica_cc__Resource__c');
        new Tc9MergeProc().process(new Map<String, Object>{
                'tsId' => ts.Id
        });
        new Tc9BreakProc().process(new Map<String, Object>{
                'tsId' => ts.Id,
                'resourceId' => res.Id
        });
        Test.startTest();
        Response resp = new Tc9SyncProc().process(new Map<String, Object>{
                'batchId' => batchVar.Id,
                'batchSize' => 10
        });
        Test.stopTest();
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Log__c
        ]);
        Assert.isNull(log);
        Assert.isNotNull(resp.get('jobId'));
    }

    @IsTest
    static void testSyncProc() {
        maica_cc__Timesheet__c ts = (maica_cc__Timesheet__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM maica_cc__Timesheet__c
        ], 'No maica_cc__Timesheet__c');
        List<maica_cc__Timesheet_Entry__c> TSEs = [
                SELECT Id
                FROM maica_cc__Timesheet_Entry__c
                WHERE maica_cc__Timesheet__c = :ts.Id
                ORDER BY maica_cc__Start_Time__c ASC
                LIMIT 3
        ];
        for (maica_cc__Timesheet_Entry__c tse : TSEs) {
            Response resp = new Tc9SyncProc().process(new Map<String, Object>{
                    'tseId' => tse.Id
            });
            maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                    SELECT Id
                    FROM maica_cc__Log__c
            ]);
            Assert.isNull(log);
            Assert.isTrue(resp.isValid);
        }
    }

    @IsTest
    static void testSyncProcCatch() {
        try {
            new Tc9SyncProc().process(new Map<String, Object>());
        } catch (Exception e) {
            maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrException([
                    SELECT Id
                    FROM maica_cc__Log__c
            ], 'No maica_cc__Log__c');
            Assert.isNotNull(log);
        }
    }

    @IsTest
    static void testBatchSyncTo2c9QAMetaProc() {
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        Response resp = new BatchSyncTo2c9QAMetaProc().process(new Map<String, Object>{
                'batchId' => batchVar.Id
        });
        Assert.isTrue(resp.isValid);
    }

    @IsTest
    static void testBatchRemoveItemsQASubmitProc() {
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id
                FROM Batch__c
        ], 'No Batch__c');
        Response resp = new BatchRemoveItemsQASubmitProc().process(new Map<String, Object>{
                'batchId' => batchVar.Id
        });
        Assert.isTrue(resp.isValid);
    }


    @IsTest
    static void testSettings2c9MetaProc() {
        Response resp = new Settings2c9MetaProc().process(new Map<String, Object>{
        });
        Assert.isTrue(resp.isValid);
    }

    @IsTest
    static void Settings2c9SubmitProc() {
        Response resp = new Settings2c9SubmitProc().process(new Map<String, Object>{
        });
        Assert.isTrue(resp.isValid);
    }
}