({
    handleInit: function (cmp, event, helper) {
        cmp.set('v.hideContentOnBusy', true)
        cmp.doInit({
            batchId: cmp.get('v.recordId'),
        }).finally(function (response) {
            cmp.set('v.hideContentOnBusy', false)
        });
    },

    handleGenerateBatch: function (cmp, event, helper) {
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

    handleMerge: function (cmp, event, helper) {
        cmp.find('mergeProcessor').process(
            'Tc9MergeProc', {batchId: cmp.get('v.recordId')}
        )
    },

    handleMergeComplete: function (cmp, event, helper) {

    },

    handleBreak: function (cmp, event, helper) {
        cmp.find('breakProcessor').process(
            'Tc9BreakProc', {batchId: cmp.get('v.recordId')}
        )
    },

    handleBreakComplete: function (cmp, event, helper) {

    },

    handleSync: function (cmp, event, helper) {
        cmp.find('syncProcessor').process(
            'Tc9SyncProc', {batchId: cmp.get('v.recordId')}
        )
    },

    handleSyncComplete: function (cmp, event, helper) {

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