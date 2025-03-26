({
    validate: function (cmp, helper) {
        let currentStep = cmp.get('v.currentStep');
        let errorMessagesCmp = cmp.find('errors');
        errorMessagesCmp.clearErrors();

        let validationResult = cmp.utils.validate(cmp.find('syncTo2c9'), {});
        if (validationResult.allValid !== true) {
            errorMessagesCmp.showErrors(validationResult.getErrorMessages(), true);
            return false;
        }

        if (currentStep === 'generateBatch' && !cmp.get('v.meta.dto.batch.Timesheet_Entry_Count__c')) {
            errorMessagesCmp.showErrors([{message: 'There are no any related Time Sheet Entries to continue the process.'}], true);
            return false;
        }

        return true;
    }
});