import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getKineticFormConfigurationCustomSetting from '@salesforce/apex/createEditKineticQuestionLWCHelper.getKineticFormConfigurationCustomSetting';
import getExtraFields from '@salesforce/apex/createEditKineticQuestionLWCHelper.getExtraFields';
import checkPermissions from '@salesforce/apex/createEditKineticQuestionLWCHelper.checkPermissions';
import getExistingKineticQuestion from '@salesforce/apex/createEditKineticQuestionLWCHelper.getExistingKineticQuestion';
import getRelatedFileIds from '@salesforce/apex/createEditKineticQuestionLWCHelper.getRelatedFileIds';
import doDirtyDataCleanup from '@salesforce/apex/createEditKineticQuestionLWCHelper.doDirtyDataCleanup';
import invalidQuestionText from '@salesforce/label/c.Invalid_data_Enter_Question_Text';
import invalidValues from '@salesforce/label/c.Invalid_data_Enter_Values';
import specifycommaseparatedvalues from '@salesforce/label/c.Specify_Comma_Separated_Values_for_the_chosen_field_type';
import valuemustnotstartwithcomma from '@salesforce/label/c.Invalid_Data_Values_must_not_start_with_Comma';
import defaultvaluemustnotstartwithcomma from '@salesforce/label/c.Invalid_Data_Default_Value_must_not_start_with_Comma';
import valuemustnotendwithcomma from '@salesforce/label/c.Invalid_Data_Values_must_not_end_with_Comma';
import defaultvaluemustnotendwithcomma from '@salesforce/label/c.Invalid_Data_Default_Value_must_not_end_with_Comma';
import nomultipledefaultvalueforradiobutton from '@salesforce/label/c.Invalid_Data_Question_of_type_Radio_Button_can_not_have_multiple_Default_Values';
import defaultvalueshouldbeoneofthevalues from '@salesforce/label/c.Invalid_data_Default_Value_must_be_one_of_the_Values';
import Success from '@salesforce/label/c.success';
import Edit_Question from '@salesforce/label/c.Edit_Question';
import Question_Created from '@salesforce/label/c.Question_Created';
import defaultImage from '@salesforce/resourceUrl/SurveyCamera';

export default class CreateEditKineticQuestionHome extends NavigationMixin(LightningElement)  {
    @api recordId;
    originalRecId;
    @track currentStep = '1';
    @track metadataObj = {'isStepOne':true};
    stepsNumberArr = [];
    @track selectedValue = {};
    @track quesTypes = [];
    @track childquestType = [];
    @track isLoading = true;
    @track showCustomQuestionNumber = false;
    @track labels = {};
    @track objectapiname = 'Kinetics__Kinetic_Question__c';
    @track fieldsetname = 'Kinetics__More_Details';
    @track extraDetailFields = [];
    originalQuestionRecord = {};
    @track isModalOpen = false;
    @track values = [];
    isCreateMode = true;
    isEditMode = false;
    fileAttachTitleVsId;

