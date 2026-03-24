import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInspectionDetails from '@salesforce/apex/TbInspTemplateQuestionRendererController.getInspectionDetails';
import { updateRecord } from 'lightning/uiRecordApi';
import saveAnswers from '@salesforce/apex/TbInspTemplateQuestionRendererController.saveAnswers';
import saveTheChunkFile from '@salesforce/apex/InspTemplateRendererController.saveTheChunkFile';
import updateStatusToInprogress from '@salesforce/apex/TbInspTemplateQuestionRendererController.updateStatusToInprogress';
import linkAnswerToTasks from '@salesforce/apex/TbInspTemplateQuestionRendererController.linkAnswerToTasks';
import linkAnswerToNotes from '@salesforce/apex/TbInspTemplateQuestionRendererController.linkAnswerToNotes';

import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
const MAX_FILE_SIZE = 6500000;
const CHUNK_SIZE = 1000000;
const MAX_SUPPORTED_FILE_SIZE = 1000000;
const imageFilterType = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i;

export default class TbInspTemplateQuestionRendererNG extends LightningElement {

    @api recordId;
    @track templatePageMetadata = {};
    @track scoredetails = {};
    @track inspectionRec;
    @track templateRec;
    @track newTemplatePresent = true;
    @track existingAnswersByUniqueId = {};
    templateName;
    questionsMap = {};
    answers = {};
    files = {};
    visitNotesBySurveyQuestionId = {};
    attachmentArrayBySurveyQuestionId = {};
    tasksArrayBySurveyQuestionId = {};
    taskIdsArrayBySurveyQuestionId = {};
    showSpinner = true;
    scoreByoptionByQuestion = {};
    maximumScoreByQuestion = {};
    totalOutofScore = 0;
    totalObtainedScore = 0;
    totalNumberOfQuestions = 0;
    taskCountByAnswerId = {};
    noteCountByAnswerId = {};
    fileCountByAnswerId = {};
    numOfFilesToUpload = 0;

    @api inspectionOutcome;

    connectedCallback() {
        getInspectionDetails({ inspectionRecId: this.recordId }).then(resultWrapper => {
            var resultWrapper = JSON.parse(resultWrapper);
            this.inspectionRec = resultWrapper.inspectionRec;
            this.templateRec = resultWrapper.templateRec;
            this.existingAnswersByUniqueId = resultWrapper.existingAnswersByUniqueId;
            this.taskCountByAnswerId = resultWrapper.taskCountByAnswerId;
            this.noteCountByAnswerId = resultWrapper.noteCountByAnswerId;
            this.fileCountByAnswerId = resultWrapper.fileCountByAnswerId;
            this.templateName = this.templateRec.Name;
            this.updateStatusToInProgress();
            this.loadTemplateRecord(this.templateRec);
        }).catch(error => {
            this.showErrorMessage(error.body.message);
        });

    }

    loadTemplateRecord(fetchedExistingRecord) {
        this.templatePageMetadata.selectedFormValue = {};
        this.templatePageMetadata.selectedFormValue.Name = fetchedExistingRecord.Name;
        this.templatePageMetadata.selectedFormValue.Kinetics__Instructions__c = fetchedExistingRecord.Kinetics__Instructions__c;
        this.templatePageMetadata.selectedFormValue.Kinetics__Status__c = fetchedExistingRecord.Kinetics__Status__c;
        this.templatePageMetadata.selectedFormValue.Kinetics__Questions_By_Page_No__c = fetchedExistingRecord.Kinetics__Questions_By_Page_No__c;
        this.templatePageMetadata.selectedFormValue.Kinetics__Section_Metadata__c = fetchedExistingRecord.Kinetics__Section_Metadata__c;
        this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c = fetchedExistingRecord.Kinetics__Template_Metadata__c;

        this.templatePageMetadata.ispreviewshown = false;
        this.templatePageMetadata.pagelist = [];
        this.newTemplatePresent = false;
        if (this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != null
            && this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != ''
            && this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != undefined) {
            this.templatePageMetadata.pagelist = JSON.parse(this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c);//.replaceAll('\\', ''));
            this.templatePageMetadata.existingAnswersByUniqueId = this.existingAnswersByUniqueId;
            this.templatePageMetadata.taskCountByAnswerId = this.taskCountByAnswerId;
            this.templatePageMetadata.noteCountByAnswerId = this.noteCountByAnswerId;
            this.templatePageMetadata.fileCountByAnswerId = this.fileCountByAnswerId;
            this.templatePageMetadata.answers = this.answers;
            this.newTemplatePresent = true;
            this.generateAnswerWrapperForExistingAnswers();
            this.generateScoreWrapperByQuestionUId();
        }
        this.calculateScore();
        this.updateLastModifiedMetadata();
    }
    showErrorMessage(message) {
        this.showToast('Inspection', 'error', message);
    }

