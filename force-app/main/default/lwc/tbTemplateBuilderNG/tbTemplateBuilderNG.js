import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import kineticsResources from '@salesforce/resourceUrl/kineticsresources';
import getExtraFields from '@salesforce/apex/createEditKineticFormLWCHelper.getExtraFields';


export default class TbTemplateBuilderNG extends NavigationMixin(LightningElement) {
    chatgptLogo = kineticsResources + '/kineticsresources/images/chatgpt-logo-blue.png';
    @track disableChatGPT = false;
    isLoading = false;
    labels = {};
    @track selectedFormValue = {};
    existingRecord = {};
    @track objectapiname = 'Kinetics__Kinetic_Form__c';
    @api recordId;

    @track pagelist = [];

    @track templatePageMetadata = {};
    showExtraFields = false;
    @track fieldsetname = 'Kinetics__More_Details';


    connectedCallback() {
        this.resetToDefaults();
        this.initializeLabels();
    }

    @wire(getRecord, {
        recordId: '$recordId', fields: ['Kinetics__Kinetic_Form__c.Name', 'Kinetics__Kinetic_Form__c.Kinetics__Instructions__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Status__c', 'Kinetics__Kinetic_Form__c.Kinetics__Questions_By_Page_No__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Section_Metadata__c', 'Kinetics__Kinetic_Form__c.Kinetics__Template_Metadata__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Chat_GPT_Parameters__c', 'Kinetics__Kinetic_Form__c.Kinetics__Assistant__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Spreadsheet_Template__c'
        ]
    })
    templateformrecord({ error, data }) {
        if (data) {
            this.loadRecord(data);
        } else if (error) {
            this.showErrorMessage(error);
        } else if(data == undefined && error == undefined) {
            this.getExtraDetailsInfo();
        }
    }

    getExtraDetailsInfo() {
        getExtraFields({ 'objectname': this.objectapiname, 'fieldsetName': this.fieldsetname }).then(data => {
            //get the entire map
            this.extraDetailFields = JSON.parse(data);
            this.showExtraFields = this.extraDetailFields.length != 0;
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
            // for (let i = 0; i < this.extraDetailFields.length; i++) {
            //     if (this.templatePageMetadata.selectedFormValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
            //         this.extraDetailFields[i]['value'] = this.templatePageMetadata.selectedFormValue[this.extraDetailFields[i].fieldPath];
            //     }
            // }
            for (let i = 0; i < this.extraDetailFields.length; i++) {
                this.templatePageMetadata.selectedFormValue[this.extraDetailFields[i].fieldPath] = '';
                if (this.existingRecord != null && this.existingRecord.fields != null
                    && this.existingRecord.hasOwnProperty('fields')
                    && this.existingRecord.fields.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                    this.extraDetailFields[i]['value'] = this.existingRecord.fields[this.extraDetailFields[i].fieldPath].value;
                    this.templatePageMetadata.selectedFormValue[this.extraDetailFields[i].fieldPath] = this.extraDetailFields[i]['value'];
                }
            }
        }).catch(error => {
            this.handleErrorBlock(error);
        });
    }
    handlefieldvalueupdate(event) {
        this.templatePageMetadata.selectedFormValue = event.detail.selectedValue;
        for (let i = 0; i < this.extraDetailFields.length; i++) {
            this.extraDetailFields[i]['required'] = (this.extraDetailFields[i].dbRequired || this.extraDetailFields[i].required)
            if (this.templatePageMetadata.selectedFormValue.hasOwnProperty(this.extraDetailFields[i].fieldPath)) {
                this.extraDetailFields[i]['value'] = this.templatePageMetadata.selectedFormValue[this.extraDetailFields[i].fieldPath];
            }
        }
    }

