public without sharing class BatchRemoveItemsQASubmitProc extends AbstractProcessor {

    public override Response process(Request request) {
        this.request = request;
        this.doSubmit();
        return this.response;
    }
    
    private void doSubmit() {
        String batchId = this.request.getRequiredString('batchId');
        List<maica_cc__Timesheet_Entry__c> items = [
                SELECT Id
                FROM maica_cc__Timesheet_Entry__c
                WHERE Batch__c = :batchId
                AND TC9_Sync_Status__c IN :new List<String>{'Failed', 'Pending'}
                AND Timesheet_Entry_2C9__c = NULL
        ];
        for(maica_cc__Timesheet_Entry__c item : items){
            item.Batch__c = null;
        }
        update items;
    }
}