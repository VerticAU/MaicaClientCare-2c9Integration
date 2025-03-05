({
    handleInit: function (cmp, event, helper) {
        cmp.doInit({
            batchId: cmp.get('v.recordId'),
        }).then(function (response) {
        });
    },

    handleGenerateBatch: function (cmp, event, helper) {
        cmp.set('v.isBusy', true);
        cmp.set('v.isBusy', true);

        cmp.utils
            .executePromise(
                cmp,
                'Tc9GenerateBatchProc',
                {batch: cmp.get('v.meta.dto.batch')}
            )
            .then(response => {
                cmp.set('v.meta.dto.batch', response.dto.batch);
                $A.enqueueAction(cmp.get('c.handleNext'));
                $A.get('e.force:refreshView').fire();
                return Promise.resolve(response);
            })
            .finally(response => {
                cmp.set('v.isBusy', false);
            });
    },


    handleNext: function (cmp, event, helper) {
        let steps = cmp.get('v.meta.dto.steps');
        let currentStep = cmp.get('v.currentStep');
        let currentStepIndex = steps.findIndex(step => step.value === currentStep);
        let newStepIndex = currentStepIndex + 1;
        let newStep = steps[newStepIndex].value;
        let isValid = helper.validate(cmp, helper);
        if (isValid) {
            cmp.set('v.currentStep', newStep);
        }
    },

    handlePrevious: function (cmp, event, helper) {
        let steps = cmp.get('v.meta.dto.steps');
        let currentStep = cmp.get('v.currentStep');
        let currentStepIndex = steps.findIndex(step => step.value === currentStep);
        let newStepIndex = currentStepIndex - 1;
        cmp.set('v.currentStep', steps[newStepIndex].value);
    },
});