    connectedCallback() {
        this.resetToDefaults();
        this.initializeLabels();
        
        // @wire(getRecord, { recordId: this.recordId, modes: ['View'] })
        // questionRec;

        checkPermissions().then(permission =>{
            if(permission === true) {
                getKineticFormConfigurationCustomSetting().then(data=>{
                    //get the entire map
                    let ssetting = JSON.parse(data);
                    // if(ssetting.hasOwnProperty('ArxxusRFMv1__Show_Custom_Question_Number__c')) {
                    //     this.showCustomQuestionNumber = ssetting.ArxxusRFMv1__Show_Custom_Question_Number__c;
                    // }
                    this.showCustomQuestionNumber = false;
                    this.isLoading =false;
                })
                .catch(error =>{
                    this.showErrorMessage(error.body.message);
                    console.log('error',error);
                    this.isLoading =false;
                });
        
                getExtraFields({'objectname': this.objectapiname, 'fieldsetName': this.fieldsetname}).then(data=>{        
                    //get the entire map
                    this.extraDetailFields = JSON.parse(data); 
                    for(let i=0;i<this.extraDetailFields.length;i++) {
                        this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
                        if(this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                            this.extraDetailFields[i]['value'] = this.selectedValue[this.extraDetailFields[i].fieldPath];
                        }
                    }
                    this.isLoading =false;
                })
                .catch(error =>{
                    this.showErrorMessage(error.body.message);
                    console.log('error',error);
                    this.isLoading =false;
                });
                getExistingKineticQuestion({'recordId': this.recordId}).then(data =>{
                    let quesList = JSON.parse(data);
                    if(quesList.length > 0) {
                        this.isEditMode = true;
                        this.isCreateMode = false;
                        this.selectedValue = quesList[0];
                        this.originalRecId = this.recordId;
                        this.originalQuestionRecord = JSON.parse(JSON.stringify(quesList[0]));
                    }
                    var qTypeMap = this.getChildQuestionTypeMap();
                    var reverseMapByType = {};
                    for(var key in qTypeMap){
                        for(var tindex = 0; tindex<qTypeMap[key].length; tindex++) {
                            reverseMapByType[qTypeMap[key][tindex].value] = key;
                        }
                    }
                    this.selectedValue['Kinetics__Field_Type__c_parent'] = reverseMapByType[this.selectedValue['Kinetics__Field_Type__c']];
                    for(var l=0;l<this.quesTypes.length;l++){
                        this.quesTypes[l].isselected = false;
                        if(this.quesTypes[l].value === this.selectedValue['Kinetics__Field_Type__c_parent']) {
                            this.quesTypes[l].isselected = true;
                        }
                    }
                    this.childquestType = this.getchildquestType();
                    this.callVisualPickerMethod();
                    this.isLoading =false;
                }).catch(error => {
                    this.showErrorMessage(error.body.message);
                    console.log('error',error);
                    this.isLoading =false;
                });
            }
        }).catch(error => {
            console.log('error',error);
            this.isLoading =false;
            this.showErrorMessage(error.body.message);
        });
    }

    initializeLabels() {
        this.labels['headerTitle'] = 'Questions';
        this.labels['headerSubTitle'] = 'Edit Questions';
        this.labels['firstStepHelpText'] = 'Select Question Category';
        this.labels['secondStepHelpText'] = 'Select Specific Question Type';
        this.labels['thirdStepHelpText'] = 'Enter Question Information';
        //this.labels['fourthStepHelpText'] = 'Specify Photo and Attachment requirements';
        this.labels['fourthStepHelpText'] = 'Additional Details';
        //this.labels['sixthStepHelpText'] = 'Specify Dependent Follow Up Question';
        this.labels['fifthStepHelpText'] = 'Question Attributes';
        this.labels['sixthStepHelpText'] = 'Activate the Question';
    }

    resetToDefaults() {
        this.selectedValue = {
            'Kinetics__Field_Type__c_parent': 'Text',
            'Kinetics__Field_Type__c': 'Text',
            'Kinetics__Custom_Question_Number__c': null,
            'Kinetics__Question__c': '',
            'Kinetics__Default_Value__c': '',
            'Kinetics__Values__c': '',
            'Kinetics__Take_Photo__c': false,
            'Kinetics__Is_Photo_Mandatory__c': false,
            'Kinetics__Status__c': 'Active',
            'Kinetics__Capture_Notes__c': true,
            'Kinetics__Attach_Photos_or_Files__c': true && !this.isFileType,
            'Kinetics__Assign_Tasks__c': true
        };

        this.showCustomQuestionNumber = false;
        this.stepsNumberArr = [1,2,3,4,5,6];
        this.quesTypes = this.getquesTypes();
        this.childquestType = this.getchildquestType();
    }

    getquesTypes() {
        return [
            { label: 'Text', value: 'Text', icon: 'standard:text', description: 'Text, Text Area, Email or URL', isselected:true},
            { label: 'Picklist', value: 'Picklist', icon: 'utility:picklist_type', description: 'Picklist or Multi-Select Picklist', isselected:false},
            { label: 'Number', value: 'Number', icon: 'standard:number_input', description: 'Number, Currency or Percentage', isselected:false },
            { label: 'Date', value: 'Date', icon: 'standard:date_input', description: 'Date or Date & Time', isselected:false},
            { label: 'Interactive', value: 'Interactive', icon: 'utility:touch_action', description: 'Signature, Photo or File, Star Rating, NPS or location', isselected:false},
            /*//commenting below type, because we are not actively using this yet
             { label: 'App', value: 'App', icon: 'utility:keypad', description: 'Third party app', isselected:false} */
        ];
    }

