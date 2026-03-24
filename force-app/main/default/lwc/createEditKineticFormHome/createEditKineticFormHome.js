import { LightningElement, api, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getSurveyConfigurationCustomSetting from '@salesforce/apex/createEditKineticFormLWCHelper.getSurveyConfigurationCustomSetting';
import getExtraFields from '@salesforce/apex/createEditKineticFormLWCHelper.getExtraFields';
import checkPermissions from '@salesforce/apex/createEditKineticFormLWCHelper.checkPermissions';
import getExistingKineticForms from '@salesforce/apex/createEditKineticFormLWCHelper.getExistingKineticForms';
import doDirtyDataCleanup from '@salesforce/apex/createEditKineticFormLWCHelper.doDirtyDataCleanup';
import getAllActiveKineticQuestions from '@salesforce/apex/createEditKineticFormLWCHelper.getAllActiveKineticQuestions';
import upsertKineticQuestions from '@salesforce/apex/createEditKineticFormLWCHelper.upsertKineticQuestions';
import Kinetic_Form_Edit from '@salesforce/label/c.Kinetic_Form_Edit';
import Kinetic_Form_Created from '@salesforce/label/c.Kinetic_Form_Created';
import getNumberOfAllowedQuestionsPerForm from '@salesforce/apex/createEditKineticFormLWCHelper.getNumberOfAllowedQuestionsPerForm';
import allowedQuestionsLimitExceededString from '@salesforce/label/c.allowedQuestionsLimitExceededString';

export default class CreateEditKineticFormHome extends NavigationMixin(LightningElement) {
    @api recordId;
    @track currentStep = '1';
    @track metadataObj = { 'isStepOne': true };
    @track selectedValue = {};
    @track isLoading = true;
    @track labels = {};
    @track objectapiname = 'Kinetics__Kinetic_Form__c';
    @track fieldsetname = 'Kinetics__More_Details';
    @track extraDetailFields = [];
    @track showInstruction = false;
    @track isModalOpen = false;
    @track allActiveQuestionsById = {};
    @track selectedQuestionCount = 0;
    @track selectedQuestionsList = [];
    originalRecId;
    stepsNumberArr = [];
    originalSurveyRecord = {};
    isCreateMode = true;
    isEditMode = false;
    existingSurveyQuestionIds = [];
    numberOfAllowedQuestionsPerForm;
    questionIndexByPageNumber = {};
    questionIndexBySectionNumber = {};
    pageNumberByFirstQuestionIndex = {};
    sectionNumberByFirstQuestionIndex = {};
    latestPageNumber = 0;
    latestSectionNumber = 0;

    @track templateStatus = true;

    connectedCallback() {
        this.resetToDefaults();
        this.initializeLabels();
        checkPermissions().then(permission => {
            if (permission === true) {
                getSurveyConfigurationCustomSetting().then(data => {
                    getExistingKineticForms({ 'recordId': this.recordId }).then(data => {
                        let surveyList = JSON.parse(data);
                        if (surveyList.length > 0) {
                            this.isEditMode = true;
                            this.isCreateMode = false;
                            this.selectedValue = surveyList[0];
                            this.originalRecId = this.recordId;
                            this.originalSurveyRecord = JSON.parse(JSON.stringify(surveyList[0]));
                            this.templateStatus = this.selectedValue['Kinetics__Status__c'] == 'Active';
                        }
                        getExtraFields({ 'objectname': this.objectapiname, 'fieldsetName': this.fieldsetname }).then(data => {
                            getAllActiveKineticQuestions({ 'kFormId': this.recordId }).then(data => {
                                const questionWrapperMap = JSON.parse(data);
                                const selectedQuestionsList = questionWrapperMap['kSelectedQuesDefList'];
                                const allActiveQuestionsList = questionWrapperMap['kQuestionDefList'];

                                this.allActiveQuestionsById = {};
                                this.generateQuestionWrapper(selectedQuestionsList, true);

                                this.generateQuestionWrapper(allActiveQuestionsList, false);
                                this.maintainPagebreakNumbers();
                                this.maintainSectionbreakNumbers();
                                this.isLoading = false;
                            }).catch(error => {
                                this.handleErrorBlock(error);
                            });
                            //get the entire map
                            this.extraDetailFields = JSON.parse(data);
                            var extraRequiredFields = [];
                            for (let i = 0; i < this.extraDetailFields.length; i++) {
                                if (this.extraDetailFields[i].fieldPath == 'Name'
                                    || this.extraDetailFields[i].fieldPath == 'Kinetics__Status__c'
                                    || this.extraDetailFields[i].fieldPath == 'Kinetics__Instructions__c'
                                    || this.extraDetailFields[i].fieldPath == 'Kinetics__Questions_By_Page_No__c'
                                    || this.extraDetailFields[i].fieldPath == 'Kinetics__Section_Metadata__c') {
                                    continue;
                                }
                                extraRequiredFields.push(this.extraDetailFields[i]);
                            }
                            this.extraDetailFields = extraRequiredFields;
                            for (let i = 0; i < this.extraDetailFields.length; i++) {
                                if (this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                                    this.extraDetailFields[i]['value'] = this.selectedValue[this.extraDetailFields[i].fieldPath];
                                }
                            }
                        }).catch(error => {
                            this.handleErrorBlock(error);
                        });
                    }).catch(error => {
                        this.handleErrorBlock(error);
                    });

                    //get the entire map
                    // let ssetting = JSON.parse(data);
                    // if(ssetting.hasOwnProperty('ArxxusRFMv1__Show_Instructions__c')) {
                    //     this.showInstruction = ssetting.ArxxusRFMv1__Show_Instructions__c;
                    // }
                    this.showInstruction = true;
                }).catch(error => {
                    this.handleErrorBlock(error);
                });
                getNumberOfAllowedQuestionsPerForm({}).then(result => {
                    this.numberOfAllowedQuestionsPerForm = result;
                }).catch(error => {
                    this.handleErrorBlock(error);
                });
            }
        }).catch(error => {
            this.handleErrorBlock(error);
        });
    }

    handleErrorBlock(error) {
        console.log('error', error);
        this.isLoading = false;
        this.showErrorMessage(error.body.message);
    }
    generateQuestionWrapper(questionsList, isselectedList) {

        this.questionIndexByPageNumber = { 1: [1] };
        if (this.selectedValue.hasOwnProperty('Kinetics__Questions_By_Page_No__c')) {
            var questionIndexByNumber = JSON.parse(this.selectedValue['Kinetics__Questions_By_Page_No__c']);
            if (questionIndexByNumber != undefined && Object.keys(questionIndexByNumber).length > 0) {
                this.questionIndexByPageNumber = questionIndexByNumber;
            }
        }
        this.questionIndexBySectionNumber = {};
        if (this.selectedValue.hasOwnProperty('Kinetics__Section_Metadata__c')) {
            var questionIndexBySecNumber = JSON.parse(this.selectedValue['Kinetics__Section_Metadata__c']);
            if (questionIndexBySecNumber != undefined && Object.keys(questionIndexBySecNumber).length > 0) {
                this.questionIndexBySectionNumber = questionIndexBySecNumber;
            }
        }

        var pageNumberByQuestIndex = {};
        Object.entries(this.questionIndexByPageNumber).forEach(([pagenumber, indexArr]) => {
            if (indexArr.length > 0) {
                pagenumber = parseInt(pagenumber);
                pageNumberByQuestIndex[indexArr[0]] = pagenumber;

                if (this.latestPageNumber < pagenumber) {
                    this.latestPageNumber = pagenumber;
                }
            }
        });

        var sectionNumberByQuestIndex = {};
        Object.entries(this.questionIndexBySectionNumber).forEach(([sectionnumber, sectionWrapper]) => {
            
            if (sectionWrapper.questIndex.length > 0) {
                sectionnumber = parseInt(sectionnumber);
                sectionWrapper['sectionnumber'] = sectionnumber;
                sectionNumberByQuestIndex[sectionWrapper.questIndex[0]] = sectionWrapper;

                if (this.latestsectionNumber < sectionnumber) {
                    this.latestsectionNumber = sectionnumber;
                }
            }
        });

        for (var i = 0; i < questionsList.length; i++) {
            var questWrapper = {};
            questWrapper['text'] = questionsList[i]['Kinetics__Question__c'];
            questWrapper['type'] = questionsList[i]['Kinetics__Field_Type__c'];
            questWrapper['values'] = questionsList[i]['Kinetics__Values__c'] || '';
            questWrapper['helpText'] = questionsList[i]['Kinetics__Question_Help_Text__c'];
            questWrapper['isselected'] = isselectedList;
            questWrapper['name'] = questionsList[i]['Name'];
            questWrapper['id'] = questionsList[i]['Id'];
            questWrapper['index'] = -1;
            questWrapper['rowclass'] = 'slds-hint-parent';
            questWrapper['isPageBreakAdded'] = false;
            questWrapper['pagebreak'] = { 'pagenumber': -1 };
            questWrapper['isSectionBreakAdded'] = false;
            questWrapper['sectionbreak'] = { 'sectionnumber': -1, 'title': '', 'sectionnumberName': ''};
            if (isselectedList) {
                this.selectedQuestionCount = this.selectedQuestionCount + 1;
                questWrapper.rowclass = questWrapper.rowclass + ' slds-is-selected';
            }

            //get the index and id
            if (questionsList[i].hasOwnProperty('Kinetics__Kinetic_Form_Questions__r')
                && questionsList[i].Kinetics__Kinetic_Form_Questions__r.records != undefined
                && questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0] != undefined
                && questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0].Kinetics__Index__c != undefined) {
                questWrapper.index = questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0].Kinetics__Index__c;
                questWrapper['surveyQuestionId'] = questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0].Id;

                if (questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Question_Help_Text__c'] != undefined) {
                    questWrapper['helpText'] = questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Question_Help_Text__c'];
                }
                questWrapper['scoreSetting'] = {};
                if (questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Option_Score__c'] != undefined) {
                    questWrapper['scoreSetting'] = JSON.parse(questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Option_Score__c']);
                    if(Object.keys(questWrapper['scoreSetting']).length >0){
                        this.selectedValue.isScoringEnabled = true;
                    }
                }
                questWrapper['scoreConfirmed'] = false;
                if (questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Score_Confirmed__c'] != undefined) {
                    questWrapper['scoreConfirmed'] = questionsList[i].Kinetics__Kinetic_Form_Questions__r.records[0]['Kinetics__Score_Confirmed__c'];
                }

                questWrapper.isPageBreakAdded = pageNumberByQuestIndex.hasOwnProperty(questWrapper.index);
                questWrapper.pagebreak['pagenumber'] = pageNumberByQuestIndex.hasOwnProperty(questWrapper.index) ? pageNumberByQuestIndex[questWrapper.index] : 0;
                questWrapper.pagebreak['pagenumberName'] = pageNumberByQuestIndex.hasOwnProperty(questWrapper.index) ? 'Page Break' : '';

                questWrapper.isSectionBreakAdded = sectionNumberByQuestIndex.hasOwnProperty(questWrapper.index);
                questWrapper.sectionbreak['sectionnumber'] = sectionNumberByQuestIndex.hasOwnProperty(questWrapper.index) ? sectionNumberByQuestIndex[questWrapper.index].sectionnumber : 0;
                questWrapper.sectionbreak['sectionnumberName'] = sectionNumberByQuestIndex.hasOwnProperty(questWrapper.index) ? 'Section Break' + sectionNumberByQuestIndex[questWrapper.index].sectionnumber : '';
                questWrapper.sectionbreak['title'] = sectionNumberByQuestIndex.hasOwnProperty(questWrapper.index) ? sectionNumberByQuestIndex[questWrapper.index].title : '';

                this.existingSurveyQuestionIds.push(questWrapper['surveyQuestionId']);
            }
            
            this.allActiveQuestionsById[questWrapper.id] = questWrapper;
        }
    }

    maintainPagebreakNumbers() {
        var allQuestionsList = Object.values(this.allActiveQuestionsById);
        allQuestionsList = this.sortSelectedQuestionList(allQuestionsList, 'index');

        for (var i = 0; i < allQuestionsList.length; i++) {
            if (allQuestionsList[i].isPageBreakAdded === true) {
                this.pageNumberByFirstQuestionIndex[i] = parseInt(allQuestionsList[i].pagebreak['pagenumber']);
            }
        }
    }
    maintainSectionbreakNumbers() {
        var allQuestionsList = Object.values(this.allActiveQuestionsById);
        for (var i = 0; i < allQuestionsList.length; i++) {
            if (allQuestionsList[i].isSectionBreakAdded === true) {
                this.sectionNumberByFirstQuestionIndex[i] = parseInt(allQuestionsList[i].sectionbreak['sectionnumber']);
            }
        }
    }
    updateQuestionSelection(event) {
        //this.allQuestionsWrapperList = event.detail.allQuestionsWrapperList;
        this.allActiveQuestionsById = event.detail.allActiveQuestionsById;
        this.selectedQuestionCount = event.detail.selectedQuestionCount;
    }

    prepareQuestionsByPages() {
        var pagenumberTemp = 0;
        var questionIndexByPageNumberLocal = {};
        for (var i = 0; i < this.selectedQuestionsList.length; i++) {
            if (this.selectedQuestionsList[i].isPageBreakAdded) {
                pagenumberTemp = pagenumberTemp + 1;
                questionIndexByPageNumberLocal[pagenumberTemp] = [];
            }
            questionIndexByPageNumberLocal[pagenumberTemp].push(this.selectedQuestionsList[i].index);
        }

        if (Object.keys(questionIndexByPageNumberLocal).length == 0) {
            pagenumberTemp = 1;
            questionIndexByPageNumberLocal[pagenumberTemp] = [];
            for (var k = 0; k < this.selectedQuestionsList.length; k++) {
                questionIndexByPageNumberLocal[pagenumberTemp].push(this.selectedQuestionsList[k].index);
            }
        }
        this.latestPageNumber = pagenumberTemp + 1;
        this.selectedValue['Kinetics__Questions_By_Page_No__c'] = JSON.stringify(questionIndexByPageNumberLocal);
    }

    prepareQuestionsBySection() {
        var sectionnumberTemp = 0;
        var questionIndexBySectionNumberLocal = {};
        for (var i = 0; i < this.selectedQuestionsList.length; i++) {
            if (this.selectedQuestionsList[i].isSectionBreakAdded) {
                sectionnumberTemp = sectionnumberTemp + 1;
                questionIndexBySectionNumberLocal[sectionnumberTemp] = {'title':this.selectedQuestionsList[i].sectionbreak.title, 
                                                                        'questIndex': []};
            }
            if(sectionnumberTemp == 0) {
                continue;
            }
            
            questionIndexBySectionNumberLocal[sectionnumberTemp]['questIndex'].push(this.selectedQuestionsList[i].index);
        }

        this.latestSectionNumber = sectionnumberTemp;
        this.selectedValue['Kinetics__Section_Metadata__c'] = JSON.stringify(questionIndexBySectionNumberLocal);
    }

    updateQuestionIndex(event) {
        this.selectedQuestionsList = event.detail.selectedQuestionsList;
        this.pageNumberByFirstQuestionIndex = event.detail.pageNumberByFirstQuestionIndex;
        this.sectionNumberByFirstQuestionIndex = event.detail.sectionNumberByFirstQuestionIndex;

        this.prepareQuestionsByPages();
        this.prepareQuestionsBySection();
    }

    initializeLabels() {
        this.labels['headerTitle'] = 'Template Builder';
        this.labels['headerSubTitle'] = 'Edit Template';
        this.labels['firstStepHelpText'] = 'Specify Template Name';
        this.labels['secondStepHelpText'] = 'Select Questions';
        this.labels['thirdStepHelpText'] = 'Set Order';
        this.labels['fourthStepHelpText'] = 'Set Score';
        this.labels['fifthStepHelpText'] = 'Additional Details';
        this.labels['sixthStepHelpText'] = 'Activate the Template';
        this.labels['invalidSurveyText'] = 'Please provide valid name for Template';
    }

    resetToDefaults() {
        this.selectedValue = {
            'Name': '',
            'Kinetics__Instructions__c': '',
            'Kinetics__Status__c': 'Active',
            'Kinetics__Questions_By_Page_No__c': '{}',
            'Kinetics__Section_Metadata__c' : '{}'
        };

        this.templateStatus = true;
        this.stepsNumberArr = [1, 2, 3, 4, 5, 6];
    }

    handleInputFieldChange(event) {
        this.selectedValue[event.target.fieldName] = event.target.value;
    }

    handleToggleChange(event) {
        if('Kinetics__Status__c' == event.target.name) {
            this.selectedValue[event.target.name] = event.target.checked == true ? 'Active' : 'Inactive';
        } else {
            this.selectedValue[event.target.name] = event.target.checked;
        }
    }

    handlefieldvalueupdate(event) {
        this.selectedValue = event.detail.selectedValue;
        for (let i = 0; i < this.extraDetailFields.length; i++) {
            this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
            if (this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                this.extraDetailFields[i]['value'] = this.selectedValue[this.extraDetailFields[i].fieldPath];
            }
        }
    }

    get showAdditionalDetailStep() {
       
        if (this.extraDetailFields.length > 0) {
            // 5 number step is for showing additional details section where Survey can have custom fields created in customers org
            let index = this.stepsNumberArr.indexOf(5);
            if (index <= -1) {
                //if 5 is not present in array then push 5 at index of 4
                this.stepsNumberArr.splice(4, 0, 5);
            }
            return true;
        } else {
            // 5 number step is for showing additional details section where Survey can have custom fields created in customers org
            const index = this.stepsNumberArr.indexOf(5);
            if (index > -1) {
                this.stepsNumberArr.splice(index, 1);
            }
            return false;
        }
    }
    get showCaptureScoringStep() {
       
        if (this.selectedValue.isScoringEnabled === true) {
            // 4 number step is for showing capture scoring section 
            let index = this.stepsNumberArr.indexOf(4);
            if (index <= -1) {
                //if 4 is not present in array then push 4 at index of 3
                this.stepsNumberArr.splice(3, 0, 4);
            }
            return true;
        } else {
            // 4 number step is for showing capture scoring details section
            const index = this.stepsNumberArr.indexOf(4);
            if (index > -1) {
                this.stepsNumberArr.splice(index, 1);
            }
            return false;
        }
    }

    handlepopupclose(event) {
        this.isModalOpen = event.detail.isModalOpen;
        this.isLoading = false;
    }

    handleOnStepClick(event) {
        let prevStep = this.currentStep;
        this.currentStep = event.target.value;
        if (prevStep == '2') {
            this.generateSelectQuestionList();
        }
        if (parseInt(prevStep) < parseInt(this.currentStep)) {
            this.validateSurveyDetailSection(prevStep);
        }
        this.updateMetadataObj(this.currentStep);

    }

    updateMetadataObj(currentStep) {
        //please ensure that this.stepsNumberArr is also updated correctly
        this.metadataObj['isStepOne'] = currentStep == '1';
        this.metadataObj['isStepTwo'] = currentStep == '2';
        this.metadataObj['isStepThree'] = currentStep == '3';
        this.metadataObj['isStepFour'] = currentStep == '4';
        this.metadataObj['isStepFive'] = currentStep == '5';
        this.metadataObj['isStepSix'] = currentStep == '6';
    }

    get isEnableNext() {
        return this.currentStep != this.stepsNumberArr[this.stepsNumberArr.length - 1] + "";
    }

    get isEnablePrev() {
        return this.currentStep != this.stepsNumberArr[0] + "";
    }
    get isEnableCancel() {
        return this.currentStep == this.stepsNumberArr[0] + "";
    }

    get isEnableFinish() {
        return this.currentStep === this.stepsNumberArr[this.stepsNumberArr.length - 1] + "";
    }

    handleNext() {
        let currentStepIndex = -1;
        for (let i = 0; i < this.stepsNumberArr.length; i++) {
            if (this.currentStep == this.stepsNumberArr[i] + "") {
                currentStepIndex = i;
                break;
            }
        }
        if (currentStepIndex < 0 || currentStepIndex > this.stepsNumberArr.length) {
            currentStepIndex = -1;
        }
        let nextStepIndex = currentStepIndex + 1;
        let prevStep = this.currentStep;
        this.currentStep = (parseInt(this.stepsNumberArr[nextStepIndex])) + "";
        this.validateSurveyDetailSection(prevStep);
        this.updateMetadataObj(this.currentStep);
        if (prevStep == '2') {
            this.generateSelectQuestionList();
        }
    }
    generateSelectQuestionList() {
        this.selectedQuestionsList = Object.values(this.allActiveQuestionsById);
        this.selectedQuestionsList = this.selectedQuestionsList.filter(function (record) {
            return record.isselected === true;
        });
        this.selectedQuestionsList = this.sortSelectedQuestionList(this.selectedQuestionsList, 'index');

        if(Object.keys(this.pageNumberByFirstQuestionIndex).length ==0) {
            this.pageNumberByFirstQuestionIndex[0] = 1;
        }
        for (var i = 0; i < this.selectedQuestionsList.length; i++) {
            this.selectedQuestionsList[i].index = i + 1;

            this.selectedQuestionsList[i].isPageBreakAdded = this.pageNumberByFirstQuestionIndex.hasOwnProperty(i);
            this.selectedQuestionsList[i].pagebreak['pagenumber'] = this.pageNumberByFirstQuestionIndex.hasOwnProperty(i) ? this.pageNumberByFirstQuestionIndex[i] : 0;
            this.selectedQuestionsList[i].pagebreak['pagenumberName'] = this.pageNumberByFirstQuestionIndex.hasOwnProperty(i) ? 'Page Break' : '';

        }
        this.prepareQuestionsByPages();
        this.prepareQuestionsBySection();
    }

    sortSelectedQuestionList(selectedQuestionsList, sortingfieldname) {
        selectedQuestionsList.sort(function (x, y) {
            // true values first
            if(parseInt(x[sortingfieldname]) < 0 || parseInt(y[sortingfieldname]) < 0) return 1;
            return (parseInt(x[sortingfieldname]) - parseInt(y[sortingfieldname]));
        });

        return selectedQuestionsList;
    }

    handlePrev() {
        let currentStepIndex = -1;
        for (let i = 0; i < this.stepsNumberArr.length; i++) {
            if (this.currentStep == this.stepsNumberArr[i] + "") {
                currentStepIndex = i;
                break;
            }
        }
        if (currentStepIndex < 0 || currentStepIndex > this.stepsNumberArr.length) {
            currentStepIndex = -1;
        }
        let prevStepIndex = currentStepIndex - 1;
        this.currentStep = (parseInt(this.stepsNumberArr[prevStepIndex])) + "";
        this.updateMetadataObj(this.currentStep);
    }
    deleteHelper(recordId, idToReplace) {
        doDirtyDataCleanup({ 'recordId': recordId, 'isDelete': true })
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
        //need to handle to delete the dependent questions
        // <<TO DO>>
        if (this.originalRecId !== undefined && this.recordId !== undefined
            && this.originalRecId != this.recordId) {
            this.deleteHelper(this.recordId, this.originalRecId);
        } else if (this.isCreateMode === true && this.recordId !== undefined) {
            this.deleteHelper(this.recordId, undefined);
        } else if (this.isEditMode === true
            && this.originalSurveyRecord !== undefined
            && this.originalSurveyRecord.Id !== undefined) {
            const fields = JSON.parse(JSON.stringify(this.originalSurveyRecord));
            const recordInput = { apiName: this.objectapiname, fields };
            delete recordInput.apiName;
            updateRecord(recordInput).then(data => {
                this.recordId = recordInput.fields.Id;
                this.navigateToRecordPage();
            }).catch(error => {
                this.showErrorMessage(error.body.message);
            });
        } else {
            this.navigateToRecordPage();
        }
    }
    isNotValidValue(v) {
        return (v == '' || v == null || v == undefined);
    }

    isExtraDetailSectionValid() {
        var isValidExtraFields = true;
        for (let i = 0; i < this.extraDetailFields.length; i++) {
            this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
            if (this.extraDetailFields[i]['required'] == true
                && (!this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)
                    || (this.selectedValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)
                        && this.isNotValidValue(this.selectedValue[this.extraDetailFields[i].fieldPath])))) {
                isValidExtraFields = false;
                break;
            }
        }
        if (isValidExtraFields == false) {
            return false;
        }
        return true;
    }

    validateSurveyDetailSection(prevStep) {
        if (prevStep == '1' && this.currentStep !== '1') {
            if (!this.isValidToSave(this.selectedValue)) {
                this.currentStep = '1';
                //this.showErrorMessage('Please provide valid name for Template');
            }
        }
        if (prevStep == '2' && this.currentStep !== '2' && this.selectedQuestionCount <= 0) {
            this.currentStep = '2';
            this.showErrorMessage('Please select atleast one Kinetic question');
        }
        if (prevStep == '5' && this.currentStep != '5' && !this.isExtraDetailSectionValid()) {
            this.currentStep = '5';
            this.showErrorMessage('Please provide valid details');
        }
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: Kinetic_Form_Edit,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    isValidToSave(rec) {

        if (this.isNotValidValue(rec.Name)) {
            this.showErrorMessage(this.labels.invalidSurveyText);
            return false;
        }

        return true;
    }

    navigateToRecordPage() {

        if (this.recordId !== undefined) {
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
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            }
        }).then(url => {
            const event = new ShowToastEvent({
                "title": 'Success',
                "variant": 'success',
                "message": Kinetic_Form_Created
            });
            this.dispatchEvent(event);
        });
    }

    recordCreaterHelper() {
        if (this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }

    getRecordToSave() {
        delete this.selectedValue.isScoringEnabled;
        const fields = JSON.parse(JSON.stringify(this.selectedValue));
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

    handleFinish() {
        this.isLoading = true;
        if (!this.isValidToSave(this.selectedValue)) {
            this.isLoading = false;
            return false;
        }

        if (this.numberOfAllowedQuestionsPerForm < this.selectedQuestionsList.length) {
            this.isLoading = false;
            var errorObj = { 'body': { 'message': allowedQuestionsLimitExceededString.replace('{{numberOfAllowedQuestionsPerForm}}', '' + this.numberOfAllowedQuestionsPerForm) } };
            this.handleErrorBlock(errorObj);
            return false;
        }

        this.recordCreaterHelper().
            then(surveyRec => {
                this.recordId = surveyRec.id;
                var selectedQuestionsWrapper = [];
                for (var j = 0; j < this.selectedQuestionsList.length; j++) {
                    var slQuest = {};
                    slQuest['qid'] = this.selectedQuestionsList[j].id;
                    slQuest['index'] = this.selectedQuestionsList[j].index;

                    if (this.selectedQuestionsList[j].hasOwnProperty('surveyQuestionId')) {
                        slQuest['surveyQuestionId'] = this.selectedQuestionsList[j].surveyQuestionId;
                    }
                    if (this.selectedQuestionsList[j].hasOwnProperty('helpText') && this.selectedQuestionsList[j]['helpText'] != undefined) {
                        slQuest['helpText'] = this.selectedQuestionsList[j]['helpText'];
                    }
                    slQuest['scoreSetting'] = '{}';
                    if (this.selectedQuestionsList[j].hasOwnProperty('scoreSetting') && this.selectedQuestionsList[j]['scoreSetting'] != undefined) {
                        slQuest['scoreSetting'] = JSON.stringify(this.selectedQuestionsList[j]['scoreSetting']);
                    }
                    slQuest['scoreConfirmed'] = false;
                    if (this.selectedQuestionsList[j].hasOwnProperty('scoreConfirmed') && this.selectedQuestionsList[j]['scoreConfirmed'] != undefined) {
                        slQuest['scoreConfirmed'] = this.selectedQuestionsList[j]['scoreConfirmed'];
                    }
                    
                    selectedQuestionsWrapper.push(slQuest);
                }
                upsertKineticQuestions({
                    'listwrapperString': JSON.stringify(selectedQuestionsWrapper),
                    'kFormId': this.recordId,
                    'existingKFormQuestionIdsString': JSON.stringify(this.existingSurveyQuestionIds)
                }).then(data => {
                    this.showSuccessNotification();
                    this.navigateToRecordPage();
                    this.isLoading = false;
                }).catch(error => {
                    this.handleErrorBlock(error);
                });
            })
            .catch(error => {
                this.handleErrorBlock(error);
            }
            );
    }

    handleScoreConfirmed(event) {
        var questionUpdated = event.detail;

        for (var i = 0; i < this.selectedQuestionsList.length; i++) {
            if (this.selectedQuestionsList[i].id == questionUpdated.id) {
                this.selectedQuestionsList[i].scoreSetting = questionUpdated.scoreSetting;
                this.selectedQuestionsList[i].scoreConfirmed = questionUpdated.scoreConfirmed;
                break;
            }
        }
    }

}