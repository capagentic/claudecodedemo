import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllTemplateDetailsByInspectionId from '@salesforce/apex/InspTemplateRendererController.getAllTemplateDetailsByInspectionId';
import saveAnswers from '@salesforce/apex/InspTemplateRendererController.saveAnswers';
import shareNoteRecord from '@salesforce/apex/InspTemplateRendererController.shareNoteRecord';
import updateTaskRecord from '@salesforce/apex/InspTemplateRendererController.updateTaskRecord';
import saveTheChunkFile from '@salesforce/apex/InspTemplateRendererController.saveTheChunkFile';
import updateInspectionToInprogress from '@salesforce/apex/InspTemplateRendererController.updateInspectionToInprogress';
import { updateRecord } from 'lightning/uiRecordApi';


const MAX_FILE_SIZE = 6500000;
const CHUNK_SIZE = 1000000;
const MAX_SUPPORTED_FILE_SIZE = 1000000;
const imageFilterType = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i;

export default class InspTemplateQuestionRendererLWC extends LightningElement {

    @api inspectionRecordId;
    @api templateRecordId;
    @api inspectionTemplateId;
    @api fetchAllQuestions;
    @api disableSubmission = false;

    @api recordId;

    result;
    errorMessage;
    @track templQuestionList = [];
    answers = {};
    @track files = {};
    visitNotesBySurveyQuestionId = {};
    tasksArrayBySurveyQuestionId = {};
    taskIdsArrayBySurveyQuestionId = {};
    attachmentArrayBySurveyQuestionId = {};
    instruction;
    greeting;
    pageTitle;
    answersDB = [];
    pageTitleClass;// = 'welcomePageTitle';

    // element visibility
    timeoutId;
    @track openState;
    showWelcome = false;
    showComplete = false;
    showError = false;
    showFirstScreen = false;
    showSpinner = false;
    showQuestionProgress = false;
    disableSubmitBtn = false;

    // for file upload
    numOfFilesUploaded = 0;
    numOfFilesToUpload = 0;

    inspectionRec;

    questionsByPages = {};
    retrievedRecordId = false;

    scoreByoptionByQuestion = {};
    totalObtainedScore = 0;
    totalOutofScore = 0;
    maximumScoreByQuestion = {};

    allExistingQuestionAnswers = [];
    allQuestionsAlongWithAnswered = [];
    parentRecordIdByFieldNameByQuestionId = {};
    parentRecordId = '';
    parentObject = '';
    parentRecordName = '';
    showParentRecordDetailPopup = false;

    connectedCallback() {
        this.startAnimation();
        if (this.inspectionRecordId != undefined && this.inspectionRecordId != '') {
            this.retrievedRecordId = true;
            this.init();
        }
    }
    renderedCallback() {

        if (this.inspectionRecordId == undefined || this.inspectionRecordId == '') {
            this.inspectionRecordId = this.recordId;
        }
        if (!this.retrievedRecordId && this.recordId) {
            this.retrievedRecordId = true;
            if (this.inspectionRecordId == undefined || this.inspectionRecordId == '') {
                this.hanldeCatchBlock('Please provide Inspection Id to proceed.');
            } else {
                this.init();
            }
        }
    }
    init() {
        updateInspectionToInprogress({ inspectionId: this.inspectionRecordId }).then(result => {
            getAllTemplateDetailsByInspectionId({ inspectionId: this.inspectionRecordId, fetchAllQuestions: true }).then(result => {
                this.result = result;
                var resObj = JSON.parse(result);
                this.handleStartInspection(resObj);
            }).catch(error => {
                this.hanldeCatchBlock(JSON.stringify(error));
            });
        }).catch(error => {
            this.hanldeCatchBlock(JSON.stringify(error));
        });
    }

