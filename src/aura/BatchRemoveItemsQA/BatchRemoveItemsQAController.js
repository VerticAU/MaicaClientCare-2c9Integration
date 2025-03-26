({
    handleConfirm: function (cmp, event, helper) {
        cmp.set('v.isBusy', true);

        cmp.utils
            .executePromise(
                cmp,
                'BatchRemoveItemsQASubmitProc',
                {
                    batchId: cmp.get('v.recordId')
                }
            )
            .then(response => {
                cmp.find('notifLib').showToast({
                    variant: 'success',
                    message: 'All Timesheet Entries have been removed successfully.'
                });
                $A.get('e.force:refreshView').fire();
                $A.get('e.force:closeQuickAction').fire();
                return Promise.resolve(response);
            })
            .finally(response => {
                cmp.set('v.isBusy', false);
            });
    }
});