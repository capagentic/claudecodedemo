import { LightningElement, api, track } from 'lwc';

export default class TbTemplateQuestionRendererNG extends LightningElement {
    //@track pageMetadata = [];
    showError = false;
    showSpinner = false;
    // templatePageMetadataLocal = {};
    @track isMetadataLoaded = false;
    @api readOnly = false;;
    @api templateName;
    @api existingAnswersByUniqueId;
    noteCountByAnswerId;
    taskCountByAnswerId;
    fileCountByAnswerId;
    currentAnswers = {};
    files = {};

    @track page = {};
    currentpagenumber = 1;
    totalpagenumbers = 1;
    currentpageprogress = 0;

    nextpageavailable = false;
    prepageavailabel = false;


    _inspectionRec;
    @api
    get inspectionRec() {
        return this._inspectionRec;
    }
    set inspectionRec(value) {
        this._inspectionRec = value;
        if (this._inspectionRec && this._inspectionRec.Kinetics__Status__c == 'Complete') {
            this.readOnly = true;
        }
    }
    connectedCallback() {
    }

    _templatePageMetadata
    @api set templatePageMetadata(value) {
        this._templatePageMetadata = value;
        this.existingAnswersByUniqueId = value.existingAnswersByUniqueId;
        this.noteCountByAnswerId = value.noteCountByAnswerId;
        this.taskCountByAnswerId = value.taskCountByAnswerId;
        this.fileCountByAnswerId = value.fileCountByAnswerId;
        this.currentAnswers = value.answers;
        this.files = value.files;
        this.refreshPageMetadata(value.pagelist);
    }
    get templatePageMetadata() {
        return this._templatePageMetadata;
    }

    _scoredetails
    @api set scoredetails(value) {
        this._scoredetails = value || {};
    }
    get scoredetails() {
        return this._scoredetails;
    }
    get totalOutofScore() {
        return this.scoredetails?.totalOutofScore || 0;
    }

    get totalObtainedScore() {
        return this.scoredetails?.totalObtainedScore || 0;
    }

    get scorePercentage() {
        var percentageScore = ((this.totalObtainedScore / this.totalOutofScore) * 100) || 0;
        percentageScore = parseFloat(percentageScore).toFixed(0);
        return percentageScore;
    }