    updateLastModifiedMetadata() {
        //this is done to have one place from where the changes are broadcasted, so that child component get the updated version
        this.templatePageMetadata = JSON.parse(JSON.stringify(this.templatePageMetadata));
        this.showSpinner = false;
    }
    updateStatusToInProgress() {
        //this.recordId;
        if (this.inspectionRec.Kinetics__Status__c == 'Not Started') {
            updateStatusToInprogress({ inspRecId: this.inspectionRec.Id }).then(success => {
                //updated to in progress
            }).catch(error => {
                this.showToast('Inspection', 'error', error.body.message);
            });
        }
    }


    handleCancel(event) {
    }

    answersSnapshot = '';
    handleSave(event) {
        var isAutoSave = (event.detail.event && event.detail.event.type && event.detail.event.type == 'autosave');
        if (isAutoSave) {
            this.showSpinner = false;

            // check if the answers are changed 
            // if (this.answersSnapshot.replaceAll('\\', '').replaceAll('"', '') == JSON.stringify(this.answers).replaceAll('\\', '').replaceAll('"', '')) {
            //     return;
            // } else {
            //     this.answersSnapshot = JSON.stringify(this.answers);
            // }
        } else {
            this.showSpinner = true;
        }

        this.generateMissingAnswers();
        this.mergeAttachmentsInFilesList();

        const fields = {};
        fields['Kinetics__Available_Score__c'] = this.totalOutofScore;
        fields['Kinetics__Total_Score__c'] = this.totalObtainedScore;
        fields['Kinetics__Answered_Questions__c'] = this.answers.length;
        fields['Id'] = this.inspectionRec.Id;

        const recordInput = { fields };

        updateRecord(recordInput).then((result) => {
            //do some pre processing
            var keysList = Object.keys(this.answers);
            var answersObj = {};
            for (var i = 0; i < keysList.length; i++) {

                var answerObj = {};
                answerObj = this.answers[keysList[i]];
                answerObj.questionValues = JSON.stringify(answerObj.questionValues);
                answersObj[answerObj.templateQuestionId] = answerObj;
            }
            saveAnswers({ answerJsonString: JSON.stringify(answersObj) }).then(result => {
                console.log('***** saveAnswers');
                var answerIdByTemplateQuestionId = JSON.parse(result).responseDetails;

                if (isAutoSave) {
                    return;
                }

                linkAnswerToTasks({
                    answerIdByTemplateQuestionIdString: JSON.stringify(answerIdByTemplateQuestionId),
                    taskIdsArrayBySurveyQuestionIdString: JSON.stringify(this.taskIdsArrayBySurveyQuestionId)
                }).then(success => {
                    console.log(success);
                }).catch(error => {
                    console.log(error);
                    this.showToast('Inspection', 'error', error.body.message);
                });

                linkAnswerToNotes({
                    answerIdByTemplateQuestionIdString: JSON.stringify(answerIdByTemplateQuestionId),
                    noteIdsArrayBySurveyQuestionIdString: JSON.stringify(this.visitNotesBySurveyQuestionId)
                }).then(success => {
                    console.log(success);
                }).catch(error => {
                    console.log(error);
                    this.showToast('Inspection', 'error', error.body.message);
                });

                if (Object.entries(this.files).length > 0) {
                    // uploading files
                    this.uploadFiles(answerIdByTemplateQuestionId);
                    //TODO: I think  it can create problems
                    this.finishSubmittion();
                } else {
                    this.finishSubmittion();
                }
            }).catch(error => {
                this.showToast('Inspection', 'error', error.body.message);
            });
        }).catch(error => {
            this.showToast('Inspection', 'error', error.body.message);
        });

        var outcome = 'not compliant';
        if (this.totalObtainedScore > 1) {
            outcome = 'compliant';
        }
        const attributeChangeEvent = new FlowAttributeChangeEvent('inspectionOutcome', outcome);
        this.dispatchEvent(attributeChangeEvent);
    }