    getChildQuestionTypeMap () {
        var qTypeMap={};
        qTypeMap['Text'] = [
            { label: 'Text', value: 'Text', icon: 'standard:text', description: 'Capture a short answer as free text' },
            { label: 'Text Area', value: 'Text Area', icon: 'standard:textarea', description: 'Capture a long answer as free text' },
            { label: 'Email', value: 'Email', icon: 'utility:email', description: 'Capture an email address' },
            { label: 'URL', value: 'URL', icon: 'utility:linked', description: 'Capture a website address'}
        ];
        qTypeMap['Picklist'] = [
            { label: 'Multi-Select Picklist', value: 'Checkbox', icon: 'utility:list', description: 'Capture multiple checkbox values from a list' },
            { label: 'Picklist', value: 'Radio Button', icon: 'utility:radio_button', description: 'Capture a single value from a list' },
            { label: 'Pass/Fail', value: 'Pass Fail', icon: 'utility:locker_service_console', description: 'Capture a Pass or Fail result linked to Knowledge' }
        ];
        qTypeMap['Number'] = [
            { label: 'Number', value: 'Number', icon: 'standard:number_input', description: 'Capture any number' },
            { label: 'Currency', value: 'Currency', icon: 'standard:currency', description: 'Capture a currency amount' },
            { label: 'Percentage', value: 'Percentage', icon: 'utility:percent', description: 'Capture a percentage number' }
        ];
        qTypeMap['Date'] = [
            { label: 'Date', value: 'Date', icon: 'standard:date_input', description: 'Capture a date from a popup window' },
            { label: 'Date & Time', value: 'Date & Time', icon: 'standard:date_time', description: 'Capture a date and time from a popup window' }
        ];
        qTypeMap['Interactive'] = [
            // { label: 'Photo', value: 'Photo', icon: 'standard:photo', description: 'Allows users to capture a photo from the mobile device camera or photo album' },
            // { label: 'Advanced Search BETA', value: 'Advanced Search BETA', icon: 'standard:search', description: 'Allows users to lookup and validate a question answer against an existing record' },
            { label: 'Signature', value: 'Signature', icon: 'utility:edit', description: 'Capture a handwritten signature'},
            { label: 'Photo or File', value: 'File', icon: 'utility:upload', description: 'Capture a photo or file'},
            { label: 'Rating', value: 'Rating', icon: 'utility:rating', description: 'Capture a 1 to 10 star rating'},
            { label: 'NPS', value: 'Net Promoter Score', icon: 'utility:like', description: 'Capture a Net Promotor Score rating'},
            { label: 'Geo Location', value: 'Geo Location', icon: 'utility:location', description: 'Capture the location of the recipient'},
        ];
       /* //commenting below section, as we are not using these question types as of yet
       qTypeMap['App'] = [
            //need to handle below imageSrc part correctly, but for now for demo, added hard coded urls
            // { label: 'FirstAML', value: 'Block', icon: '', description: 'FirstAML', imageSrc: ''},
            { label: '', value: 'FrankieOneBlock', icon: '', description: 'FrankieOne', imageSrc:'https://uploads-ssl.webflow.com/5f56d07000f5c31eaaa6066f/615d3de981b39b84ea356d4f_Frame%202.png'},
            { label: '', value: 'Stripe', icon: '', description: 'Stripe', imageSrc: 'http://t3.gstatic.com/images?q=tbn:ANd9GcSJHbnfk81kA_5mIj81yhRy3R2LRx3S11OyMjC68QeONsOp5DXx'},
            { label: '', value: 'Calendly', icon: '', description: 'Calendly', imageSrc: 'https://images.g2crowd.com/uploads/product/image/large_detail/large_detail_9b95c3b92b1ef692b5f69baaec6579d5/calendly.png'},
        ]; */
        return qTypeMap;
    }
    getchildquestType (questTypeCategory) {
        let questionTypeArr = [];
        let selectedQuestionType_Parent = this.selectedValue['Kinetics__Field_Type__c_parent'];
        if(questTypeCategory !== undefined) {
            selectedQuestionType_Parent = questTypeCategory;
        }
        
        var qTypeMap = this.getChildQuestionTypeMap();
        if(qTypeMap.hasOwnProperty(selectedQuestionType_Parent)) {
            questionTypeArr = qTypeMap[selectedQuestionType_Parent];
        }
        var arrValue=[];
        for(let j = 0;j<questionTypeArr.length;j++) {
            arrValue.push(questionTypeArr[j].value);
        }
        if(arrValue.indexOf(this.selectedValue['Kinetics__Field_Type__c']) < 0) {
            this.selectedValue['Kinetics__Field_Type__c'] = questionTypeArr[0].value;
        }
        
        return questionTypeArr;
    }