    handlePrevClick(event) {
        this.currentpagenumber = this.currentpagenumber >= 1 ? this.currentpagenumber - 1 : this.currentpagenumber;
        this.adjustpagination();
    }
    handleNextClick(event) {
        this.currentpagenumber = this.currentpagenumber <= this.totalpagenumbers ? this.currentpagenumber + 1 : this.currentpagenumber;
        this.adjustpagination();
    }
    adjustpagination() {
        this.prepageavailabel = (this.currentpagenumber > 1);
        this.nextpageavailable = (this.currentpagenumber < this.totalpagenumbers);
        this.currentpageprogress = (this.currentpagenumber * 100) / this.totalpagenumbers;
        var pagemetadatalocal = this._templatePageMetadata.pagelist;
        if (pagemetadatalocal.length > 0) {
            this.page = (this.currentpagenumber <= pagemetadatalocal.length) ? pagemetadatalocal[this.currentpagenumber - 1] : pagemetadatalocal[0];
        }
    }
    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }
    isValidValue(value) {
        return (value != undefined && value != '')
    }
    refreshPageMetadata(pageMetadata) {
        this.init(pageMetadata);
    }

    init(pageMetadata) {
        if (!this.isValidValue(pageMetadata)) {
            return 0;
        }
        var questionWrapperList = [];
        var pagemetadatalocal = this.cloneValue(pageMetadata);
        var qindex = 1;
        for (var i = 0; i < pagemetadatalocal.length; i++) {
            for (var j = 0; j < pagemetadatalocal[i].sectionlist.length; j++) {
                questionWrapperList = [];
                for (var k = 0; k < pagemetadatalocal[i].sectionlist[j].questionWrapperList.length; k++) {
                    var qwrapper = {};
                    var questionObj = pagemetadatalocal[i].sectionlist[j].questionWrapperList[k];
                    qwrapper.index = qindex;
                    qwrapper.helpText = questionObj.Kinetics__Question_Help_Text__c;
                    qwrapper.fieldType = questionObj.Kinetics__Field_Type__c;
                    qwrapper.questionDetails = questionObj.Name;
                    qwrapper.questionId = questionObj.uid;
                    qwrapper.templateQuestionId = questionObj.uid;
                    qwrapper.questionValues = questionObj.Kinetics__Values__c;
                    qwrapper.displayIndex = questionObj.displayQuestionNo;
                    qwrapper.scoreByOption = questionObj.Kinetics__Option_Score__c;
                    qwrapper.scoreConfirmed = false;
                    qwrapper.assignTaskEnabled = questionObj.Kinetics__Assign_Tasks__c;
                    qwrapper.attachPhotoEnabled = (questionObj.Kinetics__Attach_Photos_or_Files__c && qwrapper.fieldType !== 'File');
                    qwrapper.captureNotesEnabled = questionObj.Kinetics__Capture_Notes__c;
                    qwrapper.defaultValue = questionObj.Kinetics__Default_Value__c;
                    qwrapper.markAnswerReadOnly = questionObj.Kinetics__Show_Related_Info_In_Answer_As_ReadOly__c;
                    qwrapper.answerrequired = questionObj.Kinetics__Required__c;
                    qwrapper.relatedObjectName = questionObj.Kinetics__Related_To_Object__c;
                    qwrapper.relatedObjectFieldName = questionObj.Kinetics__Related_Field_API_Name__c;
                    qwrapper.showRelatedInfoInQuestionText = questionObj.Kinetics__Show_Related_Info_In_Question_Text__c;
                    qwrapper.showRelatedInfoAsaAnswer = questionObj.Kinetics__Show_Related_Info_As_a_Answer__c;
                    qwrapper.chatgptguidance = questionObj.Kinetics__AI_Guidance__c;
                    qwrapper.qInstructions = questionObj.qInstructions;
                    qwrapper.flowName = questionObj.flowName;
                    qwrapper.dependantQuestions = questionObj.dependantQuestions || {};
                    qwrapper.flows = questionObj.flows || [];
                    qwrapper.showDependantQuestion = questionObj.showDependantQuestion || false;
                    qwrapper.currentDependantQuestion = questionObj.currentDependantQuestion || {};

                    qwrapper.answer = questionObj.answer || '';
                    if (this.currentAnswers != undefined
                        && this.currentAnswers.hasOwnProperty(questionObj.uid)) {
                        qwrapper.answer = this.currentAnswers[questionObj.uid].answer;

                        if (qwrapper.dependantQuestions.hasOwnProperty(qwrapper.answer)) {
                            qwrapper.currentDependantQuestion = this.createDepedantQuestionWrapper(questionObj.uid, qwrapper.dependantQuestions[qwrapper.answer]);
                            qwrapper.showDependantQuestion = true;
                        }

                    }
                    if (this.existingAnswersByUniqueId != undefined
                        && this.existingAnswersByUniqueId != null
                        && this.existingAnswersByUniqueId.hasOwnProperty(questionObj.uid)) {
                        qwrapper.existingAnswerId = this.existingAnswersByUniqueId[questionObj.uid].Id;
                        if (qwrapper.answer == null || qwrapper.answer == undefined || qwrapper.answer == '') {
                            qwrapper.answer = this.existingAnswersByUniqueId[questionObj.uid].Kinetics__Answer__c;
                        }
                        qwrapper.totalNumberOfTasksCreated = (this.taskCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.taskCountByAnswerId[qwrapper.existingAnswerId] : 0);
                        qwrapper.totalNumberOfNotesCreated = (this.noteCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.noteCountByAnswerId[qwrapper.existingAnswerId] : 0);
                        qwrapper.totalNumberOfFilesUploaded = (this.fileCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.fileCountByAnswerId[qwrapper.existingAnswerId] : 0);
                    }
                    qwrapper.totalNumberOfTasksCreated = questionObj.totalNumberOfTasksCreated || qwrapper.totalNumberOfTasksCreated || 0;
                    qwrapper.totalNumberOfNotesCreated = questionObj.totalNumberOfNotesCreated || qwrapper.totalNumberOfNotesCreated || 0;
                    qwrapper.totalNumberOfFilesUploaded = questionObj.totalNumberOfFilesUploaded || qwrapper.totalNumberOfFilesUploaded || 0;


                    if (questionObj.dependantQuestions) {
                        questionObj.showDependantQuestion = false;
                        for (var ans in questionObj.dependantQuestions) {

                            if (questionObj.answer == ans) {
                                questionObj.showDependantQuestion = true;
                                questionObj.currentDependantQuestion = this.createDepedantQuestionWrapper(questionObj.index, questionObj.dependantQuestions[ans]);
                                // question.showDependantQuestion = { 'value': true };
                            }
                        }
                    }

                    questionWrapperList.push(qwrapper);
                    qindex = qindex + 1;
                }
                pagemetadatalocal[i].sectionlist[j].questionWrapperList = questionWrapperList;
            }
        }
        this.totalpagenumbers = pagemetadatalocal.length;

        // return pagemetadatalocal;
        //  this.pageMetadata = pagemetadatalocal;
        var templateAndPageMetadata = this.cloneValue(this._templatePageMetadata);
        //templateAndPageMetadata['selectedFormValue'] = this._templatePageMetadata.selectedFormValue;
        templateAndPageMetadata['pagelist'] = pagemetadatalocal;
        //templateAndPageMetadata['existingAnswersByUniqueId'] = this.existingAnswersByUniqueId;
        //  this.templatePageMetadataLocal = templateAndPageMetadata;
        this._templatePageMetadata = templateAndPageMetadata;
        this.adjustpagination();
        this.isMetadataLoaded = true;
    }

    updateQuestion(question, questionUId) {
        var pageMetadata = this._templatePageMetadata;
        if (!this.isValidValue(pageMetadata)) {
            return 0;
        }
        var pagemetadatalocal = this.cloneValue(pageMetadata.pagelist);
        for (var i = 0; i < pagemetadatalocal.length; i++) {
            for (var j = 0; j < pagemetadatalocal[i].sectionlist.length; j++) {
                for (var k = 0; k < pagemetadatalocal[i].sectionlist[j].questionWrapperList.length; k++) {
                    var questionObj = pagemetadatalocal[i].sectionlist[j].questionWrapperList[k];
                    if (questionUId == questionObj.questionId) {
                        questionObj = question;
                    }
                    pagemetadatalocal[i].sectionlist[j].questionWrapperList[k] = questionObj;
                }
            }
        }

        var templateAndPageMetadata = this.cloneValue(this._templatePageMetadata);
        templateAndPageMetadata['pagelist'] = pagemetadatalocal;
        this._templatePageMetadata = templateAndPageMetadata;
        this.isMetadataLoaded = true;
    }

    handleValueChanged(event) {
        console.log('****** handleValueChanged');
        var question = this.cloneValue(event.detail.question);

        if (question.dependantQuestions) {
            question.showDependantQuestion = false;
            for (var ans in question.dependantQuestions) {

                if (question.answer == ans) {
                    question.showDependantQuestion = true;
                    question.currentDependantQuestion = this.createDepedantQuestionWrapper(question.index, question.dependantQuestions[ans]);
                    // question.showDependantQuestion = { 'value': true };
                }
            }
        }

        this.updateQuestion(question, question.questionId);
        const questionAnswer = event.detail.answer;
        const valueChangeEvent = new CustomEvent('questionupdate', {
            detail: { index: question.index, questionAnswer: questionAnswer, question: question }
        });
        this.dispatchEvent(valueChangeEvent);


    }
    maintainVisitNotesRecords(event) {

        console.log('TbTemplateQuestionRendererNG>maintainVisitNotesRecords...');
        var question = event.detail.question;
        var noteId = event.detail.noteId;
        const valueChangeEvent = new CustomEvent('noterecordcreate', {
            detail: { noteId: noteId, question: question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    maintainTaskRecords(event) {

        var question = event.detail.question;
        var taskId = event.detail.taskId;
        var taskRecord = event.detail.taskRec;
        const valueChangeEvent = new CustomEvent('taskrecordcreate', {
            detail: { taskId: taskId, taskRecord: taskRecord, question: question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    maintainFileUpload(event) {
        var uploadedfile = event.detail.file;
        var question = event.detail.question;

        const valueChangeEvent = new CustomEvent('fileupload', {
            detail: { uploadedfile: uploadedfile, question: question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleCancel(event) {
        const valueChangeEvent = new CustomEvent('cancel', {
            detail: { event: event }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    handleSave(event) {
        const valueChangeEvent = new CustomEvent('save', {
            detail: { event: event }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    createDepedantQuestionWrapper(parentQuestionIndex, dQuestion) {
        var qwrapper = {};
        var questionObj = dQuestion.question;
        qwrapper.name = questionObj.Name;
        qwrapper.index = parentQuestionIndex + '.' + 1;
        qwrapper.helpText = questionObj.Kinetics__Question_Help_Text__c;
        qwrapper.fieldType = questionObj.Kinetics__Field_Type__c;
        qwrapper.questionDetails = questionObj.Name;
        qwrapper.questionId = questionObj.uid;
        qwrapper.templateQuestionId = questionObj.uid;
        qwrapper.questionValues = questionObj.Kinetics__Values__c;
        qwrapper.displayIndex = questionObj.displayQuestionNo;
        qwrapper.scoreByOption = questionObj.Kinetics__Option_Score__c;
        qwrapper.scoreConfirmed = false;
        qwrapper.assignTaskEnabled = questionObj.Kinetics__Assign_Tasks__c;
        qwrapper.attachPhotoEnabled = (questionObj.Kinetics__Attach_Photos_or_Files__c && qwrapper.fieldType !== 'File');
        qwrapper.captureNotesEnabled = questionObj.Kinetics__Capture_Notes__c;
        qwrapper.defaultValue = questionObj.Kinetics__Default_Value__c;
        qwrapper.markAnswerReadOnly = questionObj.Kinetics__Show_Related_Info_In_Answer_As_ReadOly__c;
        qwrapper.answerrequired = questionObj.Kinetics__Required__c;
        qwrapper.relatedObjectName = questionObj.Kinetics__Related_To_Object__c;
        qwrapper.relatedObjectFieldName = questionObj.Kinetics__Related_Field_API_Name__c;
        qwrapper.showRelatedInfoInQuestionText = questionObj.Kinetics__Show_Related_Info_In_Question_Text__c;
        qwrapper.showRelatedInfoAsaAnswer = questionObj.Kinetics__Show_Related_Info_As_a_Answer__c;
        qwrapper.chatgptguidance = questionObj.Kinetics__AI_Guidance__c;
        qwrapper.qInstructions = questionObj.qInstructions;
        qwrapper.flowName = questionObj.flowName;
        qwrapper.dependantQuestions = questionObj.dependantQuestions || {};
        qwrapper.flows = questionObj.flows || [];

        qwrapper.answer = questionObj.answer || '';
        if (this.currentAnswers != undefined
            && this.currentAnswers.hasOwnProperty(questionObj.uid)) {
            qwrapper.answer = this.currentAnswers[questionObj.uid].answer;
        }
        if (this.existingAnswersByUniqueId != undefined
            && this.existingAnswersByUniqueId != null
            && this.existingAnswersByUniqueId.hasOwnProperty(questionObj.uid)) {
            qwrapper.existingAnswerId = this.existingAnswersByUniqueId[questionObj.uid].Id;
            if (qwrapper.answer == null || qwrapper.answer == undefined || qwrapper.answer == '') {
                qwrapper.answer = this.existingAnswersByUniqueId[questionObj.uid].Kinetics__Answer__c;
            }
            qwrapper.totalNumberOfTasksCreated = (this.taskCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.taskCountByAnswerId[qwrapper.existingAnswerId] : 0);
            qwrapper.totalNumberOfNotesCreated = (this.noteCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.noteCountByAnswerId[qwrapper.existingAnswerId] : 0);
            qwrapper.totalNumberOfFilesUploaded = (this.fileCountByAnswerId.hasOwnProperty(qwrapper.existingAnswerId) ? this.fileCountByAnswerId[qwrapper.existingAnswerId] : 0);
        }
        qwrapper.totalNumberOfTasksCreated = questionObj.totalNumberOfTasksCreated || qwrapper.totalNumberOfTasksCreated || 0;
        qwrapper.totalNumberOfNotesCreated = questionObj.totalNumberOfNotesCreated || qwrapper.totalNumberOfNotesCreated || 0;
        qwrapper.totalNumberOfFilesUploaded = questionObj.totalNumberOfFilesUploaded || qwrapper.totalNumberOfFilesUploaded || 0;

        return qwrapper;

    }

    handleQuestionOnblur(event) {
        console.log('handleQuestionOnblur> ready for auto save');
        // var question = this.cloneValue(event.detail.question);
        event = {} || event;
        event.type = 'autosave';
        this.handleSave(event);
    }
}