import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTemplateDetailsByInspectionId from '@salesforce/apex/InspSendInspectionController.getTemplateDetailsByInspectionId';
import getKineticUsageMap from '@salesforce/apex/SeqSenderController.getKineticUsageMap';
import allowedSMSEmailLimitExceededString from '@salesforce/label/c.allowedSMSEmailLimitExceededString';
import getSmsTemplate from '@salesforce/apex/SeqSenderController.getSmsTemplate';
import getEmailTemplateById from '@salesforce/apex/SeqSenderController.getEmailTemplateById';
import createJob from '@salesforce/apex/SeqSenderController.createJob';
import updateAnswerToLinkWithSurveyInvitation from '@salesforce/apex/InspSendInspectionController.updateAnswerToLinkWithSurveyInvitation';

export default class InspSendTemplateToContact extends LightningElement {
    
    @api inspectionRecordId;
    @track smsTemplate;
    emailTemplateId;
    deliveryMethod = 'sms';
    kineticUsageByType;
    @track showSMSTemplate = true;
    @track showEmailTemplate = false;
    @track emailObj = {};
    
    @track inspectionRec = {contactName: '', contactEmail: '', contactId: '', contactMobile: '', templateName: '', templateId: ''};

    isLoading = false;

    @track contactIds = [];
    @track templateId;
    @track sendAutoReminders = false; 
    @track daysForFirstReminder = 3;
    @track daysbetweenReminder = 2;
    @track daysbeforerequestexpires = 7;
    @track expirationQueueDate;
    @track sendNotAllowed = false;

    connectedCallback() {
        this.isLoading =true;
        // this.initializeLabels();
        this.getSmsTemplate();
        this.setExpirationDate();
        this.getKineticUsageMap();
        this.getTemplateDetails();
    }

    getTemplateDetails() {
        getTemplateDetailsByInspectionId({inspectionId : this.inspectionRecordId}).then(result => {
            var responseObj = JSON.parse(result);
            var inspectionRecordList = responseObj.responseDetails;
            if(inspectionRecordList.length > 0){
                var inspectionRecLocal = inspectionRecordList[0];
                this.inspectionRec['contactName'] = inspectionRecLocal.Kinetics__Contact__r.Name;
                this.inspectionRec['contactEmail'] = inspectionRecLocal.Kinetics__Contact__r.Email;
                this.inspectionRec['contactId'] = inspectionRecLocal.Kinetics__Contact__c;
                this.inspectionRec['contactMobile'] = inspectionRecLocal.Kinetics__Contact__r.MobilePhone;
                this.inspectionRec['templateName'] = inspectionRecLocal.Kinetics__Template__r.Name;
                this.inspectionRec['templateId'] = inspectionRecLocal.Kinetics__Template__c;

                this.contactIds.push(this.inspectionRec['contactId']);
                this.templateId = this.inspectionRec['templateId'];

                if(this.contactIds.length == 0) {
                    this.sendNotAllowed = true;
                    this.showMessage('Please ensure contact is populated on Inspection to send', 'error', 'sticky');
                }
                if(this.templateId == undefined) {
                    this.sendNotAllowed = true;
                    this.showMessage('Please ensure Template is populated on Inspection to send', 'error', 'sticky');
                }
                if(this.inspectionRec['contactMobile'] == undefined 
                    && this.inspectionRec['contactEmail'] == undefined) {
                    this.sendNotAllowed = true;
                    this.showMessage('Please ensure atleast mobile or email is populated on contact linked to the Inspection to send', 'error', 'sticky');
                }
            }
        }).catch(error => {
            console.log(error);
            this.handleErrorBlock(error);
        });
    }

    getKineticUsageMap() {
        getKineticUsageMap({}).then(result => {
            this.kineticUsageByType = JSON.parse(result);
        }).catch(error => {
            this.handleErrorBlock(error);
        });
    }
    getSmsTemplate() {
        getSmsTemplate({})
            .then(result => {
                this.smsTemplate = result;
            })
            .catch(error => {
                this.handleErrorBlock(error);
            }
        );
    }

    changeSMSTemplateHandler (event) {
        var smsTextValue = event.target.value;
        if(smsTextValue.length >= 160) {
            var error = {'body': {'message': 'Please enter SMS text upto 160 characters only.'}};
            this.handleErrorBlock(error);
            smsTextValue = smsTextValue.substring(smsTextValue, 160);
            this.smsTemplate = smsTextValue;
            return;
        }

        if(smsTextValue.indexOf('{{pageUrl}}') < 0) {
            var error = {'body': {'message': 'Please DO NOT remove "pageUrl" from SMS text.'}};
            this.handleErrorBlock(error);
            return ;
        }

        this.smsTemplate = smsTextValue;
    }
    isInValidValue(v) {
        if(v === undefined || v === null || v === '' ) {
            return true;
        }
        return false;
    }
    emailSelectionHandler(event) {
        const selecteRecordId = event.detail.selectedRecordId;
        this.emailTemplateId = selecteRecordId;
        this.getEmailTemplateById(selecteRecordId)
    }