    callVisualPickerMethod() {
        this.template.querySelector('c-visual-picker').updateSelectedValue(this.selectedValue);
    }
    handleChange(event) {
        this.selectedValue[event.target.name] = event.target.value;
    }
    handleToggleChange(event) {
        this.selectedValue[event.target.name] = event.target.checked;
    }
    handleInputFieldChange(event) {
        this.selectedValue[event.target.fieldName] = event.target.value;
        let fieldName = event.target.fieldName;
        let fieldValue = event.target.value;
        if(fieldName == 'Kinetics__Take_Photo__c' && fieldValue === false) {
            this.selectedValue['Kinetics__Is_Photo_Mandatory__c'] = false;
        }
    }   

    handlefieldvalueupdate(event) {
        this.selectedValue = event.detail.selectedValue;
        this.childquestType = this.getchildquestType();
        if((this.selectedValue['Kinetics__Field_Type__c'] !== 'Radio Button' 
            && this.selectedValue['Kinetics__Field_Type__c'] !== 'Checkbox')) {
            this.selectedValue['Kinetics__Values__c'] = '';
            this.selectedValue['Kinetics__Default_Value__c'] = '';
        }

        if(this.selectedValue['Kinetics__Field_Type__c'] == 'File') {
            this.selectedValue['Kinetics__Attach_Photos_or_Files__c'] = false;
        }
        for(let i=0;i<this.extraDetailFields.length;i++) {
            this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
            if(this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                this.extraDetailFields[i]['value'] = this.selectedValue[this.extraDetailFields[i].fieldPath];
            }
        }
    }

    get showPhotoMandatoryCheckbox() {
        return this.selectedValue['Kinetics__Take_Photo__c'];
    }
    get showRadio_dependantFields() {
        // var dependentFieldsIndex = 4;
        // if(this.extraDetailFields.length > 0) {
        //     dependentFieldsIndex = 5;
        // }

        if(((this.selectedValue['Kinetics__Field_Type__c'] === 'Radio Button'))) {
            // 6 or 5 number step is for showing additional details section where question can have custom fields created in customers org
            // let index = this.stepsNumberArr.indexOf(6);
            // if (index <= -1) {
            //     //if 6 is not present in array then push 6 at index of 5
            //     this.stepsNumberArr.splice(dependentFieldsIndex, 0, 6);
            // }
            return true;
        } else {
            // 5 number step is for showing additional details section where question can have custom fields created in customers org
            // const index = this.stepsNumberArr.indexOf(5);
            // if (index > -1) {
            //     this.stepsNumberArr.splice(index, 1);
            // }
            return false;
        }
    }
    get isCheckBoxType() {
        return ((this.selectedValue['Kinetics__Field_Type__c'] === 'Checkbox'));
    }

    get isPassFailType() {
        if((this.selectedValue['Kinetics__Field_Type__c'] === 'Pass Fail')) {
            this.selectedValue['Kinetics__Values__c'] = 'Pass, Fail, N/A';
            return true;
        }
        return false;
    }
    
    get isFileType() {
        return ((this.selectedValue['Kinetics__Field_Type__c'] === 'File'));
    }
    get showAdditionalDetailStep() {
        if(this.extraDetailFields.length > 0) {
            // 4 number step is for showing additional details section where question can have custom fields created in customers org
            let index = this.stepsNumberArr.indexOf(4);
            if (index <= -1) {
                //if 4 is not present in array then push 4 at index of 3
                this.stepsNumberArr.splice(3, 0, 4);
            }
            return true;
        } else {
            // 4 number step is for showing additional details section where question can have custom fields created in customers org
            const index = this.stepsNumberArr.indexOf(4);
            if (index > -1) {
                this.stepsNumberArr.splice(index, 1);
            }
            return false;
        }
    }

