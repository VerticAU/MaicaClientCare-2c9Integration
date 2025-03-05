public without sharing class SyncTo2c9QAMetaProc extends MetadataProcessor {

    public override Response process(Request request) {
        this.request = request == null ? new MetadataProcessor.MetadataRequest() : (MetadataProcessor.MetadataRequest) request;

        this.request.fields = new Set<SObjectField>{
        };

        super.process(this.request);

        this.init();

        return this.response;
    }
    
    private void init() {
        String batchId = this.request.getRequiredString('batchId');
        Batch__c batchVar = (Batch__c) Utils.arrays.firstOrException([
                SELECT Id, Start_Date__c, End_Date__c, Include_All__c, Timesheet_Entry_Count__c,
                        Timesheet_Entry_Hours__c, Status__c
                FROM Batch__c
                WHERE Id = :batchId
        ],'No Batch__c with Id: ' + batchId);
        this.response.put('batch', batchVar);

        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        Boolean isMergeEnabled = setting.Is_Merge_Processor_Enabled__c == true;

        List<Map<String, String>> steps = new List<Map<String, String>>();
        steps.add(new Map<String, String>{
                'value' => 'generateBatch',
                'label' => 'Generate Batch'
        });
        if(isMergeEnabled){
            steps.add(new Map<String, String>{
                    'value' => 'mergeProcess',
                    'label' => 'Process Merge'
            });
        }
        steps.add(new Map<String, String>{
                'value' => 'breakProcess',
                'label' => 'Process Break'
        });
        steps.add(new Map<String, String>{
                'value' => 'syncProcess',
                'label' => 'Sync to 2c9'
        });
        this.response.put('steps', steps);
    }
}