    handleStartInspection(resObj) {
        if (resObj.statusCode == '2000') {
            var questionsByPageNo = {};
            var sectionMetadata = {};
            this.inspectionRec = resObj.responseDetails.inspectionRec;
            if (this.inspectionRec != undefined && this.inspectionRec.Kinetics__Template__r != undefined) {
                this.templateName = this.inspectionRec.Kinetics__Template__r.Name;
                this.instruction = this.inspectionRec.Kinetics__Template__r.Kinetics__Instructions__c;
                if (this.inspectionRec.Kinetics__Template__r.Kinetics__Questions_By_Page_No__c != undefined) {
                    questionsByPageNo = JSON.parse(this.inspectionRec.Kinetics__Template__r.Kinetics__Questions_By_Page_No__c);
                }
                if (this.inspectionRec.Kinetics__Template__r.Kinetics__Section_Metadata__c != undefined) {
                    sectionMetadata = JSON.parse(this.inspectionRec.Kinetics__Template__r.Kinetics__Section_Metadata__c);
                }
            }
            this.parentRecordIdByFieldNameByQuestionId = resObj.responseDetails.parentRecordIdByFieldNameByQuestionId;

            this.allExistingQuestionAnswers = [];
            this.allQuestionsAlongWithAnswered = [];
            if ((this.fetchAllQuestions == false || this.fetchAllQuestions === 'false')) {
                this.allQuestionsAlongWithAnswered = JSON.parse(JSON.stringify(resObj.responseDetails.tempQuestionList));
                resObj.responseDetails.tempQuestionList = this.getUnAnsweredQuestions(resObj.responseDetails.tempQuestionList);
                this.maintainAnswersForExistingAnswers(this.allQuestionsAlongWithAnswered);
            }

            resObj.responseDetails.tempQuestionList = this.updateSectionDetails(resObj.responseDetails.tempQuestionList, sectionMetadata);
            this.createQuestionPages(resObj.responseDetails.tempQuestionList, questionsByPageNo);

            if (this.allQuestionsAlongWithAnswered.length > 0) {
                this.maintainScore(this.allQuestionsAlongWithAnswered);
            } else {
                this.maintainScore(resObj.responseDetails.tempQuestionList);
            }
            this.updateWithDefaultAnswers(resObj.responseDetails.tempQuestionList);

            var currentPageNumber = 1;
            this.manageQuestionsToDisplay(currentPageNumber);

            this.pageTitle = this.templateName;
            var totalPages = Object.keys(this.questionsByPages).length;
            this.updateValuesAtParent(this.pageTitle, currentPageNumber, totalPages);
            this.pageTitleClass = 'slds-text-heading_medium slds-p-around_medium';
            this.showFirstScreen = false;
            this.showWelcome = false;

            this.showComplete = !(resObj.responseDetails.tempQuestionList != undefined && resObj.responseDetails.tempQuestionList.length != 0);
            this.updateOpenState();
        } else if (resObj.statusCode == '2100') {
            this.hanldeCatchBlock(resObj.responseMessage);
        }
    }

    getUnAnsweredQuestions(templateQuestionList) {
        var templateQuestionListLocal = [];
        for (var i = 0; i < templateQuestionList.length; i++) {
            if ((this.fetchAllQuestions == false || this.fetchAllQuestions === 'false')
                && (!(templateQuestionList[i].answer != undefined
                    && templateQuestionList[i].answer != ''))) {
                templateQuestionListLocal.push(templateQuestionList[i]);
            }
        }
        return templateQuestionListLocal;
    }

    // sortArray(selectedValueList, sortingfieldname) {
    //     selectedValueList.sort(function (x, y) {
    //         // true values first
    //         if(parseInt(x[sortingfieldname]) < 0 || parseInt(y[sortingfieldname]) < 0) return 1;
    //         return (parseInt(x[sortingfieldname]) - parseInt(y[sortingfieldname]));
    //     });