    get showRadio_Checkbox_dependantFields() {
        return (this.showRadio_dependantFields || this.isCheckBoxType || this.isPassFailType);
    }

    handlepopupclose(event) {
        this.isModalOpen = event.detail.isModalOpen;
        this.isLoading =false;
    }
    maintainSelectedValues(questionRec) {
        this.recordId = questionRec.id;
        this.selectedValue['Id'] = this.recordId;

    }
    addQuestionAttachment() {
        //imageURL='/sfc/servlet.shepherd/document/download/<YOUR FILE ID>';
        //imageURL = '/sfc/servlet.shepherd/version/download/<YOUR_contentVersion_ID>
        this.isLoading =true;
        this.recordCreaterHelper().
            then(questionRec => {
                this.maintainSelectedValues(questionRec);
                //code to show the attachment popup
                
                getRelatedFileIds({'questionId': this.recordId}).then(data => {
                    this.fileAttachTitleVsId = JSON.parse(data);
                    
                    let obj = {'key': 'QuestionAttachment', 'value':'', 'existingAtt':defaultImage, 'existingAttId':undefined};
                    if(this.fileAttachTitleVsId.hasOwnProperty('QuestionAttachment')) {
                        let imageURL = '/sfc/servlet.shepherd/version/download/' +this.fileAttachTitleVsId['QuestionAttachment'];
                        obj.existingAtt = imageURL;
                        obj.existingAttId = this.fileAttachTitleVsId['QuestionAttachment'];
                    }
                    this.values = [obj];
                    this.isModalOpen = true;
                }).catch(error => {
                    this.isLoading =false;
                    this.showErrorMessage(error.body.message);
                    console.log('error',error);
                });
            })
            .catch(error => {
                this.isLoading =false;
                this.showErrorMessage(error.body.message);
            }
        );
    }

    addOptionAttachments(event) {
        this.isLoading =true;
        this.recordCreaterHelper().
            then(questionRec => {
                this.maintainSelectedValues(questionRec);
                getRelatedFileIds({'questionId': this.recordId}).then(data => {
                    this.fileAttachTitleVsId = JSON.parse(data);
                    //code to show the attachment popup
                    
                    const optionsArr = this.selectedValue.Kinetics__Values__c.split(',');
                    this.values = [];
                    for(var i=0;i<optionsArr.length;i++) {
                        let op = optionsArr[i].trim();
                        let obj = {'key': op, 'value':op,'existingAtt':defaultImage, 'existingAttId':undefined};
                        if(this.fileAttachTitleVsId.hasOwnProperty(op)) {
                            let imageURL = '/sfc/servlet.shepherd/version/download/' +this.fileAttachTitleVsId[op];
                            obj.existingAtt = imageURL;
                            obj.existingAttId = this.fileAttachTitleVsId[op];
                        }
                        this.values.push(obj);
                    }
                    this.isModalOpen = true;
                }).catch(error => {
                    this.isLoading =false;
                    this.showErrorMessage(error.body.message);
                });
            })
            .catch(error => {
                this.isLoading =false;
                this.showErrorMessage(error.body.message);
            }
        );
    }

    handleOnStepClick(event) {
        let prevStep = this.currentStep;
        this.currentStep = event.target.value;
        this.validateQuestionDetailSection(prevStep);
        this.updateMetadataObj(this.currentStep);
    }