    updateQuestionAnswer(event) {
        console.log('******* updateQuestionAnswer');
        var question = event.detail.question;
        var questionAnswer = event.detail.questionAnswer;
        var answer = this.getAnswerWrapper(question, questionAnswer);

        if (answer.answer != undefined && answer.answer != null && answer.answer.length > 0) {
            this.answers[question.templateQuestionId] = answer;
        } else {
            delete this.answers[question.templateQuestionId];
        }

        this.calculateScore();
        this.templatePageMetadata.answers = this.answers;

        // update show dependant question flag based on the event from the child
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    if (quest.uid == question.questionId) {
                        quest.showDependantQuestion = question.showDependantQuestion;

                        if (JSON.stringify(quest.currentDependantQuestion) != JSON.stringify(question.currentDependantQuestion)
                            && question.currentDependantQuestion.templateQuestionId != undefined) {
                            console.log('need to update depedent answers ....');
                            var answerDependent = this.getAnswerWrapper(question.currentDependantQuestion, '');
                            this.answers[question.currentDependantQuestion.templateQuestionId] = answerDependent;
                        }

                        quest.currentDependantQuestion = question.currentDependantQuestion;




                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                        break;
                    }
                }
            }
        }
        this.updateLastModifiedMetadata();
    }

    getAnswerWrapper(question, questionAnswer) {
        var answer = {};
        answer.index = question.index;
        answer.templateQuestionId = question.templateQuestionId;
        answer.questionId = question.questionId;
        answer.questionDetails = question.questionDetails;
        answer.fieldType = question.fieldType;
        answer.questionValues = question.questionValues;
        answer.inspectionId = this.inspectionRec.Id;
        answer.inspectionTemplateId = this.templateRec.Id;
        answer.existingAnswerId = question.existingAnswerId;
        answer.chatgptguidance = question.chatgptguidance;

        if (answer.fieldType == 'File') {
            answer.answer = questionAnswer.name;
            this.files[question.templateQuestionId] = questionAnswer;
            this.updateQuestion(question, questionAnswer.name);
        } else if (answer.fieldType == 'Signature') {
            answer.answer = '';
            delete this.files[question.templateQuestionId];
            if (questionAnswer != undefined && questionAnswer != null && questionAnswer.length > 0) {
                answer.answer = 'Signature_' + this.inspectionRec.Id + '_' + question.templateQuestionId + '.png';
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
        q['answer'] = answer;
        this.questionsMap[q.templateQuestionId] = q;
    }

    maintainVisitNotesRecords(event) {
        var question = event.detail.question;
        var noteId = event.detail.noteId;
        var visitNoteIdList = [];
        if (this.visitNotesBySurveyQuestionId.hasOwnProperty(question.templateQuestionId)) {
            visitNoteIdList = this.visitNotesBySurveyQuestionId[question.templateQuestionId];
        }
        visitNoteIdList.push(noteId);
        this.visitNotesBySurveyQuestionId[question.templateQuestionId] = visitNoteIdList;

        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    if (quest.uid == question.templateQuestionId) {
                        quest['totalNumberOfNotesCreated'] = this.visitNotesBySurveyQuestionId[question.templateQuestionId].length + (this.noteCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.noteCountByAnswerId[question.existingAnswerId] : 0);
                        quest['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                        break;
                    }
                    if (question.questionId.indexOf('-child-') > 0) {
                        //this is dependent question
                        var parentQuestionId = question.questionId.split('-child-')[0];
                        if (quest.uid == parentQuestionId) {
                            var dependetQuestion = quest.currentDependantQuestion;
                            dependetQuestion['totalNumberOfNotesCreated'] = this.visitNotesBySurveyQuestionId[question.templateQuestionId].length + (this.noteCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.noteCountByAnswerId[question.existingAnswerId] : 0);
                            dependetQuestion['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                            quest.currentDependantQuestion = dependetQuestion;
                            this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                            break;
                        }
                    }
                }
            }
        }
        this.updateLastModifiedMetadata();
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

        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    if (quest.uid == question.templateQuestionId) {
                        quest['totalNumberOfTasksCreated'] = this.tasksArrayBySurveyQuestionId[question.templateQuestionId].length + (this.taskCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.taskCountByAnswerId[question.existingAnswerId] : 0);
                        quest['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                        break;
                    }
                    if (question.questionId.indexOf('-child-') > 0) {
                        //this is dependent question
                        var parentQuestionId = question.questionId.split('-child-')[0];
                        if (quest.uid == parentQuestionId) {

                            var dependetQuestion = quest.currentDependantQuestion;
                            dependetQuestion['totalNumberOfTasksCreated'] = this.tasksArrayBySurveyQuestionId[question.templateQuestionId].length + (this.taskCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.taskCountByAnswerId[question.existingAnswerId] : 0);
                            dependetQuestion['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                            quest.currentDependantQuestion = dependetQuestion;
                            this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                            break;
                        }
                    }
                }
            }
        }
        this.updateLastModifiedMetadata();
    }

    maintainFileUpload(event) {
        var uploadedfile = event.detail.uploadedfile;
        var question = event.detail.question;
        var attachmentRecordList = [];
        if (this.attachmentArrayBySurveyQuestionId.hasOwnProperty(question.templateQuestionId)) {
            attachmentRecordList = this.attachmentArrayBySurveyQuestionId[question.templateQuestionId];
        }

        attachmentRecordList.push(uploadedfile);

        this.attachmentArrayBySurveyQuestionId[question.templateQuestionId] = attachmentRecordList;

        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    if (quest.uid == question.templateQuestionId) {
                        quest['totalNumberOfFilesUploaded'] = this.attachmentArrayBySurveyQuestionId[question.templateQuestionId].length + (this.fileCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.fileCountByAnswerId[question.existingAnswerId] : 0);
                        quest['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                        break;
                    }
                    if (question.questionId.indexOf('-child-') > 0) {
                        //this is dependent question
                        var parentQuestionId = question.questionId.split('-child-')[0];
                        if (quest.uid == parentQuestionId) {

                            var dependetQuestion = quest.currentDependantQuestion;
                            dependetQuestion['totalNumberOfFilesUploaded'] = this.attachmentArrayBySurveyQuestionId[question.templateQuestionId].length + (this.fileCountByAnswerId.hasOwnProperty(question.existingAnswerId) ? this.fileCountByAnswerId[question.existingAnswerId] : 0);
                            dependetQuestion['answer'] = this.questionsMap.hasOwnProperty(question.templateQuestionId) ? this.questionsMap[question.templateQuestionId].answer : '';
                            quest.currentDependantQuestion = dependetQuestion;
                            this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                            break;
                        }
                    }
                }
            }
        }
        this.updateLastModifiedMetadata();
    }

    generateMissingAnswers() {

        var surveyIdListForNotes = Object.keys(this.visitNotesBySurveyQuestionId);
        for (var j = 0; j < surveyIdListForNotes.length; j++) {
            if (!this.answers.hasOwnProperty(surveyIdListForNotes[j]) && this.questionsMap.hasOwnProperty(surveyIdListForNotes[j])) {
                var answerWrapper = this.getAnswerWrapper(this.questionsMap[surveyIdListForNotes[j]], '');
                this.answers[this.questionsMap[surveyIdListForNotes[j]].templateQuestionId] = answerWrapper;
            }
        }

        var surveyIdListForTasks = Object.keys(this.taskIdsArrayBySurveyQuestionId);
        for (var j = 0; j < surveyIdListForTasks.length; j++) {
            if (!this.answers.hasOwnProperty(surveyIdListForTasks[j]) && this.questionsMap.hasOwnProperty(surveyIdListForTasks[j])) {
                var answerWrapper = this.getAnswerWrapper(this.questionsMap[surveyIdListForTasks[j]], '');
                this.answers[this.questionsMap[surveyIdListForTasks[j]].templateQuestionId] = answerWrapper;
            }
        }


        var surveyQuestIdListForAttachment = Object.keys(this.attachmentArrayBySurveyQuestionId);
        for (var j = 0; j < surveyQuestIdListForAttachment.length; j++) {
            if (!this.answers.hasOwnProperty(surveyQuestIdListForAttachment[j]) && this.questionsMap.hasOwnProperty(surveyQuestIdListForAttachment[j])) {
                var answerWrapper = this.getAnswerWrapper(this.questionsMap[surveyQuestIdListForAttachment[j]], '');
                this.answers[this.questionsMap[surveyQuestIdListForAttachment[j]].templateQuestionId] = answerWrapper;
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

    showToast(title, variant, message) {
        this.showSpinner = false;
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

    finishSubmittion() {
        this.showSpinner = false;
        this.showToast('', 'success', this.inspectionRec.Name + ' was saved.');
        this.closeQuickAction();

        // navigate to the next step in Salesforce flow
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
    uploadFiles(answerIdMap) {
        this.numOfFilesToUpload = 0;
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
            inspectionId: this.inspectionRec.Id,
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
            this.showSpinner = false;
        });
    }

    closeQuickAction() {
        const closepopup = new CustomEvent('closepopup');
        // Dispatches the event.
        this.dispatchEvent(closepopup);
        this.showSpinner = false;
    }

    formatBytes(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    generateScoreWrapperByQuestionUId() {
        this.scoreByoptionByQuestion = {};
        this.totalOutofScore = 0;
        this.totalNumberOfQuestions = 0;
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    this.totalNumberOfQuestions = this.totalNumberOfQuestions + 1;
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    this.scoreByoptionByQuestion[quest.uid] = {};
                    this.maximumScoreByQuestion[quest.uid] = 0;
                    if (quest.Kinetics__Values__c != undefined
                        && quest.Kinetics__Values__c != null
                        && quest.Kinetics__Values__c != '') {
                        var scoreByOption = {};
                        for (var v = 0; v < quest.Kinetics__Values__c.length; v++) {
                            scoreByOption[quest.Kinetics__Values__c[v].value] = parseInt(quest.Kinetics__Values__c[v].score);
                            if (this.maximumScoreByQuestion.hasOwnProperty(quest.uid)
                                && parseInt(this.maximumScoreByQuestion[quest.uid]) < parseInt(quest.Kinetics__Values__c[v].score)) {
                                this.maximumScoreByQuestion[quest.uid] = parseInt(quest.Kinetics__Values__c[v].score);
                            }
                        }
                        this.totalOutofScore = this.totalOutofScore + (parseInt(this.maximumScoreByQuestion[quest.uid]) || 0);
                        this.scoreByoptionByQuestion[quest.uid] = JSON.parse(JSON.stringify(scoreByOption));
                    }
                }
            }
        }
    }
    getAnswerWrapperForExistingAnswer(question) {
        var answer = {};
        var questionAnswer = question.Kinetics__Answer__c;
        answer.index = question.Kinetics__Answer_Index__c;
        answer.templateQuestionId = question.Kinetics__Template_Question_UID__c;
        answer.questionId = question.Kinetics__Template_Question_UID__c;
        answer.questionDetails = question.Kinetics__Kinetic_Question__c;
        answer.fieldType = question.Kinetics__Type__c;
        answer.questionValues = [];
        if (question.Kinetics__Kinetic_Question_Values__c != undefined
            && question.Kinetics__Kinetic_Question_Values__c != ''
            && question.Kinetics__Kinetic_Question_Values__c != null) {
            answer.questionValues = JSON.parse(question.Kinetics__Kinetic_Question_Values__c);
        }
        answer.inspectionId = this.inspectionRec.Id;
        answer.inspectionTemplateId = this.templateRec.Id;
        answer.existingAnswerId = question.Id;
        answer.chatgptguidance = question.Kinetics__AI_Guidance__c;

        if (answer.fieldType == 'File') {
            answer.answer = questionAnswer;
            // this.files[answer.templateQuestionId] = questionAnswer;
            this.updateQuestion(question, questionAnswer);
        } else if (answer.fieldType == 'Signature') {
            answer.answer = '';
            delete this.files[answer.templateQuestionId];
            if (questionAnswer != undefined && questionAnswer != null && questionAnswer.length > 0) {
                answer.answer = 'Signature_' + this.inspectionRec.Id + '_' + answer.templateQuestionId + '.png';
                //this.files[answer.templateQuestionId] = questionAnswer;
            }
            // answer.file = questionAnswer;
            this.updateQuestion(question, answer.answer);
        } else {
            answer.answer = questionAnswer;
            this.updateQuestion(question, questionAnswer);
        }
        return answer;
    }

    generateAnswerWrapperForExistingAnswers() {
        if (Object.keys(this.existingAnswersByUniqueId).length == 0) {
            return 0;
        }

        //below code is for calculating score for all existing answers
        var answerLocalTempMapExisting = JSON.parse(JSON.stringify(this.existingAnswersByUniqueId));
        Object.entries(answerLocalTempMapExisting).forEach(([qId, answerLocal]) => {
            var answerLocalObj = this.getAnswerWrapperForExistingAnswer(answerLocal);
            this.answers[qId] = answerLocalObj;
        });
    }
    calculateScore() {
        this.totalObtainedScore = 0;
        if (this.answers.length == 0) {
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
                    answer['outOfScore'] = parseInt(this.maximumScoreByQuestion[answer.questionId]) || 0;
                    // this.totalOutofScore = this.totalOutofScore + answer['outOfScore'];
                }
            }
            answerLocalTempMap[qId] = answer;
        });

        this.answers = answerLocalTempMap;
        this.scoredetails.totalOutofScore = this.totalOutofScore;
        this.scoredetails.totalObtainedScore = this.totalObtainedScore;
        this.scoredetails = JSON.parse(JSON.stringify(this.scoredetails));
    }
}