    getEmailTemplateById(emailTemplateId) {
        getEmailTemplateById({
            emailTemplateId: emailTemplateId
        })
        .then(result => {
            var resObj = JSON.parse(result);
            if (resObj.statusCode == '2000') {
                this.emailObj = resObj.responseDetails;
                if((!this.isInValidValue(this.emailObj))
                    && this.emailObj.hasOwnProperty('HtmlValue')){
                    if(this.isInValidValue(this.emailObj.HtmlValue)
                        && this.emailObj.hasOwnProperty('Body')
                        && !this.isInValidValue(this.emailObj.Body)) {
                        this.emailObj.HtmlValue = this.emailObj.Body;
                        this.emailObj.HtmlValue = this.emailObj.HtmlValue.replaceAll('\n','<br/>');
                    }
                }

                this.emailObj.HtmlValue = this.emailObj.HtmlValue.replace('<![CDATA[', '');
                this.emailObj.HtmlValue = this.emailObj.HtmlValue.replace(']]>', '');
            } else if (resObj.statusCode == '2100') {
                this.handleErrorBlock(resObj.responseDetails);
            }
        })
        .catch(error => {
            this.handleErrorBlock(error);
        });
    }

    validateKineticUsage() {
        var numberOfInvitesToBeSent = 1;
        if(this.deliveryMethod == 'email') {
            var TotalAllowedEmailInvites = this.kineticUsageByType['TotalAllowedEmailInvites'];
            var NumberOfSentEmailInvite = this.kineticUsageByType['NumberOfSentEmailInvite'];
            if(TotalAllowedEmailInvites < NumberOfSentEmailInvite) {
                return false;
            }
            if(TotalAllowedEmailInvites < (NumberOfSentEmailInvite + numberOfInvitesToBeSent)) {
                return false;
            }
        } else if(this.deliveryMethod == 'sms') {
            var TotalAllowedSMSInvites = this.kineticUsageByType['TotalAllowedSMSInvites'];
            var NumberOfSentSMSInvite = this.kineticUsageByType['NumberOfSentSMSInvite'];
            if(TotalAllowedSMSInvites < NumberOfSentSMSInvite) {
                return false;
            }
            if(TotalAllowedSMSInvites < (NumberOfSentSMSInvite + numberOfInvitesToBeSent)) {
                return false;
            }
        }
        return true;
    }

    get deliveryOptions() {
        return [
            { label: 'Email', value: 'email' },
            { label: 'SMS', value: 'sms' },
        ];
    }

    handleDeliveryChange(event) {
        this.deliveryMethod = event.detail.value;
        if (this.deliveryMethod == 'email') {
            this.showSMSTemplate = false;
            this.showEmailTemplate = true;
        } else {
            this.showSMSTemplate = true;
            this.showEmailTemplate = false;
        }
    }
    setExpirationDate() {
        var todayDate = new Date();
        this.expirationQueueDate = new Date(todayDate.setDate(todayDate.getDate() + parseInt(this.daysbeforerequestexpires)));
        this.expirationQueueDate = this.expirationQueueDate.getDate() + ' ' + this.expirationQueueDate.toLocaleString('default', { month: 'short' }) + ' ' + this.expirationQueueDate.getFullYear();
    }


    submitSendRequest(event) {
        if(!this.validateKineticUsage()) {
            this.isLoading = false;
            this.handleErrorBlock({'body': {'message': allowedSMSEmailLimitExceededString}});
            return 0;
        }

        if(this.inspectionRec['contactMobile'] == undefined && this.deliveryMethod == 'sms') {
            this.showMessage('Please ensure mobile is populated on contact linked to the Inspection to send', 'error', null);
            return 0;
        }

        if(this.inspectionRec['contactEmail'] == undefined && this.deliveryMethod == 'email') {
            this.showMessage('Please ensure email is populated on contact linked to the Inspection to send', 'error', null);
            return 0;
        }
        

        createJob({
            surveyId: this.templateId,
            contactIds: this.contactIds,
            emailTemplateId: this.emailTemplateId,
            smsContent: this.smsTemplate,
            delivery: this.deliveryMethod,
            sendAutoReminders: this.sendAutoReminders,
            daysForFirstReminder: this.daysForFirstReminder,
            daysbetweenReminder: this.daysbetweenReminder,
            daysbeforerequestexpires: this.daysbeforerequestexpires,
            inspectionId: this.inspectionRecordId
        })
        .then(result => {
            this.isLoading = false;
            var resObj = JSON.parse(result);
            updateAnswerToLinkWithSurveyInvitation({
                inspectionId: this.inspectionRecordId, 
                jobId : resObj.responseDetails.Id,
                contactIds: this.contactIds,
                templateId: this.templateId
            }).then(result => {
                this.showMessage('Send request is placed successfully', 'success');
                this.closeQuickAction();
            }).catch(error => {
                this.handleErrorBlock(error);
            });
        })
        .catch(error => {
            this.handleErrorBlock(error);
        });
    }

    showMessage(message, variant, mode) {
        const event = new ShowToastEvent({
            title: 'Send Inspection',
            message: message,
            variant: variant,
            mode: mode || 'dismissable'
        });
        this.dispatchEvent(event);
    }
    handleErrorBlock(error) {
        console.log('error',error);
        this.isLoading =false;
        this.showMessage(error.body.message, 'error');
    }
    closeQuickAction() {
        const closepopup = new CustomEvent('closepopup');
        // Dispatches the event.
        this.dispatchEvent(closepopup);
    }
}