    updateMetadataObj(currentStep) {
        //please ensure that this.stepsNumberArr is also updated correctly
        this.metadataObj['isStepOne'] = currentStep == '1';
        this.metadataObj['isStepTwo'] = currentStep == '2';
        this.metadataObj['isStepThree'] = currentStep == '3';
        //this.metadataObj['isStepFour'] = currentStep == '4';
        //this.metadataObj['isStepFive'] = currentStep == '5';
        //this.metadataObj['isStepSix'] = currentStep == '6';
        //this.metadataObj['isStepSeven'] = currentStep == '7';
        this.metadataObj['isStepFour'] = currentStep == '4';
        this.metadataObj['isStepFive'] = currentStep == '5';
        this.metadataObj['isStepSix'] = currentStep == '6';
        
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
        this.validateQuestionDetailSection(prevStep);
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
    deleteHelper(recordId, idToReplace) {
        doDirtyDataCleanup({'questionId':recordId, 'isDelete': true})
            .then(() => {
                this.recordId = idToReplace;
                this.navigateToRecordPage();           
            })
            .catch(error => {
                this.showErrorMessage(error.body.message);
            }
        );
    }
    handleCancel() {
        this.isLoading = true;
        // <<TO DO>>
        if(this.originalRecId !== undefined && this.recordId !== undefined 
            && this.originalRecId != this.recordId) {
            this.deleteHelper(this.recordId, this.originalRecId);
        } else if(this.isCreateMode === true && this.recordId !== undefined) {
            this.deleteHelper(this.recordId, undefined);
        } else if (this.isEditMode === true 
            && this.originalQuestionRecord !== undefined
            && this.originalQuestionRecord.Id !== undefined) {
            const fields = JSON.parse(JSON.stringify(this.originalQuestionRecord));
            delete fields.Kinetics__Field_Type__c_parent;
            delete fields.Name;
            const recordInput = { apiName: this.objectapiname, fields };
            delete recordInput.apiName;
            updateRecord(recordInput).then(data => {
                this.recordId = recordInput.fields.Id;
                this.navigateToRecordPage();
            }).catch(error => {
                this.isLoading = false;
                this.showErrorMessage(error.body.message);
            });
        } else {
            this.navigateToRecordPage();
        }
    }
    isNotValidValue(v) {
        return (v == '' || v == null || v == undefined);
    }

    validateQuestionDetailSection(prevStep) {
    
        if(prevStep == '3' && this.currentStep !== '3') {
            if(!this.isValidToSave(this.selectedValue)){
                this.currentStep = '3';
            }
        } else if(prevStep == '4' && this.currentStep != '4') {
            if(!this.isExtraDetailSectionValid()) {
                this.currentStep = '4';
            }
        }
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: Edit_Question,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    isExtraDetailSectionValid () {
        var isValidExtraFields = true;
        for(let i=0;i<this.extraDetailFields.length;i++) {
            this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
            if(this.extraDetailFields[i]['required'] == true 
                && (!this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath) 
                    || (this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath) 
                        && this.isNotValidValue(this.selectedValue[this.extraDetailFields[i].fieldPath])))) {
                isValidExtraFields = false;
                break;
            }
        }
        if(isValidExtraFields == false) {
            this.showErrorMessage(invalidValues);
            return false;
        }
        return true;
    }

