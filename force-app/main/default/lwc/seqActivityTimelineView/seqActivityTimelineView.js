import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurveyInvitationsForContact from '@salesforce/apex/seqActivityTimelineController.getSurveyInvitationsForContact';

const sentToRecipientStage = 'Sent to recipient';
export default class SeqActivityTimelineView extends NavigationMixin(LightningElement) {
    @api recordId;
    @track futureActivityList = [];
    @track pastActivityList = [];
    @track isLoading = true;
 
    connectedCallback() {
        this.getSurveyInvitationsForContact();

    }

    getSurveyInvitationsForContact() {
        getSurveyInvitationsForContact({contactId: this.recordId}).then(dataList => {
            this.isLoading = false;
            this.generateActivityWrapperList(JSON.parse(dataList));
        }).catch(error =>{
            this.handleErrorBlock(error);
        });
    }
    handleErrorBlock(error) {
        this.isLoading =false;
        if(error.hasOwnProperty('body') && error.body.hasOwnProperty('message')) {
            this.showErrorMessage(error.body.message);
        }else {
            this.showErrorMessage(error);
        }
    }
    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Activity Time for Survey Invitation',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    generateActivityWrapperList (activityList) {
        for(var i=0;i<activityList.length;i++) {
            var act = activityList[i];
            act['sentDate'] = this.formatDate(act.CreatedDate, 'dd/mm/yyyy,mm:ss a');
            act['CreatedDate'] = new Date(act.CreatedDate);
            if(act.Kinetics__TTL_Day__c != undefined && act.Kinetics__TTL_Day__c != null){
                act['expiresOnDate'] = new Date(act.CreatedDate);
                act.expiresOnDate.setDate(act.CreatedDate.getDate() + parseInt(act.Kinetics__TTL_Day__c));
                act['expiresTime'] = this.formatAMPM(act.expiresOnDate);
                act['expiresDate'] = this.formatDate(act.expiresOnDate, 'dd MMM');
                act.expiresOnDate = this.formatDate(act.expiresOnDate, 'dd/mm/yyyy,mm:ss a');
            }
            act['isEmailOpened'] = false;
            act['lastOpenedDifference'] = 0;
            act['cancelButtonRequired'] = true;
            if(act.Kinetics__Stage__c == sentToRecipientStage) {
                act['isEmailOpened'] = false;
            } else if(act.Kinetics__Stage__c == 'In progress' || act.Kinetics__Stage__c == 'Completed' || act.Kinetics__Stage__c =='Expired') {
                act['isEmailOpened'] = true;
                var difftime = Math.abs(new Date()  - new Date(act.LastModifiedDate));
                act['lastOpenedDifference'] = Math.ceil(difftime / (1000 * 60 * 60 * 24));
            }
            if(act.Kinetics__Stage__c == 'Expired' || act.Kinetics__Stage__c == 'Completed') {
                act['cancelButtonRequired'] = false;
                this.pastActivityList.push(act);
            } else if(act.Kinetics__Stage__c == 'In progress' || act.Kinetics__Stage__c == sentToRecipientStage) {
                this.futureActivityList.push(act);
            }
        }
    }
    formatAMPM(date) {
        date = new Date(date);
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0'+minutes : minutes;
        var strTime = hours + ':' + minutes + ' ' + ampm;
        return strTime;
    }

    formatDate(ldate, format) {
        ldate = new Date(ldate);
        if(format === 'dd/mm/yyyy,mm:ss a') {
            return ldate.getDate() + '/' + (ldate.getMonth() + 1) + '/' + ldate.getFullYear() + ', ' + this.formatAMPM(ldate);
        } else if (format === 'dd MMM') {
            return ldate.getDate() + ' ' + ldate.toLocaleString('default', { month: 'short' });
        }
        return ''
    }
    toggleExpandedView(event) {
        var recordId = event.target.dataset.recordid;
        var parentDivblock = this.template.querySelector('[data-id="'+recordId+'"]');
        
        if(parentDivblock.className.indexOf('slds-is-open') >= 0){
            parentDivblock.className = parentDivblock.className.replace(' slds-is-open', ' slds-is-closed');
            parentDivblock.ariaExpanded = 'false';
        } else {
            parentDivblock.className = parentDivblock.className.replace(' slds-is-closed', '');
            parentDivblock.className = parentDivblock.className + ' slds-is-open';
            parentDivblock.ariaExpanded = 'true';
        }

        var contentDivblock = this.template.querySelector('[data-id="'+recordId+'-content"]');
        if(contentDivblock != undefined) {
            if(contentDivblock.className.indexOf('slds-is-collapsed') >=0){
                contentDivblock.className = contentDivblock.className.replace(' slds-is-collapsed', '');
                contentDivblock.ariaHidden == 'false'
            } else {
                contentDivblock.className = contentDivblock.className + ' slds-is-collapsed';
                contentDivblock.ariaHidden == 'true'
            }
        }
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
}