    //     return selectedQuestionsList;
    // }
    updateSectionDetails(allTemplateQuestionsList, sectionMetadata) {
        if (sectionMetadata == undefined
            || Object.keys(sectionMetadata).length == 0) {
            return allTemplateQuestionsList;
        }
        var questionWrapperByQuestionIndexMap = {};
        for (var j = 0; j < allTemplateQuestionsList.length; j++) {
            var questionWrapper = allTemplateQuestionsList[j];
            questionWrapperByQuestionIndexMap[questionWrapper.index] = questionWrapper;
        }
        var allTemplateQuestionsListLocal = [];
        var sectionWrapperByQuestionIndex = {};
        for (const [sectionNumber, sectionWrapper] of Object.entries(sectionMetadata)) {
            if (sectionWrapper != null && sectionWrapper != undefined
                && sectionWrapper.title != null && sectionWrapper.title != undefined
                && sectionWrapper.questIndex != null && sectionWrapper.questIndex != undefined && sectionWrapper.questIndex.length > 0) {
                for (var k = 0; k < sectionWrapper.questIndex.length; k++) {
                    sectionWrapper.questIndex.sort(function (a, b) { return a - b; });
                    if (questionWrapperByQuestionIndexMap.hasOwnProperty(sectionWrapper.questIndex[k])) {
                        sectionWrapperByQuestionIndex[sectionWrapper.questIndex[k]] = sectionWrapper;
                        break;
                    }
                }
            }
        }
        for (var i = 0; i < allTemplateQuestionsList.length; i++) {
            var questionWrapper = allTemplateQuestionsList[i];
            questionWrapper['isSectionBreakAdded'] = false;
            questionWrapper['sectionWrapper'] = { 'title': '' };
            if (sectionWrapperByQuestionIndex.hasOwnProperty(questionWrapper.index)) {
                questionWrapper['isSectionBreakAdded'] = true;
                questionWrapper['sectionWrapper'] = sectionWrapperByQuestionIndex[questionWrapper.index];
            }
            allTemplateQuestionsListLocal.push(questionWrapper);
        }
        return allTemplateQuestionsListLocal;
    }
    createQuestionPages(allTemplateQuestionsList, questionsByPageNo) {
        this.questionsByPages = {};
        var questionsList = [];

        if (questionsByPageNo == undefined
            || Object.keys(questionsByPageNo).length == 0
            || allTemplateQuestionsList.length == 0) {
            //backward compatible
            this.questionsByPages[1] = allTemplateQuestionsList;
        }
        var pageNumberLocal = 1;
        for (const [pageNumber, questionsIndexList] of Object.entries(questionsByPageNo)) {
            for (var j = 0; j < questionsIndexList.length; j++) {
                var qIndex = questionsIndexList[j];
                for (var i = 0; i < allTemplateQuestionsList.length; i++) {
                    if (allTemplateQuestionsList[i].index == qIndex) {
                        questionsList.push(allTemplateQuestionsList[i]);
                    }
                }
            }
            if (questionsList.length > 0) {
                this.questionsByPages[pageNumberLocal] = questionsList;
                pageNumberLocal = pageNumberLocal + 1;
            }
            questionsList = [];
        }
    }

    maintainScore(allTemplateQuestionsList) {
        this.scoreByoptionByQuestion = {};
        this.totalOutofScore = 0;
        for (var i = 0; i < allTemplateQuestionsList.length; i++) {
            this.scoreByoptionByQuestion[allTemplateQuestionsList[i].questionId] = {};
            if (allTemplateQuestionsList[i].hasOwnProperty('scoreByOption')
                && allTemplateQuestionsList[i].scoreByOption != '{}') {
                this.scoreByoptionByQuestion[allTemplateQuestionsList[i].questionId] = JSON.parse(allTemplateQuestionsList[i].scoreByOption);
            }
            var maxScore = 0;
            if (this.scoreByoptionByQuestion.hasOwnProperty(allTemplateQuestionsList[i].questionId)
                && this.scoreByoptionByQuestion[allTemplateQuestionsList[i].questionId] != null) {

                Object.entries(this.scoreByoptionByQuestion[allTemplateQuestionsList[i].questionId]).forEach(([optionValue, scoreValue]) => {
                    if (maxScore < scoreValue) {
                        maxScore = scoreValue;
                    }
                });
            }
            this.maximumScoreByQuestion[allTemplateQuestionsList[i].questionId] = maxScore;
            this.totalOutofScore = this.totalOutofScore + maxScore;
        }
        //to update total out of score
        this.calculateScore();
    }

    @api
    handlePagination(currentPageNumber) {
        this.manageQuestionsToDisplay(currentPageNumber);
    }

    @api
    submitTemplate() {
        this.handleSubmit(null);
    }

