public without sharing class Settings2c9SubmitProc extends AbstractProcessor {

    public override Response process(Request request) {
        this.request = request;

        this.doSubmit();

        return this.response;
    }

    private void doSubmit() {
        maica_cc__Setting__c setting = Tc9Service.tc9Setting;
        this.request.getMapper().mapToSObject('setting', setting);
        upsert setting;

//        List<Employment_Type_Mapping__c> employmentTypeMappings = this.request.getMapper().mapToListSObjects('employmentTypeMappings', Employment_Type_Mapping__c.SObjectType);
//        upsert employmentTypeMappings;
    }
}