    isValidToSave(qd) {
        
        if(this.isNotValidValue(qd.Kinetics__Question__c)) {
            this.showErrorMessage(invalidQuestionText);
            return false;
        }

        if((qd.Kinetics__Field_Type__c === 'Radio Button' || qd.Kinetics__Field_Type__c === 'Checkbox' || qd.Kinetics__Field_Type__c === 'Picklist')) {			
			var valuesStr = this.isNotValidValue(qd.Kinetics__Values__c) ?  '' : qd.Kinetics__Values__c.trim().toLowerCase();
			var defaultValueStr = this.isNotValidValue(qd.Kinetics__Default_Value__c) ? '' : qd.Kinetics__Default_Value__c.trim().toLowerCase();
			
            if(this.isNotValidValue(valuesStr)) {
				this.showErrorMessage(invalidValues);
				return false;
			}
            if(!valuesStr.includes(',')) {
                this.showErrorMessage(specifycommaseparatedvalues);
                return false;
            }
            
			if(valuesStr.startsWith(',')) {
                this.showErrorMessage(valuemustnotstartwithcomma);
                return false;
            }
            if(defaultValueStr.startsWith(',')) {
                this.showErrorMessage(defaultvaluemustnotstartwithcomma);
                return false;
            }
			
			if(valuesStr.endsWith(',')) {
				this.showErrorMessage(valuemustnotendwithcomma);
				return false;
			}

			if(defaultValueStr.endsWith(',')) {
                this.showErrorMessage(defaultvaluemustnotendwithcomma);
                return false;
            }
            
            var defaultValues = [];
            var splitedDefaultValues = defaultValueStr.split(',');
            for(var i in splitedDefaultValues) {
                var defaultValue = splitedDefaultValues[i];
                defaultValue = this.isNotValidValue(defaultValue) ? '' : defaultValue.trim();
                if(!this.isNotValidValue(defaultValue)) {
                    defaultValues.push(defaultValue);
                }
            }
            
            var actualValues = [];
            var splitedActualValues = valuesStr.split(',');
            for(var j in splitedActualValues) {
                var actualValue = splitedActualValues[j];
                actualValue = this.isNotValidValue(actualValue) ?  '' : actualValue.trim();
                if(!this.isNotValidValue(actualValue)) {
                    actualValues.push(actualValue);
                }
            }
            
            if(qd.Kinetics__Field_Type__c === 'Radio Button') {
                if(defaultValues.length > 1 || defaultValueStr.includes(',')) {
                    this.showErrorMessage(nomultipledefaultvalueforradiobutton);
                    return false;
                }

                var defaultValue = this.isNotValidValue(defaultValueStr) ? '': defaultValues[0].trim();
                var isDefaultValueFoundInValue = false;
                
                if(!this.isNotValidValue(defaultValue)) {
                    if(actualValues.indexOf(defaultValue)>=0) {
                        isDefaultValueFoundInValue = true;
                    }
                }
                
                if(!this.isNotValidValue(defaultValue) && !isDefaultValueFoundInValue) {
                    this.showErrorMessage(defaultvalueshouldbeoneofthevalues);
                    return false;
                }
            } else if(qd.Kinetics__Field_Type__c === 'Checkbox') {
                var isValidDefaultValues = true;
                
                for(var index in defaultValues) {
                    if(!this.isNotValidValue(defaultValues[index]) && actualValues.indexOf(defaultValues[index]) <0) {
                        isValidDefaultValues = false;
                    }
                }
                  
                if(!isValidDefaultValues) {
                    this.showErrorMessage(defaultvalueshouldbeoneofthevalues);
                    return false;
                }
            }
		}
        
        return true;
    }

    navigateToRecordPage() {
        this.isLoading = false;
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

    showSuccessNotification() {
        var successMessage = Question_Created;
        if(this.isEditMode) {
            successMessage = 'Kinetic Questions Updated'
        }
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            }
        }).then(url => {
            const event = new ShowToastEvent({
                "title": Success,
                "variant": 'success',
                "message": successMessage
            });
            this.dispatchEvent(event);
        });
    }

    recordCreaterHelper() {
        if(this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }
    linkFollowupQuestion() {
        if(!this.isValidToSave(this.selectedValue)) {
            return false;
        }
        this.recordCreaterHelper().
            then(questionRec => {
                this.maintainSelectedValues(questionRec);
                this.addRelatedQuestions();
            })
            .catch(error => {
                this.showErrorMessage(error.body.message);
            }
        );
    }
    addRelatedQuestions() {
        var originalQuestionId = this.originalRecId;
        if(this.recordId !== undefined) {
            window.open('/apex/OptionBasedQuestion?id='+this.recordId+'&originalQuestionId='+originalQuestionId,'popup', 'height=500,width=600,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
        }
    }

    getRecordToSave() {
        const fields = JSON.parse(JSON.stringify(this.selectedValue));
        delete fields.Kinetics__Field_Type__c_parent;
        delete fields.Name;
        const recordInput = { apiName: this.objectapiname, fields };
        return recordInput;
    }

    createRecordHelper() {
        const recordInput = this.getRecordToSave();
        return createRecord(recordInput);
    }

    updateRecordHelper() {
        const recordInput = this.getRecordToSave();
        delete recordInput.apiName;
        return updateRecord(recordInput);
    }
    handleFinish(){
        this.isLoading = true;
        if(!this.isValidToSave(this.selectedValue)) {
            this.isLoading = false;
            return false;
        }
        
        this.recordCreaterHelper().
            then(questionRec => {
                this.isLoading = false;
                this.maintainSelectedValues(questionRec);
                this.showSuccessNotification();
                this.navigateToRecordPage(); 
            })
            .catch(error => {
                this.isLoading = false;
                this.showErrorMessage(error.body.message);
            }
        );
    }
}