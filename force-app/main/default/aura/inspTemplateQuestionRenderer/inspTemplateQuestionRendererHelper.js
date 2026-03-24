({
    navigateToRecord: function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    scrollTowardsTop: function (component, event, helper) {
        let inspTemplateQuestionRendererDiv = component.find('inspTemplateQuestionRendererDiv');
        if (inspTemplateQuestionRendererDiv) {
            let inspTemplateQuestionRendererDivEle = inspTemplateQuestionRendererDiv.getElement();
            if (inspTemplateQuestionRendererDivEle) {
                inspTemplateQuestionRendererDivEle.scrollTop = 0;
            }
        }
    },
    getUrlParams: function () {
        return location.search.slice(1).split('&').reduce(function (acc, cur, i) {
            cur = cur.split('=');
            acc[cur[0]] = cur[1];
            return acc;
        }, {});
    }
})