import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSequenceById from '@salesforce/apex/SeqRendererController.getSequenceById';
import getSmsTemplate from '@salesforce/apex/SeqSenderController.getSmsTemplate';
import getEmailTemplateById from '@salesforce/apex/SeqSenderController.getEmailTemplateById';
import createJob from '@salesforce/apex/SeqSenderController.createJob';
import getContactDetails from '@salesforce/apex/SeqSenderController.getContactDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getKineticUsageMap from '@salesforce/apex/SeqSenderController.getKineticUsageMap';
import allowedSMSEmailLimitExceededString from '@salesforce/label/c.allowedSMSEmailLimitExceededString';

const questionColumns = [
    {
        label: 'Index', fieldName: 'index', initialWidth: 90, cellAttributes: {
            class: 'slds-border_left',
            alignment: 'center',
        }
    },
    {
        label: 'Question', fieldName: 'questionDetails', cellAttributes: {
            class: 'slds-border_left',
            alignment: 'left',
        }
    },
    {
        label: 'Type', fieldName: 'fieldType', initialWidth: 130, cellAttributes: {
            class: 'slds-border_left',
            alignment: 'left',
        }
    }
];

const contactColumns = [
    {
        label: 'Name', 
        name: 'Name',
        isReferenceField: false,
        referenceFieldAPIName: '',
    },
    {
        label: 'Account', 
        name: 'AccountId',
        isReferenceField: true,
        referenceFieldAPIName: 'Account'
    },
    {
        label: 'Title', 
        name: 'Title',
        isReferenceField: false,
        referenceFieldAPIName: '',
    },
    {
        label: 'Email', 
        name: 'Email',
        isReferenceField: false,
        referenceFieldAPIName: '',
    },
    {
        label: 'Mobile', 
        name: 'MobilePhone',
        isReferenceField: false,
        referenceFieldAPIName: '',
    }
];

export default class SeqSendeWizardrWithSteps extends NavigationMixin(LightningElement) {

    @api recordId;
    @track currentStep = '1';
    @track metadataObj = {'isStepOne':false};
    @track isLoading = true;
    @track labels = {};
    @track objectapiname = 'Kinetics__Kinetic_Job__c';
    @track allContactsById = {};
    @track selectedContactsCount = 0;
    @track selectedContactList = [];
    stepsNumberArr = [];
    @track contactColumnsToDisplay = contactColumns;
    @track surveyId;
    @track showRelatedQuestions = false;
    @track relatedquestions = [];
    columns = questionColumns;
    
    @track smsTemplate;
    emailTemplateId;
    deliveryMethod;
    kineticUsageByType;
    @track showSMSTemplate = true;
    @track showEmailTemplate = false;
    @track job = {};
    @track emailObj = {};
    @track contactIds = [];
    //api attributes to set value from caller component
    @api selectedContactIds = [];

    @track sendAutoReminders = false; 
    @track daysForFirstReminder = 3;
    @track daysbetweenReminder = 2;
    @track daysbeforerequestexpires = 7;
    @track expirationQueueDate;
    connectedCallback() {
        this.isLoading =true;
        this.resetToDefaults();
        this.initializeLabels();
        this.getSmsTemplate();
        this.getAllRequiredContact();
        this.setExpirationDate();
        this.getKineticUsageMap();
    }
    setExpirationDate() {
        var todayDate = new Date();
        this.expirationQueueDate = new Date(todayDate.setDate(todayDate.getDate() + parseInt(this.daysbeforerequestexpires)));
        this.expirationQueueDate = this.expirationQueueDate.getDate() + ' ' + this.expirationQueueDate.toLocaleString('default', { month: 'short' }) + ' ' + this.expirationQueueDate.getFullYear();
    }

    handleErrorBlock(error) {
        console.log('error',error);
        this.isLoading =false;
        this.showErrorMessage(error.body.message);
    }
    initializeLabels() {
        this.labels['headerTitle'] = 'Kinetic Sender';
        this.labels['headerSubTitle'] = 'Edit Kinetic Sender';
        this.labels['firstStepHelpText'] = 'Select your Recipients';
        this.labels['secondStepHelpText'] = 'Select a Kinetic Form';
        this.labels['thirdStepHelpText'] = 'Select a Delivery Method';
        this.labels['fourthStepHelpText'] = 'Configure Automatic Reminders';
        this.labels['fifthStepHelpText'] = 'Confirmation';
        this.labels['searchPlaceHolderTextForContact'] = 'Select Contacts';
        this.labels['error_selectatleastonecontact'] = 'Please select at least one Recipient';
        this.labels['error_selectvalidsurvey'] = 'Please select valid Kinetic form';
        this.labels['error_selectvalidtemplate'] = 'Please select either email or sms template';
        this.labels['error_selectvaliddeliverymethod'] = 'Please select valid delivery method';
        this.labels['Next'] = 'Next';
        this.labels['Back'] = 'Back';
        this.labels['Cancel'] = 'Cancel';
        this.labels['Finish'] = 'Finish';
        this.labels['Send'] = 'Send';
        this.labels['NextDummy'] = 'Next';
        this.labels['error_daysForFirstReminderRequired'] = 'Please specify number of days to wait before sending first reminder';
        this.labels['error_daysbetweentworeminder'] = 'Please specify number of days to wait between two reminders';
        this.labels['error_TTLDays'] = 'Please specify number of days after which this invitation should expire';
    }

