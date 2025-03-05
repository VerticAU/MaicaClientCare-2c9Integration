public class Tc9GenerateBatchProc extends AbstractProcessor {

    public override Response process(Request request) {
        this.request = request;
        this.doSubmit();
        return this.response;
    }

    private void doSubmit() {
        Batch__c batchVar = new Batch__c();
        this.request.getMapper().mapToSObject('batch', batchVar);
        Integer totalTSEs = 0;
        Decimal totalHours = 0;

        String soql = '' +
                'SELECT Id\n' +
                'FROM maica_cc__Timesheet_Entry__c\n' +
                'WHERE maica_cc__Timesheet__r.maica_cc__Status__c = \'Approved\'\n' +
                'AND maica_cc__Start_Time__c != NULL\n' +
                'AND maica_cc__End_Time__c != NULL\n' +
                (batchVar.Include_All__c != true ? 'AND maica_cc__Start_Time__c >= :startDate\n' : '') +
                'AND maica_cc__End_Time__c <= :endDate\n' +
                'AND Timesheet_Entry_2C9__c = NULL\n' +
                'AND Merged_Timesheet_Entry__c = FALSE\n' +
                'AND (Merge_Target_Timesheet_Entry__c = NULL OR Merge_Target_Timesheet_Entry__r.Timesheet_Entry_2C9__c = NULL)\n';
        List<maica_cc__Timesheet_Entry__c> TSEs = Tc9Service.query(soql, new Map<String, Object>{
                'endDate' => batchVar.End_Date__c,
                'startDate' => batchVar.Start_Date__c
        });
        for (maica_cc__Timesheet_Entry__c tse : TSEs) {
            tse.Batch__c = batchVar.Id;
        }
        update TSEs;

        List<maica_cc__Timesheet_Entry__c> allRelatedTSEs = [
                SELECT Id, maica_cc__Start_Time__c, maica_cc__End_Time__c
                FROM maica_cc__Timesheet_Entry__c
                WHERE Batch__c = :batchVar.Id
        ];
        for (maica_cc__Timesheet_Entry__c tse : allRelatedTSEs) {
            totalTSEs += 1;
            totalHours += (tse.maica_cc__End_Time__c.getTime() - tse.maica_cc__Start_Time__c.getTime()) / (1000 * 60 * 60);
        }
        batchVar.Timesheet_Entry_Count__c = totalTSEs;
        batchVar.Timesheet_Entry_Hours__c = totalHours;
        if (batchVar.Timesheet_Entry_Count__c > 0) {
            batchVar.Status__c = 'Generated';
        }
        update batchVar;

        this.response.put('batch', batchVar);
    }
}