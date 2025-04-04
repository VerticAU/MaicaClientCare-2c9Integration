public without sharing class Settings2c9MetaProc extends MetadataProcessor {

    public override Response process(Request request) {
        this.request = request == null ? new MetadataProcessor.MetadataRequest() : (MetadataProcessor.MetadataRequest) request;

        this.request.fields = new Set<SObjectField>{
                maica_cc__Setting__c.Break_Processor_Mode__c
//                Employment_Type_Mapping__c.Employment_Type__c
        };

        super.process(this.request);

        this.init();

        return this.response;
    }

    private void init() {
        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        this.response.getMapper().mapFromSObject('setting', setting);

//        List<Employment_Type_Mapping__c> employmentTypeMappings = [
//                SELECT Id,Active__c, Is_Default__c, Employment_Type__c, Interpretation_Rule_ID__c
//                FROM Employment_Type_Mapping__c
//        ];

//        this.response.put('employmentTypeMappings', employmentTypeMappings);
    }
}