    get deliveryOptions() {
        return [
            { label: 'Email', value: 'email' },
            { label: 'SMS', value: 'sms' },
        ];
    }

    resetToDefaults() {
        this.deliveryMethod = 'sms';
        this.showSMSTemplate = true;
        this.showEmailTemplate = false;
        this.stepsNumberArr = [1,2,3,4,5];
        this.contactIds = [];
        this.selectedContactList = [];
        this.allContactsById = {};
        this.selectedContactsCount = 0;
        this.surveyId = null;
    }
    updateContactSelection(event) {
        this.allContactsById = event.detail.allAvailableRecordsById;
        this.selectedContactsCount = event.detail.selectedRecordsCount;
    }

    handleOnStepClick(event) {
        let prevStep = this.currentStep;
        this.currentStep = event.target.value;
        if(prevStep == '1') {
            this.generateSelectContactList();
        }
        if(parseInt(prevStep) < parseInt(this.currentStep)) {
            this.validateKineticDetailSection(prevStep);
        }
        this.updateMetadataObj(this.currentStep);
        if(prevStep == '4') {
            this.handleFinish();
        }
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
    getAllRequiredContact() {
        //console.log('selectedContactIds: ' + JSON.stringify(this.selectedContactIds));
        //if this is called from list view button then there will be value in selectedContactIds attribute
        getContactDetails({ selectedContactIds: this.selectedContactIds }).then((records) => {
            this.generateContactWrapper(records);
        }).catch((error) => {
            this.handleErrorBlock(error);
        });
    }
    generateContactWrapper(records) {
        var isSelected = false;
        if(this.selectedContactIds.length > 0 
            && this.selectedContactIds.length == records.length) {
                isSelected = true;
                this.selectedContactsCount = this.selectedContactIds.length;
        }
        for(var i=0;i<records.length;i++) {
            var rec = records[i];
            if(!rec.hasOwnProperty('MobilePhone')) {
                rec['MobilePhone'] = '';
            }
            if(!rec.hasOwnProperty('Email')) {
                rec['Email'] = '';
            }
            if(!rec.hasOwnProperty('Title')) {
                rec['Title'] = '';
            }
            if(!rec.hasOwnProperty('AccountId') || !rec.hasOwnProperty('Account')){
                rec['AccountId'] = '';
                rec['Account'] = {'Name' : '', 'Id': ''};
            }
            rec['isselected'] = isSelected;
            rec['rowclass'] = 'slds-hint-parent';
            if(rec['isselected']=== true) {
                rec['rowclass'] = rec['rowclass'] + ' slds-is-selected';
            }
            
            this.allContactsById[rec.Id] = rec;
        }
        this.isLoading = false;
        this.metadataObj['isStepOne'] = true;
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

    seqSelectionHandler(event) {
        const selecteRecordId = event.detail.selectedRecordId;
        this.surveyId = selecteRecordId;
        this.getSequenceById(this.surveyId);
    }
    emailSelectionHandler(event) {
        const selecteRecordId = event.detail.selectedRecordId;
        console.log('selecteRecordId=' + selecteRecordId);
        this.emailTemplateId = selecteRecordId;
        this.getEmailTemplateById(selecteRecordId)
    }
    getSequenceById(surveyId) {
        getSequenceById({
            surveyId: surveyId
        })
        .then(result => {
            var resObj = JSON.parse(result);

            if (resObj.statusCode == '2000') {
                this.relatedquestions = resObj.responseDetails;
                if (this.relatedquestions.length > 0) {
                    this.showRelatedQuestions = true;
                }
            } else if (resObj.statusCode == '2100') {

            }
        })
        .catch(error => {
            this.handleErrorBlock(error);
        });
    }
    getEmailTemplateById(emailTemplateId) {
        //console.log('getEmailTemplateById');
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

    updateMetadataObj(currentStep) {
        //please ensure that this.stepsNumberArr is also updated correctly
        this.metadataObj['isStepOne'] = currentStep == '1';
        this.metadataObj['isStepTwo'] = currentStep == '2';
        this.metadataObj['isStepThree'] = currentStep == '3';
        this.metadataObj['isStepFour'] = currentStep == '4';
        this.metadataObj['isStepFive'] = currentStep == '5';

        if(currentStep === '4') {
            this.labels['Next'] = this.labels.Send;
        } else {
            this.labels['Next'] = this.labels.NextDummy;
        }
    }
 
    get isEnableNext() {
        return this.currentStep != this.stepsNumberArr[this.stepsNumberArr.length-1] + "";
    }
 
    get isEnablePrev() {
        return this.currentStep != this.stepsNumberArr[0] + "";
    }
    get isEnableCancel() {
        return this.currentStep == this.stepsNumberArr[0] + "";
    }
 
    get isEnableFinish() {
        return this.currentStep === this.stepsNumberArr[this.stepsNumberArr.length-1] + "";
    }
 
    handleNext(){
        let currentStepIndex = -1;
        for(let i=0;i<this.stepsNumberArr.length;i++) {
            if(this.currentStep == this.stepsNumberArr[i] + "") {
                currentStepIndex = i;
                break;
            }
        }
        if(currentStepIndex < 0 || currentStepIndex > this.stepsNumberArr.length) {
            currentStepIndex = -1;
        }
        let nextStepIndex = currentStepIndex + 1;
        let prevStep = this.currentStep;
        this.currentStep = (parseInt(this.stepsNumberArr[nextStepIndex])) + "";
        if(prevStep == '1') {
            this.generateSelectContactList();
        }
        this.validateKineticDetailSection(prevStep);
        if(prevStep == '4') {
            this.handleFinish();
        }
        this.updateMetadataObj(this.currentStep);
    }
    handlePrev(){
        let currentStepIndex = -1;
        for(let i=0;i<this.stepsNumberArr.length;i++) {
            if(this.currentStep == this.stepsNumberArr[i] + "") {
                currentStepIndex = i;
                break;
            }
        }
        if(currentStepIndex < 0 || currentStepIndex> this.stepsNumberArr.length) {
            currentStepIndex = -1;
        }
        let prevStepIndex = currentStepIndex - 1;
        this.currentStep = (parseInt(this.stepsNumberArr[prevStepIndex])) + "";
        this.updateMetadataObj(this.currentStep);
    }
    generateSelectContactList() {
        this.selectedContactList = Object.values(this.allContactsById);
        var selectedContacts = [];
        this.selectedContactList = this.selectedContactList.filter(function (record) {
                if(record.isselected === true) {
                    selectedContacts.push(record.Id);
                    return true;
                } 
                return false;
            }
        );
        this.contactIds = selectedContacts;
    }

    validateKineticDetailSection(prevStep) {
        if(prevStep == '1' && this.currentStep !== '1' && this.selectedContactsCount <= 0) {
            this.currentStep = '1';
            this.showErrorMessage(this.labels.error_selectatleastonecontact);
        }
        if(prevStep == '2' && this.currentStep !== '2' && this.isInValidValue(this.surveyId)) {
            this.currentStep = '2';
            this.showErrorMessage(this.labels.error_selectvalidsurvey);
        }
        if(prevStep == '3' && this.currentStep !== '3' && this.isInValidValue(this.emailTemplateId) && this.isInValidValue(this.smsTemplate)) {
            this.currentStep = '3';
            this.showErrorMessage(this.labels.error_selectvalidtemplate);
        }

        if(prevStep == '4'){
            if(this.sendAutoReminders === true ) {
                if((this.daysForFirstReminder === null || this.daysForFirstReminder === '' || this.daysForFirstReminder === undefined)){
                    this.currentStep = '4';    
                    this.showErrorMessage(this.labels.error_daysForFirstReminderRequired);
                }
        
                if((this.daysbetweenReminder === null || this.daysbetweenReminder === '' || this.daysbetweenReminder === undefined)){
                    this.currentStep = '4';
                    this.showErrorMessage(this.labels.error_daysbetweentworeminder);
                }
            }
    
            if(this.daysbeforerequestexpires === null || this.daysbeforerequestexpires === '' || this.daysbeforerequestexpires === undefined){
                this.currentStep = '4';
                this.showErrorMessage(this.labels.error_TTLDays);
            }
        }
    }

    showErrorMessage(message, errorTitle) {
        const event = new ShowToastEvent({
            title: 'Kinetic Sender',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    isInValidValue(v) {
        if(v === undefined || v === null || v === '' ) {
            return true;
        }
        return false;
    }

    isValidToSave() {
        //need to add some logic
        if(this.isInValidValue(this.surveyId)){
            this.showErrorMessage(this.labels.error_selectvalidsurvey);
            return false;
        }

        if(this.isInValidValue(this.contactIds) || this.contactIds.length === 0 ){
            this.showErrorMessage(this.labels.error_selectatleastonecontact, 'Recipient Required');
            return false;
        }

        if(this.isInValidValue(this.emailTemplateId) && this.isInValidValue(this.smsTemplate)){
            this.showErrorMessage(this.labels.error_selectvalidtemplate);
            return false;
        }

        if(this.isInValidValue(this.deliveryMethod)) {
            this.showErrorMessage(this.labels.error_selectvaliddeliverymethod);
            return false;
        }

        if(this.sendAutoReminders === true 
            && (this.daysForFirstReminder === null || this.daysForFirstReminder === '' || this.daysForFirstReminder === undefined)){
                this.showErrorMessage(this.labels.error_daysForFirstReminderRequired);
                return false;
        }

        if(this.sendAutoReminders === true 
            && (this.daysbetweenReminder === null || this.daysbetweenReminder === '' || this.daysbetweenReminder === undefined)){
                this.showErrorMessage(this.labels.error_daysbetweentworeminder);
                return false;
        }

        if(this.daysbeforerequestexpires === null || this.daysbeforerequestexpires === '' || this.daysbeforerequestexpires === undefined){
            this.showErrorMessage(this.labels.error_TTLDays);
            return false;
        }

        return true;
    }

    navigateToRecordPage() {
        
        if(this.recordId !== undefined) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: this.objectapiname,
                    actionName: 'view'
                }
            });
        } else {
            // Navigate to the Question home page
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.objectapiname,
                    actionName: 'home',
                },
            });
        }
    }

    handleCancel() {
        //need to handle to delete the dependent questions
        // <<TO DO>>
        this.navigateToRecordPage();

    }
    handleFinish(){
        this.isLoading = true;
        if(!this.isValidToSave()) {
            this.isLoading = false;
            return false;
        }
    
        console.log('handleSubmit');
        this.submitForm();
    }

    validateKineticUsage() {
        var numberOfInvitesToBeSent = this.contactIds.length;
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
    submitForm() {
        console.log('submitForm...');
        if(this.job.Url != undefined && this.job.Url.length >0) {
            this.isLoading = false;
            return 0;
        }

        if(!this.validateKineticUsage()) {
            this.isLoading = false;
            this.handleErrorBlock({'body': {'message': allowedSMSEmailLimitExceededString}});
            this.currentStep = '4';
            this.updateMetadataObj(this.currentStep);
            return 0;
        }

        createJob({
            surveyId: this.surveyId,
            contactIds: this.contactIds,
            emailTemplateId: this.emailTemplateId,
            smsContent: this.smsTemplate,
            delivery: this.deliveryMethod,
            sendAutoReminders: this.sendAutoReminders,
            daysForFirstReminder: this.daysForFirstReminder,
            daysbetweenReminder: this.daysbetweenReminder,
            daysbeforerequestexpires: this.daysbeforerequestexpires
        })
        .then(result => {
            this.isLoading = false;
           // console.log(result);
            var resObj = JSON.parse(result);
            if (resObj.statusCode == '2000') {
                this.job = resObj.responseDetails;
                this.job.Url = '/' + this.job.Id;
                this.recordId = this.job.Id;
            } else if (resObj.statusCode == '2100') {
                this.handleErrorBlock(resObj.responseDetails);
            }
        })
        .catch(error => {
            this.handleErrorBlock(error);
        });
    }

    handleFinishAction(event) {
        this.navigateToRecordPage();
    }

    handleInputFieldChange(event) {
        let fieldname = event.target.name;
        if(fieldname === 'sendAutoReminders'){
            this.sendAutoReminders = event.target.checked;
        }
        if(fieldname === 'daysForFirstReminder') {
            this.daysForFirstReminder = event.target.value;
            if(this.daysForFirstReminder < 0) {
                this.daysForFirstReminder = 0;
            }
        }
        if(fieldname === 'daysbetweenReminder') {
            this.daysbetweenReminder = event.target.value;
            if(this.daysbetweenReminder < 0) {
                this.daysbetweenReminder = 0;
            }
        }

        if(fieldname === 'daysbeforerequestexpires') {
            this.daysbeforerequestexpires = event.target.value;
            if(this.daysbeforerequestexpires < 0) {
                this.daysbeforerequestexpires = 0;
            }
            if(this.daysbeforerequestexpires > 10) {
                this.daysbeforerequestexpires = 10;
            }
            this.setExpirationDate();
        }
    }  
}