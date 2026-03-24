import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateSurveyInvitation from '@salesforce/apex/seqActivityTimelineController.updateSurveyInvitation';
export default class SeqActivityTimelineContent extends NavigationMixin(LightningElement) {
    @api activityList = [];
    @track activitiesPresent = true;
    connectedCallback() {
        
    }
    get activitiesPresent() {
        return this.activityList.length > 0;
    }
    handleClickForNavigateToRecordPage (event) {
        
        var recordId = event.target.dataset.recordid;
        var objectAPIName = event.target.dataset.objectname;
        this.navigateToRecordPage(recordId, objectAPIName);
    }
    navigateToRecordPage(recordIdToNavigate, objectAPIName) {
        if(recordIdToNavigate !== undefined) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordIdToNavigate,
                    objectApiName: objectAPIName,
                    actionName: 'view'
                }
            });
        }
    }
    toggleExpandedView(event) {
        var recordId = event.target.dataset.recordid;
        var buttonEle = event.target;
        var detailsSectionId = event.target.getAttribute('aria-controls');

        var parentDivblock = this.template.querySelector('[data-id="'+recordId+'"]');
        var detailsDivblock = this.template.querySelector('[id="'+detailsSectionId +'"');
        if(parentDivblock.className.indexOf('expand') >=0){
            parentDivblock.className = parentDivblock.className.replace(' expand', ' collapse');
            buttonEle.setAttribute('aria-expanded', 'false');
            detailsDivblock.setAttribute('aria-hidden', 'true');
        } else {
            parentDivblock.className = parentDivblock.className.replace(' collapse', '');
            parentDivblock.className = parentDivblock.className + ' expand'; 
            buttonEle.setAttribute('aria-expanded', 'true');
            detailsDivblock.setAttribute('aria-hidden', 'false');
        }
    }
    cancelInvite(event) {
        var siRecordId = event.target.dataset.recordid;
        updateSurveyInvitation({
            surveyInvitationId: siRecordId,
            newstage: 'Expired'
        }).then((result) => {
            console.log(result);
            const event = new ShowToastEvent({
                title: 'Congratulations',
                message: 'The sequence form has been updated successfully',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }).catch((error) => {
            console.error(error);
        });
    }
    resendInvite(event) {
        var siRecordId = event.target.dataset.recordid;
        updateSurveyInvitation({
            surveyInvitationId: siRecordId,
            newstage: 'Sent to recipien'
        }).then((result) => {
            console.log(result);
            const event = new ShowToastEvent({
                title: 'Congratulations',
                message: 'The sequence form has been re-sent successfully',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        })
        .catch((error) => {
            console.error(error);
        });
    }
}