({
    handleSaveClick: function (cmp, event, helper) {
        if (!cmp.validate()) {
            return;
        }

        cmp.set('v.hideContentOnBusy', false);

        helper
            .submit(cmp, helper)
            .then(response => {
                cmp.set('v.isEdit', false);
                return helper.init(cmp);
            });
    },

    handleAddETMClick: function (cmp, event, helper) {
        let items = cmp.get('v.meta.dto.employmentTypeMappings') || [];
        items.push({});
        cmp.set('v.meta.dto.employmentTypeMappings', items);
    },

    handleDeleteETMClick: function (cmp, event, helper) {
        let index = event.getSource().get('v.value'),
            items = cmp.get('v.meta.dto.employmentTypeMappings');
        if (items && items.length !== 0) {
            items.splice(index, 1);
            cmp.set('v.meta.dto.employmentTypeMappings', items);
        }
    }
});