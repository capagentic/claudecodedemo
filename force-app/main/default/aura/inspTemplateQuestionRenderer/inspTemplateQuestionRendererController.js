({
    doInit: function (component, event, helper) {
        var disableSubmission = component.get('v.disableSubmission');
        console.log('inspTemplateQuestionRenderer >> doInit >> disableSubmission=' + disableSubmission);
        if (disableSubmission) {
            var params = helper.getUrlParams();
            var inspectionId = params['inspectionId'];
            component.set('v.recordId', inspectionId);
        }
        var deviceFormFactor = $A.get("$Browser.formFactor");
        var headerclassValue = 'slds-card__header slds-grid slds-p-around_none slds-border_bottom slds-grid_vertical-align-center slds-has-flexi-truncate';
        var footerclassValue = 'slds-grid_vertical-align-center slds-card__footer';
        var contentclassValue = 'slds-card__body slds-card__body_inner custom_body__content slds-p-around_none scrollToTopClass';

        if (deviceFormFactor === 'DESKTOP' && disableSubmission != true) {
            component.set('v.isDesktop', true);
            headerclassValue = headerclassValue + ' fixedheader desktopfixedheader'
            footerclassValue = footerclassValue + ' fixedfooter desktopfixedfooter';
            contentclassValue = contentclassValue + ' desktoprequiredheight';
        } else if (disableSubmission != true) {
            headerclassValue = headerclassValue + ' fixedheader';
            footerclassValue = footerclassValue + ' fixedfooter';
            contentclassValue = contentclassValue + ' requiredheight';
        }

        if (disableSubmission == true) {
            footerclassValue = 'hideelement';
        }


        component.set('v.headerclassValue', headerclassValue);
        component.set('v.footerclassValue', footerclassValue);
        component.set('v.contentclassValue', contentclassValue);

        var questionRendererPageRef = component.get("v.pageReference");
        if (questionRendererPageRef != undefined) {
            component.set("v.recordId", questionRendererPageRef.state.c__inspectionRecordId);
            component.set("v.fetchAllQuestions", (questionRendererPageRef.state.c__fetchAllQuestions));
        }
    },
    onPageReferenceChanged: function (cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    closePopup: function (component, event, helper) {
        var disableSubmission = component.get('v.disableSubmission');
        if (disableSubmission) {
            return;
        }
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
        helper.navigateToRecord(component, event, helper);
    },

    handleSubmit: function (component, event, helper) {
        var disableSubmission = component.get('v.disableSubmission');
        if (disableSubmission) {
            return;
        }
        var inspectionChildComp = component.find('inspTemplateQuestionRendererLWC');
        inspectionChildComp.submitTemplate();
    },
    updateValuesAtParent: function (component, event, helper) {
        component.set("v.titletext", event.getParam('title'));
        component.set("v.currentPageNumber", event.getParam('currentPageNumber'));
        component.set("v.totalPages", event.getParam('totalPages'));
    },

    handlePrevClick: function (component, event, helper) {
        var currentPageNumber = component.get("v.currentPageNumber");
        currentPageNumber = currentPageNumber > 1 ? currentPageNumber - 1 : 1;
        component.set("v.currentPageNumber", currentPageNumber);
        var inspectionChildComp = component.find('inspTemplateQuestionRendererLWC');
        inspectionChildComp.handlePagination(currentPageNumber);

        helper.scrollTowardsTop(component, event, helper);
    },
    handleNextClick: function (component, event, helper) {
        var currentPageNumber = component.get("v.currentPageNumber");
        var totalPagesNumber = component.get("v.totalPages");

        currentPageNumber = currentPageNumber < totalPagesNumber ? currentPageNumber + 1 : totalPagesNumber;
        component.set("v.currentPageNumber", currentPageNumber);
        var inspectionChildComp = component.find('inspTemplateQuestionRendererLWC');
        inspectionChildComp.handlePagination(currentPageNumber);

        helper.scrollTowardsTop(component, event, helper);
    },
    handleUpdateScore: function (component, event, helper) {
        component.set("v.currentScore", event.getParam('totalObtainedScore'));
        component.set("v.totalOutOfScore", event.getParam('totalOutofScore'));
        var currentScore = component.get("v.currentScore") || 0;
        var totalOutofScore = component.get("v.totalOutOfScore") || 0;
        var percentageScore = ((currentScore / totalOutofScore) * 100) || 0;
        percentageScore = parseFloat(percentageScore).toFixed(0);
        component.set("v.percentageScore", percentageScore);
    },
})