    updateValuesAtParent(title, currentPageNumber, totalPages) {
        const valueChangeEvent = new CustomEvent("updateValuesAtParent", {
            detail: { title, currentPageNumber, totalPages }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    manageQuestionsToDisplay(currentPageNumber) {
        this.templQuestionList = [];
        if (this.questionsByPages.hasOwnProperty(currentPageNumber)) {
            this.templQuestionList = this.questionsByPages[currentPageNumber];
            this.updateWithDefaultAnswers(this.templQuestionList);
            this.calculateScore();
        }
    }

    handleStartSurvey(event) {
        this.pageTitle = this.templateName;  // update page title;
        this.pageTitleClass = 'slds-text-heading_medium';
        this.startAnimation();
        this.showFirstScreen = false;
        this.showWelcome = false;
    }

    startAnimation() {
        this.openState = 'opening';
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.updateOpenState.bind(this), 200);
    }


    updateOpenState() {
        this.openState = 'open';
        clearTimeout(this.timeoutId);
    }

    maintainAnswersForExistingAnswers(templQuestionList) {
        this.allExistingQuestionAnswers = {};
        for (var i = 0; i < templQuestionList.length; i++) {
            var answerLocal = {};
            var question = templQuestionList[i];
            if (question.answer != undefined && question.answer.length > 0) {
                answerLocal['fieldType'] = question.fieldType;
                answerLocal['answer'] = question.answer;
                answerLocal['index'] = question.index;
                answerLocal['templateQuestionId'] = question.templateQuestionId;
                answerLocal['questionId'] = question.questionId;
                answerLocal['questionDetails'] = question.questionDetails;
                answerLocal['fieldType'] = question.fieldType;
                answerLocal['questionValues'] = question.questionValues;
                answerLocal['inspectionId'] = this.inspectionRecordId;
                answerLocal['inspectionTemplateId'] = this.inspectionTemplateId;
                answerLocal['existingAnswerId'] = question.existingAnswerId;
                this.allExistingQuestionAnswers[answerLocal.templateQuestionId] = answerLocal;
            }
        }
    }

    updateWithDefaultAnswers(templQuestionList) {
        for (var i = 0; i < templQuestionList.length; i++) {
            if (templQuestionList[i].answer != undefined && templQuestionList[i].answer.length > 0) {
                var questionAnswer = templQuestionList[i].answer;
                if (templQuestionList[i].fieldType == 'File') {
                    questionAnswer = {};
                    questionAnswer['name'] = templQuestionList[i].answer;
                }
                var question = templQuestionList[i];

                var answer = this.getAnswerWrapper(question, questionAnswer);
                this.answers[templQuestionList[i].templateQuestionId] = answer;
                if (templQuestionList[i].fieldType == 'File'
                    || templQuestionList[i].fieldType == 'Signature') {
                    //because currently we are not allowing to modify existing file
                    delete this.files[question.templateQuestionId];
                }
            }
        }
    }
    handleValueChanged(event) {
        const questionAnswer = event.detail.answer;
        var question = event.detail.question;

        var answer = this.getAnswerWrapper(question, questionAnswer);

        if (answer.answer != undefined && answer.answer != null && answer.answer.length > 0) {
            this.answers[question.templateQuestionId] = answer;
        } else {
            delete this.answers[question.templateQuestionId];
        }

        this.result = JSON.stringify(this.answers);

        this.calculateScore();
    }

    calculateScore() {
        this.totalObtainedScore = 0;
        if (this.answers.length == 0 && this.allExistingQuestionAnswers.length == 0) {
            return;
        }
        var answerLocalTempMap = JSON.parse(JSON.stringify(this.answers));
        Object.entries(answerLocalTempMap).forEach(([qId, answer]) => {
            var answerValues = [];
            if (answer.fieldType == 'Checkbox'
                && answer.answer != undefined
                && answer.answer != null) {
                var answerValuesLocal = answer.answer.split(';');
                for (var a = 0; a < answerValuesLocal.length; a++) {
                    if (answerValuesLocal[a] != undefined && answerValuesLocal[a] != null && answerValuesLocal[a].length > 0) {
                        answerValues.push(answerValuesLocal[a].trim());
                    }
                }
            } else if (answer.answer != undefined
                && answer.answer != null) {
                answerValues.push(answer.answer.trim());
            }
            for (var k = 0; k < answerValues.length; k++) {
                var localanswer = answerValues[k];
                if (this.scoreByoptionByQuestion.hasOwnProperty(answer.questionId)
                    && this.scoreByoptionByQuestion[answer.questionId] != null
                    && this.scoreByoptionByQuestion[answer.questionId].hasOwnProperty(localanswer)
                    && this.scoreByoptionByQuestion[answer.questionId][localanswer] != undefined) {
                    this.totalObtainedScore = this.totalObtainedScore + parseInt(this.scoreByoptionByQuestion[answer.questionId][localanswer]);
                    answer['scoreAttained'] = parseInt(this.scoreByoptionByQuestion[answer.questionId][localanswer]);
                    answer['outOfScore'] = this.maximumScoreByQuestion[answer.questionId] || 0;
                }
            }
            answerLocalTempMap[qId] = answer;
        });

        this.answers = answerLocalTempMap;

        //below code is for calculating score for all existing answers
        var answerLocalTempMapExisting = JSON.parse(JSON.stringify(this.allExistingQuestionAnswers));
        Object.entries(answerLocalTempMapExisting).forEach(([qId, answerLocal]) => {
            var answerValues = [];
            if (answerLocal.fieldType == 'Checkbox'
                && answerLocal.answer != undefined
                && answerLocal.answer != null) {
                var answerValuesLocal = answerLocal.answer.split(';');
                for (var a = 0; a < answerValuesLocal.length; a++) {
                    if (answerValuesLocal[a] != undefined && answerValuesLocal[a] != null
                        && answerValuesLocal[a].length > 0
                        && answerValuesLocal[a].trim().length > 0) {
                        answerValues.push(answerValuesLocal[a].trim());
                    }
                }
            } else if (answerLocal.answer != undefined
                && answerLocal.answer != null) {
                answerValues.push(answerLocal.answer.trim());
            }
            for (var k = 0; k < answerValues.length; k++) {
                var localanswer = answerValues[k];
                if (this.scoreByoptionByQuestion.hasOwnProperty(answerLocal.questionId)
                    && this.scoreByoptionByQuestion[answerLocal.questionId] != null
                    && this.scoreByoptionByQuestion[answerLocal.questionId].hasOwnProperty(localanswer)
                    && this.scoreByoptionByQuestion[answerLocal.questionId][localanswer] != undefined) {
                    this.totalObtainedScore = this.totalObtainedScore + parseInt(this.scoreByoptionByQuestion[answerLocal.questionId][localanswer]);
                }
            }
        });

        const scoreupdate = new CustomEvent('scoreupdate', {
            detail: {
                totalOutofScore: this.totalOutofScore,
                totalObtainedScore: this.totalObtainedScore
            }
        });
        // Dispatches the event.
        this.dispatchEvent(scoreupdate);
    }

    maintainVisitNotesRecords(event) {
        var question = event.detail.question;
        var noteId = event.detail.noteId;
        // var noteRec = event.detail.noteRec;
        this.visitNotesBySurveyQuestionId[question.templateQuestionId] = noteId;
        for (var i = 0; i < this.templQuestionList.length; i++) {
            if (this.templQuestionList[i].index == question.index
                && this.templQuestionList[i].templateQuestionId == question.templateQuestionId) {
                // this.templQuestionList[i]['noteId'] = noteId;
                // this.templQuestionList[i]['shortNoteDescription'] = noteRec;
                this.templQuestionList[i]['totalNumberOfNotesCreated'] = 1;
                break;
            }
        }
    }

    maintainTaskRecords(event) {

        var question = event.detail.question;
        var taskId = event.detail.taskId;
        var taskRecord = event.detail.taskRec;
        var taskRecordList = [];
        if (this.tasksArrayBySurveyQuestionId.hasOwnProperty(question.templateQuestionId)) {
            taskRecordList = this.tasksArrayBySurveyQuestionId[question.templateQuestionId];
        }
        var taskRecordIds = [];
        if (this.taskIdsArrayBySurveyQuestionId.hasOwnProperty(question.templateQuestionId)) {
            taskRecordIds = this.taskIdsArrayBySurveyQuestionId[question.templateQuestionId];
        }
        taskRecordList.push(taskRecord);
        taskRecordIds.push(taskId);

        this.tasksArrayBySurveyQuestionId[question.templateQuestionId] = taskRecordList;
        this.taskIdsArrayBySurveyQuestionId[question.templateQuestionId] = taskRecordIds;

        for (var i = 0; i < this.templQuestionList.length; i++) {
            if (this.templQuestionList[i].index == question.index
                && this.templQuestionList[i].templateQuestionId == question.templateQuestionId) {
                this.templQuestionList[i]['totalNumberOfTasksCreated'] = taskRecordList.length;
                break;
            }
        }
    }

    maintainFileUpload(event) {
        var uploadedfile = event.detail.file;
        var question = event.detail.question;

        var attachmentRecordList = [];
        if (this.attachmentArrayBySurveyQuestionId.hasOwnProperty(question.templateQuestionId)) {
            attachmentRecordList = this.attachmentArrayBySurveyQuestionId[question.templateQuestionId];
        }

        attachmentRecordList.push(uploadedfile);

        this.attachmentArrayBySurveyQuestionId[question.templateQuestionId] = attachmentRecordList;

        for (var i = 0; i < this.templQuestionList.length; i++) {
            if (this.templQuestionList[i].index == question.index
                && this.templQuestionList[i].templateQuestionId == question.templateQuestionId) {
                this.templQuestionList[i]['totalNumberOfFilesUploaded'] = attachmentRecordList.length;
                break;
            }
        }
    }

    getAnswerWrapper(question, questionAnswer) {
        var answer = {};
        answer.index = question.index;
        answer.templateQuestionId = question.templateQuestionId;
        answer.questionId = question.questionId;
        answer.questionDetails = question.questionDetails;
        answer.fieldType = question.fieldType;
        answer.questionValues = question.questionValues;
        answer.inspectionId = this.inspectionRecordId;
        answer.inspectionTemplateId = this.inspectionTemplateId;
        //answer.surveyId = this.templateRecordId;
        answer.existingAnswerId = question.existingAnswerId;

        if (answer.fieldType == 'File') {
            answer.answer = questionAnswer.name;
            // answer.file = questionAnswer;
            this.files[question.templateQuestionId] = questionAnswer;
            this.updateQuestion(question, questionAnswer.name);
        } else if (answer.fieldType == 'Signature') {
            answer.answer = '';
            delete this.files[question.templateQuestionId];
            if (questionAnswer != undefined && questionAnswer != null && questionAnswer.length > 0) {
                answer.answer = 'Signature_' + this.inspectionRecordId + '_' + question.templateQuestionId + '.png';
                this.files[question.templateQuestionId] = questionAnswer;
            }
            // answer.file = questionAnswer;
            this.updateQuestion(question, answer.answer);
        } else {
            answer.answer = questionAnswer;
            this.updateQuestion(question, questionAnswer);
        }
        return answer;
    }

    updateQuestion(q, answer) {
        for (var i = 0; i < this.templQuestionList.length; i++) {
            if (this.templQuestionList[i].index == q.index
                && this.templQuestionList[i].templateQuestionId == q.templateQuestionId) {
                this.templQuestionList[i].answer = answer;
                break;
            }
        }
    }

    generateMissingAnswers() {
        var questionBySurveyQuestionIdMap = {};
        for (var i = 0; i < this.templQuestionList.length; i++) {
            questionBySurveyQuestionIdMap[this.templQuestionList[i].templateQuestionId] = this.templQuestionList[i];
        }
        var surveyIdListForNotes = Object.keys(this.visitNotesBySurveyQuestionId);
        for (var j = 0; j < surveyIdListForNotes.length; j++) {
            if (!this.answers.hasOwnProperty(surveyIdListForNotes[j]) && questionBySurveyQuestionIdMap.hasOwnProperty(surveyIdListForNotes[j])) {
                var answerWrapper = this.getAnswerWrapper(questionBySurveyQuestionIdMap[surveyIdListForNotes[j]], '');
                this.answers[questionBySurveyQuestionIdMap[surveyIdListForNotes[j]].templateQuestionId] = answerWrapper;
            }
        }

        var surveyIdListForTasks = Object.keys(this.taskIdsArrayBySurveyQuestionId);
        for (var j = 0; j < surveyIdListForTasks.length; j++) {
            if (!this.answers.hasOwnProperty(surveyIdListForTasks[j]) && questionBySurveyQuestionIdMap.hasOwnProperty(surveyIdListForTasks[j])) {
                var answerWrapper = this.getAnswerWrapper(questionBySurveyQuestionIdMap[surveyIdListForTasks[j]], '');
                this.answers[questionBySurveyQuestionIdMap[surveyIdListForTasks[j]].templateQuestionId] = answerWrapper;
            }
        }


        var surveyQuestIdListForAttachment = Object.keys(this.attachmentArrayBySurveyQuestionId);
        for (var j = 0; j < surveyQuestIdListForAttachment.length; j++) {
            if (!this.answers.hasOwnProperty(surveyQuestIdListForAttachment[j]) && questionBySurveyQuestionIdMap.hasOwnProperty(surveyQuestIdListForAttachment[j])) {
                var answerWrapper = this.getAnswerWrapper(questionBySurveyQuestionIdMap[surveyQuestIdListForAttachment[j]], '');
                this.answers[questionBySurveyQuestionIdMap[surveyQuestIdListForAttachment[j]].templateQuestionId] = answerWrapper;
            }
        }
    }

    mergeAttachmentsInFilesList() {
        //TODO: need to handle multiple attachments to the same question
        var surveyQuestIdListForAttachment = Object.keys(this.attachmentArrayBySurveyQuestionId);
        for (var j = 0; j < surveyQuestIdListForAttachment.length; j++) {
            this.files[surveyQuestIdListForAttachment[j]] = this.attachmentArrayBySurveyQuestionId[surveyQuestIdListForAttachment[j]][0];
        }
    }

    handleSubmit(event) {
        console.log('inspTemplateQuestionRendererLWC >> handleSubmit');
        // skip submission
        if (this.disableSubmission) {
            return;
        }
        console.log(this.answers);
        //  console.log(JSON.stringify(this.answers));
        this.showSpinner = true;
        this.generateMissingAnswers();
        this.mergeAttachmentsInFilesList();

        const fields = {};
        fields['Kinetics__Available_Score__c'] = this.totalOutofScore;
        fields['Kinetics__Total_Score__c'] = this.totalObtainedScore;
        fields['Id'] = this.inspectionRecordId;

        const recordInput = { fields };

        updateRecord(recordInput).then((result) => {
            saveAnswers({ answerJsonString: JSON.stringify(this.answers) }).then(result => {
                console.log(JSON.parse(result));
                var answerIdByTemplateQuestionId = JSON.parse(result).responseDetails;
                //  this.shareNoteRecordsWithRequiredRecord(answerIdByTemplateQuestionId);

                //commentted below because that might not be required.....
                //this.handleTaskRecordProcessing(answerIdByTemplateQuestionId);

                if (Object.entries(this.files).length > 0) {
                    // uploading files
                    this.uploadFiles(answerIdByTemplateQuestionId);
                    //TODO: I think  it can create problems
                    this.finishSubmittion();
                } else {
                    this.showSpinner = false;
                    this.finishSubmittion();
                }
            }).catch(error => {
                this.showToast('Inspection', 'error', error.body.message);
            });
        }).catch(error => {
            this.showToast('Inspection', 'error', error.body.message);
        });
    }

    finishSubmittion() {

        this.showToast('', 'success', this.inspectionRec.Name + ' was saved.');
        this.closeQuickAction();
    }

    //shareNoteRecordsWithRequiredRecord(answerIdByTemplateQuestionId) {

    // var inspectionId = this.inspectionRec.Id;
    // var contactId = this.inspectionRec.Kinetics__Contact__c;
    // var accountId = this.inspectionRec.Kinetics__Account__c;
    // var shareWithIdListByNoteId = {};
    // var templateQuestionIdList = Object.keys(this.visitNotesBySurveyQuestionId);
    // for(var i=0;i<templateQuestionIdList.length;i++){
    //     if(this.visitNotesBySurveyQuestionId.hasOwnProperty(templateQuestionIdList[i])
    //         && answerIdByTemplateQuestionId.hasOwnProperty(templateQuestionIdList[i])){
    //             shareWithIdListByNoteId[this.visitNotesBySurveyQuestionId[templateQuestionIdList[i]]] = [];
    //             //shareWithIdListByNoteId[this.visitNotesBySurveyQuestionId[templateQuestionIdList[i]]] = [answerIdByTemplateQuestionId[templateQuestionIdList[i]]];
    //             if(inspectionId != undefined && inspectionId != '') {
    //                 shareWithIdListByNoteId[this.visitNotesBySurveyQuestionId[templateQuestionIdList[i]]].push(inspectionId);
    //             }
    //             if(accountId != undefined && accountId != '') {
    //                 shareWithIdListByNoteId[this.visitNotesBySurveyQuestionId[templateQuestionIdList[i]]].push(accountId);
    //             }
    //             if(contactId != undefined && contactId != '') {
    //                 shareWithIdListByNoteId[this.visitNotesBySurveyQuestionId[templateQuestionIdList[i]]].push(contactId);
    //             }

    //     }
    // }

    // shareNoteRecord({shareWithIdListByNoteId: shareWithIdListByNoteId}).then(result => {
    //     console.log(result);
    // }).catch(error => {
    //     console.log(error);
    // })
    //}

    // handleTaskRecordProcessing(answerIdByTemplateQuestionId) {
    //     var tasksRecordIdListByAnswerId = {};
    //     var templateQuestionIdList = Object.keys(this.taskIdsArrayBySurveyQuestionId);
    //     for(var i=0;i<templateQuestionIdList.length;i++) {
    //         var templateQuestionId = templateQuestionIdList[i];
    //         var taskRecordIds = [];
    //         if(this.taskIdsArrayBySurveyQuestionId.hasOwnProperty(templateQuestionId)) {
    //             taskRecordIds = this.taskIdsArrayBySurveyQuestionId[templateQuestionId];
    //         }
    //         if(taskRecordIds.length > 0) {
    //             tasksRecordIdListByAnswerId[answerIdByTemplateQuestionId[templateQuestionId]] = taskRecordIds;
    //         }
    //     }
    //     updateTaskRecord({tasksRecordIdListByAnswerId: tasksRecordIdListByAnswerId}).then(result => {
    //         console.log(result);
    //     }).catch(error => {
    //         console.log(error);
    //     })
    // }

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message
        });
        this.dispatchEvent(event);
    }

    hanldeCatchBlock(errorMessage) {
        errorMessage = errorMessage;
        if (errorMessage.hasOwnProperty('body') && errorMessage.body.hasOwnProperty('message')) {
            errorMessage = errorMessage.body.message;
        }
        this.showToast('Inspection Template Answer', 'error', errorMessage)
    }

    uploadFiles(answerIdMap) {

        for (const [key, value] of Object.entries(this.files)) {
            this.numOfFilesToUpload = this.numOfFilesToUpload + 1;
            if (value != undefined && value != null && value != '') {
                var fileCon = {};
                var templateAnswerId = answerIdMap[key];
                if (this.answers[key].fieldType == 'Signature') {
                    fileCon['name'] = this.answers[key].answer;
                    fileCon['type'] = 'image/png';
                    fileCon['signContent'] = value;

                    this.saveSignature(fileCon, templateAnswerId);
                } else {
                    var fileCon = value;
                    this.saveFile(fileCon, templateAnswerId);
                }
            }
        }
    }

    resizeImageAndUpload(fileCon, event, self, templateAnswerId) {
        var image = new Image();
        image.onload = function () {
            var width = image.width;
            var height = image.height;

            var canvas = document.createElement("canvas");
            canvas.width = width;
            canvas.height = height;

            var context = canvas.getContext("2d");
            context.msImageSmoothingEnabled = false;
            context.drawImage(image, 0, 0);

            var quality = 0.90;
            var fileContents = canvas.toDataURL('image/jpeg', quality);
            while (fileContents.length > MAX_SUPPORTED_FILE_SIZE && quality >= 0.20) {
                quality = quality - 0.10;
                fileContents = null;
                fileContents = canvas.toDataURL('image/jpeg', quality);
            }
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
            self.upload(fileCon, fileContents, templateAnswerId);
        }
        image.src = event.target.result;
    }
    saveSignature(fileCon, templateAnswerId) {
        var fileContents = fileCon.signContent;
        var base64Mark = 'base64,';
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        this.upload(fileCon, fileContents, templateAnswerId);
    }

    saveFile(fileCon, templateAnswerId) {
        var reader = new FileReader();
        var self = this;
        reader.onload = function (event) {
            if (imageFilterType.test(fileCon.type)) {
                self.resizeImageAndUpload(fileCon, event, self, templateAnswerId);
            } else {
                var fileContents = reader.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                fileContents = fileContents.substring(dataStart);
                self.upload(fileCon, fileContents, templateAnswerId);
            }
        };
        reader.readAsDataURL(fileCon);
    }

    upload(file, fileContents, templateAnswerId) {
        if (fileContents.length > MAX_FILE_SIZE) {
            let message = 'File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + fileContents.length;
            this.hanldeCatchBlock(message);
            return;
        }
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);

        this.uploadChunk(file, fileContents, fromPos, toPos, '', templateAnswerId);
    }

    uploadChunk(file, fileContents, fromPos, toPos, attachId, templateAnswerId) {
        var chunk = fileContents.substring(fromPos, toPos);

        saveTheChunkFile({
            inspectionId: this.inspectionRecordId,
            templateAnswerId: templateAnswerId,
            fileName: file['updatedname'] || file['name'],
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId
        }).then(result => {
            attachId = result;
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
            if (fromPos < toPos) {
                this.uploadChunk(file, fileContents, fromPos, toPos, attachId, templateAnswerId);
            } else {
                this.numOfFilesUploaded = this.numOfFilesUploaded + 1;

                if (this.numOfFilesUploaded == this.numOfFilesToUpload) {
                    //TODO:
                    this.showSpinner = false;

                }
            }
        }).catch(error => {
            console.error('Error: ', error);
            this.hanldeCatchBlock(error);
            this.showSpinner = false;
        }).finally(() => {

        });
    }

    closeQuickAction() {
        const closepopup = new CustomEvent('closepopup');
        // Dispatches the event.
        this.dispatchEvent(closepopup);
    }

    formatBytes(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }


    handleShowDetails(event) {
        this.parentRecordId = event.target.dataset.parentRecordId;;
        this.parentObject = event.target.dataset.parentObjectName;;
        this.parentRecordName = event.target.dataset.parentRecordName;
        this.showParentRecordDetailPopup = true;
    }

    hideModalBox() {
        this.showParentRecordDetailPopup = false;
        this.parentRecordId = '';
        this.parentObject = '';
        this.parentRecordName = '';
    }
}