    handleErrorBlock(error) {
        this.isLoading = false;
        this.showErrorMessage(error.body.message);
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Template Builder',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
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

    updateLastModifiedMetadata() {
        //this is done to have one place from where the changes are broadcasted, so that child component get the updated version
        this.templatePageMetadata = JSON.parse(JSON.stringify(this.templatePageMetadata));
    }

    loadRecord(existingRecord) {

        this.templatePageMetadata.selectedFormValue = {
            'Name': '',
            'Kinetics__Instructions__c': '',
            'Kinetics__Status__c': 'Active',
            'Kinetics__Questions_By_Page_No__c': '{}',
            'Kinetics__Section_Metadata__c': '{}',
            'Kinetics__Template_Metadata__c': '{}',
            'Kinetics__Chat_GPT_Parameters__c': '{}'
        };
        this.existingRecord = existingRecord;
        this.templatePageMetadata.selectedFormValue.Name = existingRecord.fields.Name.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Instructions__c = existingRecord.fields.Kinetics__Instructions__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Status__c = existingRecord.fields.Kinetics__Status__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Questions_By_Page_No__c = existingRecord.fields.Kinetics__Questions_By_Page_No__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Section_Metadata__c = existingRecord.fields.Kinetics__Section_Metadata__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c = existingRecord.fields.Kinetics__Template_Metadata__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Chat_GPT_Parameters__c = JSON.parse(existingRecord.fields.Kinetics__Chat_GPT_Parameters__c.value);
        //this needs to be changed
        this.templatePageMetadata.pagelist = JSON.parse(this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c);//.replaceAll('\\', '')
        console.log('*** TbTemplateBuilderNG>loadRecord=this.templatePageMetadata.pagelist=' + JSON.stringify(this.templatePageMetadata.pagelist));
        this.updateLastModifiedMetadata();

        // if there are any questions added, ChatGPT will be disabled.
        if (this.templatePageMetadata.pagelist) {
            this.disableChatGPT = true;
        }
        this.getExtraDetailsInfo();
    }

    loadLogic() {
        console.log('loadLogic...');
    }

    resetToDefaults() {
        this.templatePageMetadata.selectedFormValue = {
            'Name': '',
            'Kinetics__Instructions__c': '',
            'Kinetics__Status__c': 'Active',
            'Kinetics__Questions_By_Page_No__c': '{}',
            'Kinetics__Section_Metadata__c': '{}',
            'Kinetics__Template_Metadata__c': '{}'
        };
        if(this.extraDetailFields){
            for (let i = 0; i < this.extraDetailFields.length; i++) {
                this.templatePageMetadata.selectedFormValue[this.extraDetailFields[i].fieldPath] = '';
            }
        }
        this.templatePageMetadata.pagelist = [];
        this.templatePageMetadata.pagelist.push(this.getDefaultPage());
        this.addQuestionToListHelper(0, 0);
    }

    cloneTemplate(event) {
        this.recordId = undefined;
        var templatePageMetadata = JSON.parse(JSON.stringify(this.templatePageMetadata));
        //if any other changes are required then we can do those here....
        templatePageMetadata.selectedFormValue.Name = templatePageMetadata.selectedFormValue.Name + ' - Clone';
        this.templatePageMetadata = templatePageMetadata;
        this.showSuccessNotification('Template has been cloned successfully, please save it to create separate instance.');
    }
    handleInputFieldChange(event) {
        this.templatePageMetadata.selectedFormValue[event.target.dataset.name] = event.target.value;
        this.updateLastModifiedMetadata();
    }

    maintainGPTParameterValues(event) {
        var gptParameter = event.detail.gptParameter;
        this.templatePageMetadata.selectedFormValue.Kinetics__Chat_GPT_Parameters__c = gptParameter;
    }

    addQuestionInList(event) {
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;
        this.addQuestionToListHelper(pageno, sectionno);
    }
    addSectionInList(event) {
        var pageno = event.target.dataset.pageno;

        var sectionno = this.templatePageMetadata.pagelist[pageno].sectionlist.length;// + 1;
        this.templatePageMetadata.pagelist[pageno].sectionlist.push(this.getDefaultSection(sectionno));
        this.updateLastModifiedMetadata();
    }

    addQuestionToListHelper(pageno, sectionno) {
        var alreadyQuestions = 0;
        sectionno = parseInt(sectionno);// - 1;
        pageno = parseInt(pageno);// - 1;
        var newQuestion = {
            'uid': pageno + '.' + sectionno + '.' + alreadyQuestions,
            'Name': '',
            'Kinetics__Field_Type__c': 'Text',
            'Kinetics__Assign_Tasks__c': false,
            'Kinetics__Attach_Photos_or_Files__c': false,
            'Kinetics__Capture_Notes__c': false,
            'Kinetics__Required__c': false,
            'Kinetics__Values__c': [],
            'displayQuestionNo': pageno + '.' + alreadyQuestions,
            'pageno': pageno,
            'sectionno': sectionno,
            'isdragover': false
        };

        this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList.push(newQuestion);
        this.adjustQuestionSequenceForPage(pageno);
    }
    addPageInList(event) {
        this.templatePageMetadata.pagelist.push(this.getDefaultPage());
        this.updateLastModifiedMetadata();
    }
    getDefaultPage() {
        var pageno = (this.templatePageMetadata.pagelist.length);// + 1);
        var pageWrapper = {
            'pageno': pageno,
            'displayno': pageno + 1,
            'sectionlist': []
        };
        pageWrapper.sectionlist.push(this.getDefaultSection(0))
        return pageWrapper;
    }

    getDefaultSection(sectionno) {
        return {
            'sectionno': sectionno,
            'stitle': '',
            'sinstructions': '',
            'displayno': sectionno,
            'questionWrapperList': []
        };
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
    showSuccessNotification(message) {
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
                "message": message || 'Template has been created successfully.'
            });
            this.dispatchEvent(event);
        });
    }
    isvalidvalue(value) {
        return (value != null && value != undefined && value != '');
    }
    getTotalNumberOfQuestions() {
        var numberOfQuestions = 0;
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    if (this.isvalidvalue(this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k].Name)) {
                        numberOfQuestions = numberOfQuestions + 1;
                    }
                }
            }
        }
        return numberOfQuestions;
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
    recordCreaterHelper() {
        if (this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }

    getRecordToSave() {
        const fields = this.templatePageMetadata.selectedFormValue;
        //need to replace the below field to change to question JSON wrapper field
        fields['Kinetics__Template_Metadata__c'] = JSON.stringify(this.templatePageMetadata.pagelist);
        fields['Kinetics__Chat_GPT_Parameters__c'] = JSON.stringify(this.templatePageMetadata.selectedFormValue.Kinetics__Chat_GPT_Parameters__c);
        fields['Kinetics__Number_Of_Questions_From_JSON__c'] = this.getTotalNumberOfQuestions();
        if (this.recordId !== undefined) {
            fields['Id'] = this.recordId;
        }

        const recordInput = { apiName: this.objectapiname, fields };

        return recordInput;
    }

    handleSaveOperation() {
        if (this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }

    saveTemplate(event) {
        var recordToSave = {};
        recordToSave['template'] = this.templatePageMetadata.selectedFormValue;
        recordToSave['pageList'] = this.templatePageMetadata.pagelist;

        if (recordToSave['template'].Name == undefined || recordToSave['template'].Name == '') {
            this.showErrorMessage('Please provide Template Name');
            return '';
        }

        if (recordToSave['pageList'].length == 1
            && recordToSave['pageList'][0].sectionlist.length == 1
            && recordToSave['pageList'][0].sectionlist[0].questionWrapperList.length == 1
            && (recordToSave['pageList'][0].sectionlist[0].questionWrapperList[0].Name == undefined
                || recordToSave['pageList'][0].sectionlist[0].questionWrapperList[0].Name == '')) {
            this.showErrorMessage('Please add atleast one question to Template');
            return '';
        }
        this.isLoading = true;
        this.handleSaveOperation().
            then(surveyRec => {
                this.recordId = surveyRec.id;

                this.showSuccessNotification();
                this.navigateToRecordPage();
                this.isLoading = false;
            })
            .catch(error => {
                this.handleErrorBlock(error);
            }
            );
    }

    handleSectionInputFieldChange(event) {
        var pageno = event.target.dataset.pageno;//- 1;
        var sectionno = event.target.dataset.sectionno;// - 1;
        var value = event.target.value;

        this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].stitle = value;
        this.updateLastModifiedMetadata();
    }
    //c/inspQuestionCurrencypageListObj = {};
    handleQuestionUpdate(event) {
        console.log('TbTemplateBuilderNG>>handleQuestionUpdate');
        var question = event.detail.question;
        var uid = question.uid
        var pageno = question.pageno;
        var sectionno = question.sectionno;

        for (var i = 0; i < this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList.length; i++) {
            if (this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i].uid == uid) {
                this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i] = question;
            }
        }

        if (event.detail.isFocusChange != undefined
            && event.detail.isFocusChange == true) {
            for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
                for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                    for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k]['gotfocus'] = false;
                        if (i == pageno && j == sectionno && uid == this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k].uid) {
                            this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k]['gotfocus'] = true;
                        }
                    }
                }
            }
        }

        // this.pageListObj = { 'value': this.templatePageMetadata.pagelist };
        this.updateLastModifiedMetadata();
    }

    handleQuestionUp(event) {
        var uidSelected = event.target.dataset.uid;
        var pagenoSelected = event.target.dataset.pageno;
        var sectionnoSelected = event.target.dataset.sectionno;

        const uidArray = uidSelected.split(".");
        var indexSelected = uidArray[2] - 1;
        var changeWithIndex = indexSelected - 1;

        this.swapQuestions(pagenoSelected, sectionnoSelected, indexSelected, changeWithIndex);
        const moveEvent = new ShowToastEvent({
            "title": 'Success',
            "variant": 'success',
            "message": 'The selected question has been moved up.'
        });
        this.dispatchEvent(moveEvent);
    }

    swapQuestions(pageNo, sectionNo, selectedIndex, swappedIndex) {
        if (this.templatePageMetadata.pagelist[pageNo].sectionlist[sectionNo].questionWrapperList[swappedIndex]) {
            const temp = this.templatePageMetadata.pagelist[pageNo].sectionlist[sectionNo].questionWrapperList[swappedIndex];
            this.templatePageMetadata.pagelist[pageNo].sectionlist[sectionNo].questionWrapperList[swappedIndex] = this.templatePageMetadata.pagelist[pageNo].sectionlist[sectionNo].questionWrapperList[selectedIndex];
            this.templatePageMetadata.pagelist[pageNo].sectionlist[sectionNo].questionWrapperList[selectedIndex] = temp;
            this.adjustWholePageNumbers();
        }

    }

    handleQuestionDown(event) {
        var uidSelected = event.target.dataset.uid;
        var pagenoSelected = event.target.dataset.pageno;
        var sectionnoSelected = event.target.dataset.sectionno;

        const uidArray = uidSelected.split(".");
        var indexSelected = uidArray[2] - 1;
        var changeWithIndex = indexSelected + 1;

        this.swapQuestions(pagenoSelected, sectionnoSelected, indexSelected, changeWithIndex);
        const moveEvent = new ShowToastEvent({
            "title": 'Success',
            "variant": 'success',
            "message": 'The selected question has been moved down.'
        });
        this.dispatchEvent(moveEvent);
    }

    handleQuestionClone(event) {
        var uidSelected = event.target.dataset.uid;
        var pagenoSelected = event.target.dataset.pageno;
        var sectionnoSelected = event.target.dataset.sectionno;

        const uidArray = uidSelected.split(".");
        var indexSelected = uidArray[2] - 1;

        var newClonedQuestion = JSON.parse(JSON.stringify(this.templatePageMetadata.pagelist[pagenoSelected].sectionlist[sectionnoSelected].questionWrapperList[indexSelected]));
        newClonedQuestion['gotfocus'] = false;
        // const temp = this.templatePageMetadata.pagelist[pagenoSelected].sectionlist[sectionnoSelected].questionWrapperList[indexSelected];
        this.templatePageMetadata.pagelist[pagenoSelected].sectionlist[sectionnoSelected].questionWrapperList.splice(indexSelected + 1, 0, newClonedQuestion);
        this.adjustWholePageNumbers();
    }

    deleteQuestion(event) {
        var uid = event.target.dataset.uid;
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;

        var indexToDelete = -1;
        for (var i = 0; i < this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList.length; i++) {
            if (uid == this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i].uid) {
                indexToDelete = i;
                break;
            }
        }
        if (indexToDelete != -1) {
            this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList.splice(indexToDelete, 1);
        }
        this.adjustQuestionSequenceForPage(pageno);
    }
    deleteSection(event) {
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;

        var indexToDelete = -1;
        for (var i = 0; i < this.templatePageMetadata.pagelist[pageno].sectionlist.length; i++) {
            if (sectionno == this.templatePageMetadata.pagelist[pageno].sectionlist[i].sectionno) {
                indexToDelete = i;
                break;
            }
        }
        if (indexToDelete != -1) {
            this.templatePageMetadata.pagelist[pageno].sectionlist.splice(indexToDelete, 1);
        }
        this.adjustQuestionSequenceForPage(pageno);
    }
    deletePage(event) {
        var pageno = event.target.dataset.pageno;
        var indexToDelete = -1;
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            if (pageno == this.templatePageMetadata.pagelist[i].pageno) {
                indexToDelete = i;
                break;
            }
        }
        if (indexToDelete != -1) {
            this.templatePageMetadata.pagelist.splice(indexToDelete, 1);
        }
        this.adjustWholePageNumbers();
    }
    adjustWholePageNumbers() {
        //adjust the question nos
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            this.templatePageMetadata.pagelist[i].pageno = i;
            this.templatePageMetadata.pagelist[i].displayno = i + 1;
            this.adjustQuestionSequenceForPage(i);
        }
        this.updateLastModifiedMetadata();
    }

    adjustQuestionSequenceForPage(pageno) {
        pageno = parseInt(pageno);
        var alreadyAddedQuestions = 0;
        for (var i = 0; i < this.templatePageMetadata.pagelist[pageno].sectionlist.length; i++) {
            this.templatePageMetadata.pagelist[pageno].sectionlist[i].sectionno = i;
            this.templatePageMetadata.pagelist[pageno].sectionlist[i].displayno = i + 1;
            for (var j = 0; j < this.templatePageMetadata.pagelist[pageno].sectionlist[i].questionWrapperList.length; j++) {
                alreadyAddedQuestions = alreadyAddedQuestions + 1;
                this.templatePageMetadata.pagelist[pageno].sectionlist[i].questionWrapperList[j]['uid'] = pageno + '.' + i + '.' + alreadyAddedQuestions;
                this.templatePageMetadata.pagelist[pageno].sectionlist[i].questionWrapperList[j]['displayQuestionNo'] = (pageno + 1) + '.' + alreadyAddedQuestions;
                this.templatePageMetadata.pagelist[pageno].sectionlist[i].questionWrapperList[j]['pageno'] = pageno;
                this.templatePageMetadata.pagelist[pageno].sectionlist[i].questionWrapperList[j]['sectionno'] = i;
            }
        }
        this.updateLastModifiedMetadata();
    }

    showPreviewer = false;
    questionContainerGrid = 'slds-col slds-size_1-of-1 slds-large-size_12-of-12';
    previewerContainerGrid = '';
    handlePreview() {
        this.showPreviewer = !this.showPreviewer;

        if (this.showPreviewer) {
            this.questionContainerGrid = 'slds-col slds-size_1-of-1 slds-large-size_8-of-12';
            this.previewerContainerGrid = 'slds-col slds-size_1-of-1 slds-large-size_4-of-12 previewerContainer';
        } else {
            this.questionContainerGrid = 'slds-col slds-size_1-of-1 slds-large-size_12-of-12';
            this.previewerContainerGrid = '';
        }
    }

    showGPTBuilder = false;
    handleShowGPTBuilder() {
        this.showGPTBuilder = !this.showGPTBuilder;
    }

    onQuestionDragStart(event) {
        var uid = event.target.dataset.uid;
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;

        event.target.classList.add('drag');
        event.target.classList.add('slds-is-selected');

        //this.template.querySelector(`.questionRow[data-customuid="${uid}"]`)?.classList.add('drag');
        //this.template.querySelector(`.questionRow[data-customuid="${uid}"]`)?.classList.add('slds-is-selected');

        event.dataTransfer.setData("draggedElementType", "questionRow");
        event.dataTransfer.setData("draggedQuestionUID", uid);
        event.dataTransfer.setData("draggedQuestionPageNo", parseInt(pageno));
        event.dataTransfer.setData("draggedQuestionSectionNo", parseInt(sectionno));
    }

    onQuestionDragOver(event) {
        event.preventDefault();
        // var uid = event.target.dataset.uid;
        // var pageno = event.target.dataset.pageno;
        // var sectionno = event.target.dataset.sectionno;
        // this.updateIsDragOver(uid, pageno, sectionno);
    }

    onQuestionDragEnter(event) {
        event.preventDefault();
        var uid = event.target.dataset.uid;
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;
        this.updateIsDragOver(uid, pageno, sectionno);
    }

    onQuestionDragLeave(event) {
        event.preventDefault();
        var uid = event.target.dataset.uid;
        var pageno = event.target.dataset.pageno;
        var sectionno = event.target.dataset.sectionno;
        this.updateIsDragOver(undefined, pageno, sectionno);
    }

    updateIsDragOver(uid, pageno, sectionno) {
        for (var i = 0; i < this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList.length; i++) {
            this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i].isdragover = false;
            if (uid == this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i].uid) {
                this.templatePageMetadata.pagelist[pageno].sectionlist[sectionno].questionWrapperList[i].isdragover = true;
            }
        }
    }

    removeDragCSSClasses(event) {
        const questionList = this.template.querySelectorAll('.questionRow');
        questionList.forEach(element => {
            element.classList.remove('drag');
            element.classList.remove('slds-is-selected');
        });

        event.target.classList.remove('slds-drop-zone');
        event.target.classList.remove('slds-drop-zone_drag');
    }


    onQuestionDrop(event) {
        event.stopPropagation();

        var elementType = event.dataTransfer.getData("draggedElementType");

        var draggedQuestionUID = event.dataTransfer.getData("draggedQuestionUID");
        var draggedQuestionPageNo = event.dataTransfer.getData("draggedQuestionPageNo");
        var draggedQuestionSectionNo = event.dataTransfer.getData("draggedQuestionSectionNo");

        var droppedQuestionUID = event.target.dataset.uid;
        var droppedPageNo = event.target.dataset.pageno;
        var droppedSectionNo = event.target.dataset.sectionno;

        this.updateIsDragOver(undefined, droppedPageNo, droppedSectionNo);

        if (elementType !== "questionRow") {
            this.removeDragCSSClasses(event);
            return false;
        }

        if (draggedQuestionUID === droppedQuestionUID
            && draggedQuestionPageNo === droppedPageNo
            && draggedQuestionSectionNo === droppedSectionNo) {
            this.removeDragCSSClasses(event);
            return false;
        }
        event.target.classList.add('slds-drop-zone');
        event.target.classList.add('slds-drop-zone_drag');

        var indexToRemove = -1;
        var draggedQuestionRecord = {};
        for (var i = 0; i < this.templatePageMetadata.pagelist[draggedQuestionPageNo].sectionlist[draggedQuestionSectionNo].questionWrapperList.length; i++) {
            if (this.templatePageMetadata.pagelist[draggedQuestionPageNo].sectionlist[draggedQuestionSectionNo].questionWrapperList[i].uid == draggedQuestionUID) {
                indexToRemove = i;
                draggedQuestionRecord = JSON.parse(JSON.stringify(this.templatePageMetadata.pagelist[draggedQuestionPageNo].sectionlist[draggedQuestionSectionNo].questionWrapperList[i]));
                break;
            }
        }
        this.templatePageMetadata.pagelist[draggedQuestionPageNo].sectionlist[draggedQuestionSectionNo].questionWrapperList.splice(indexToRemove, 1);

        var indexToAddAfter = -1;
        for (var i = 0; i < this.templatePageMetadata.pagelist[droppedPageNo].sectionlist[droppedSectionNo].questionWrapperList.length; i++) {
            if (this.templatePageMetadata.pagelist[droppedPageNo].sectionlist[droppedSectionNo].questionWrapperList[i].uid == droppedQuestionUID) {
                indexToAddAfter = i;
                break;
            }
        }
        indexToAddAfter = indexToAddAfter + 1;
        this.templatePageMetadata.pagelist[droppedPageNo].sectionlist[droppedSectionNo].questionWrapperList.splice(indexToAddAfter, 0, draggedQuestionRecord);

        this.removeDragCSSClasses(event);
        this.adjustWholePageNumbers();
    }
    handleTemplateGenerated(event) {
        this.templatePageMetadata.selectedFormValue = JSON.parse(JSON.stringify(event.detail.template));
        this.templatePageMetadata.pagelist = [];
        this.templatePageMetadata.pagelist = JSON.parse(JSON.stringify(event.detail.pagelist));
        this.adjustWholePageNumbers();
    }


}