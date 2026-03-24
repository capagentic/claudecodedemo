import { LightningElement, track } from 'lwc';

import getSequenceBySurveyGuid from '@salesforce/apex/SeqRendererController.getSequenceBySurveyGuid';
import saveAnswers from '@salesforce/apex/SeqRendererController.saveAnswers';
import updateSurvey2InProgress from '@salesforce/apex/SeqRendererController.updateSurvey2InProgress';
import saveTheChunkFile from '@salesforce/apex/FileUploadService.saveTheChunkFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const MAX_FILE_SIZE = 6500000;
//const CHUNK_SIZE = 750000;
const CHUNK_SIZE = 1000000;
const MAX_SUPPORTED_FILE_SIZE = 1000000;
const imageFilterType = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i;
const sentToRecipientStage = 'Sent to recipient';
const partiallyCompletedStage = 'Partially Completed';
export default class SeqRendererWithPagination extends LightningElement {

    // data
    result;
    errorMessage;
    questions = [];
    answers = {};
    @track currentQuestion = {};
    @track files = {};
    instruction;
    surveyName;
    greeting;
    pageTitle;
    surveyInviteId;
    answersDB = [];
    pageTitleClass = 'welcomePageTitle';


    // index
    currentIndex = -1;
    maxIndex = 0;

    // element visibility
    timeoutId;
    @track openState;
    showDebugger = false;
    showStartBtn = true;
    showNextBtn = false;
    showBackBtn = false;
    showWelcome = false;
    showError = false;
    showComplete = false;
    showSpinner = false;
    showQuestionProgress = false;
    disableSubmitBtn = false;

    isLastQuestion = false;
    isFirstQuestion = false;
    isPreview = false;


    // for file upload
    numOfFilesUploaded = 0;
    numOfFilesToUpload = 0;
    
    scoreByQuestionByOption = {};
    @track totalScore = 0;
    @track totalAvailableScore = 0;
    @track pageslist = [];
    @track selectedpage = {};
    currentPageIndex = -1;
    currentPageDisplayIndex = 0;
    totalPageNo = 0;
    currentpageprogress = 0;

    connectedCallback() {
        var guid = this.getQueryParameters('seqnum');
        this.showDebugger = this.getParameterByName('debug');
        // this.isPreview = this.getQueryParameters('preview');
        this.getSequenceBySurveyGuid(guid);


    }

    hanldeCatchBlock(errorMessage) {
        this.showError = true;
        this.errorMessage = errorMessage;
        if (errorMessage.hasOwnProperty('body') && errorMessage.body.hasOwnProperty('message')) {
            this.errorMessage = errorMessage.body.message;
        }
        this.showSpinner = false;
    }
    updateInProgress(guid) {
        updateSurvey2InProgress({
            surveyGUID: guid
        })
            .then(result => {
                var resObj = JSON.parse(result);
                if (resObj.statusCode == '2000') {
                    console.log('Stage update successful');
                } else if (resObj.statusCode == '2100') {
                    this.hanldeCatchBlock(resObj.responseMessage);
                }
            })
            .catch(error => {
                this.hanldeCatchBlock(error);
            });
    }

    getSequenceBySurveyGuid(guid) {
        getSequenceBySurveyGuid({
            surveyGUID: guid
        })
        .then(result => {
            this.result = result;
            var resObj = JSON.parse(result);

            if (resObj.statusCode == '2000') {
                this.questions = resObj.responseDetails.sqList;
                this.maxIndex = this.questions.length;
                this.surveyName = resObj.responseDetails.surveyName;
                this.instruction = resObj.responseDetails.instruction;
                this.surveyInviteId = this.questions[0].surveyInviteId;
                this.showWelcome = true;

                if (resObj.responseDetails.contactFirstName) {
                    this.pageTitle = 'Hello, ' + resObj.responseDetails.contactFirstName + '.';
                } else {
                    this.pageTitle = this.surveyName;
                }

                let currentStage = this.questions[0].stage;
                this.prepareScoringDetails();
                this.updateWithDefaultAnswers();
                if (currentStage == sentToRecipientStage || currentStage == partiallyCompletedStage) {
                    this.updateInProgress(guid);
                }
                if(resObj.responseDetails.hasOwnProperty('templateMetadata') 
                    && resObj.responseDetails.templateMetadata !=undefined    
                    && resObj.responseDetails.templateMetadata !='') {
                        var templateMetadata = resObj.responseDetails['templateMetadata'];
                        var templateMetadataObj = JSON.parse(templateMetadata);
                        var questionWrapperById = {};
                        for(var i=0;i<this.questions.length;i++) {
                            questionWrapperById[this.questions[i].surveyQuestionId] = this.questions[i]
                        }
                        console.log(questionWrapperById);
                        console.log(templateMetadataObj);
                        this.pageslist = [];
                        for(var i=0;i<templateMetadataObj.length;i++) {
                            var pageObj = templateMetadataObj[i];
                            var pageObjClone = this.cloneValue(pageObj);
                            for(var j=0;j<pageObj.sectionlist.length;j++) {
                                pageObjClone.sectionlist[j].questionWrapperList = [];
                                for(var k=0;k<pageObj.sectionlist[j].questionWrapperList.length;k++) {
                                    if(questionWrapperById.hasOwnProperty(pageObj.sectionlist[j].questionWrapperList[k].uid)) {
                                        pageObjClone.sectionlist[j].questionWrapperList.push(questionWrapperById[pageObj.sectionlist[j].questionWrapperList[k].uid]);
                                    }
                                }
                            }
                            this.pageslist.push(pageObjClone);
                        }
                        console.log(JSON.parse(JSON.stringify(this.pageslist)));
                }
            } else if (resObj.statusCode == '2100') {
                this.hanldeCatchBlock(resObj.responseMessage);
            }
        })
        .catch(error => {
            this.hanldeCatchBlock(error);
        });
    }

    cloneValue(inputObjectArra) {
        return JSON.parse(JSON.stringify(inputObjectArra));
    }

    prepareScoringDetails () {
        this.totalAvailableScore = 0;
        for (var i = 0; i < this.questions.length; i++) {
            
            if(this.questions[i].scoreConfirmed && this.questions[i].optionScore != null) {
                console.log(this.questions[i].optionScore);
                this.scoreByQuestionByOption[this.questions[i].surveyQuestionId] = JSON.parse(this.questions[i].optionScore);
                // var maxScore = 0 ;
                // var questionsValues = Object.keys(this.scoreByQuestionByOption[this.questions[i].surveyQuestionId]);
                // console.log(questionsValues);
                // for(var j=0; j< questionsValues.length;j++){
                //     console.log(this.scoreByQuestionByOption[this.questions[i].surveyQuestionId]);
                //     if(this.scoreByQuestionByOption[this.questions[i].surveyQuestionId].hasOwnProperty(questionsValues[j])
                //     && this.scoreByQuestionByOption[this.questions[i].surveyQuestionId][questionsValues[j]] > maxScore) {
                //         maxScore = this.scoreByQuestionByOption[this.questions[i].surveyQuestionId][questionsValues[j]];
                //     }
                // }
                // this.totalAvailableScore = this.totalAvailableScore + maxScore;
            }
        }
    }

    updateWithDefaultAnswers() {
        for (var i = 0; i < this.questions.length; i++) {
            if (this.questions[i].answer != undefined && this.questions[i].answer.length > 0) {
                const questionAnswer = this.questions[i].answer;;
                var question = this.questions[i];

                var answer = this.getAnswerWrapper(question, questionAnswer);
                answer.attainedScore = this.getObtainedScore(question.surveyQuestionId, answer.answer);
                this.answers[this.questions[i].surveyQuestionId] = answer;
            }
        }
        // this.result = JSON.stringify(this.answers);
    }
    getObtainedScore(surveyQuestionId, answerValue) {
        if(this.scoreByQuestionByOption.hasOwnProperty(surveyQuestionId) 
            && this.scoreByQuestionByOption[surveyQuestionId].hasOwnProperty(answerValue)) {
            return parseInt( this.scoreByQuestionByOption[surveyQuestionId][answerValue]);
        }
        return 0;
    }

    getQueryParameters(param) {
        return (new URL(window.location.href).searchParams.get(param));
    }

    getParameterByName(name, url) {
        if (!url) {
            url = window.location.href;
        }

        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) {
            return null;
        }
        if (!results[2]) {
            return '';
        }

        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    handleSubmit(event) {
        if(!this.performValidation()){
            return;
        }

        // this.startAnimation();
        this.showSpinner = true;
        this.disableSubmitBtn = true;
        this.saveAnswers();
    }

    uploadFiles(answerIdMap) {

        for (const [key, value] of Object.entries(this.files)) {
            
            this.numOfFilesToUpload = this.numOfFilesToUpload + 1;
            var fileCon = {};
            var surveyAnswerId = answerIdMap[key];
            if (this.answers[key].fieldType == 'Signature') {
                fileCon['name'] = this.answers[key].answer;
                fileCon['type'] = 'image/png';
                fileCon['signContent'] = value;

                this.saveSignature(fileCon, surveyAnswerId);
            } else {
                fileCon = value;
                this.saveFile(fileCon, surveyAnswerId);
            }

        }
    }
    resizeImageAndUpload(fileCon, event, self, surveyAnswerId) {
        var image = new Image();
        image.onload = function () {
            var width = image.width;
            var height = image.height;

            var canvas = document.createElement("canvas");
            canvas.width = width;
            canvas.height = height;

            var context = canvas.getContext("2d");
            context.msImageSmoothingEnabled = false;
            //context.drawImage(image, 0, 0, image.width, image.height, 0, 0, width, height);
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
            self.upload(fileCon, fileContents, surveyAnswerId);
        }
        image.src = event.target.result;
    }
    saveSignature(fileCon, surveyAnswerId) {
        var fileContents = fileCon.signContent;
        var base64Mark = 'base64,';
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        this.upload(fileCon, fileContents, surveyAnswerId);
    }

    saveFile(fileCon, surveyAnswerId) {
        // var fileCon = this.filesUploaded[0];

        var reader = new FileReader();
        var self = this;
        reader.onload = function (event) {
            if (imageFilterType.test(fileCon.type)) {
                self.resizeImageAndUpload(fileCon, event, self, surveyAnswerId);
            } else {
                var fileContents = reader.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                fileContents = fileContents.substring(dataStart);
                self.upload(fileCon, fileContents, surveyAnswerId);
            }
        };
        reader.readAsDataURL(fileCon);
    }

    upload(file, fileContents, surveyAnswerId) {
        if (fileContents.length > MAX_FILE_SIZE) {
            let message = 'File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + fileContents.length;
            this.hanldeCatchBlock(message);
            return;
        }
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);

        this.uploadChunk(file, fileContents, fromPos, toPos, '', surveyAnswerId);
    }

    uploadChunk(file, fileContents, fromPos, toPos, attachId, surveyAnswerId) {
        var chunk = fileContents.substring(fromPos, toPos);

        saveTheChunkFile({
            parentId: this.surveyInviteId,
            surveyAnswerId: surveyAnswerId,
            fileName: file.name,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId
        })
            .then(result => {

                attachId = result;
                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
                if (fromPos < toPos) {
                    this.uploadChunk(file, fileContents, fromPos, toPos, attachId, surveyAnswerId);
                } else {
                    this.numOfFilesUploaded = this.numOfFilesUploaded + 1;

                    if (this.numOfFilesUploaded == this.numOfFilesToUpload) {
                        this.showComplete = true;
                        this.showNextBtn = false;
                        this.showBackBtn = false;
                        this.isLastQuestion = false;    // hide the submit button
                        this.showSpinner = false;
                    }
                }
            })
            .catch(error => {
                console.error('Error: ', error);
                this.hanldeCatchBlock(error);
            })
            .finally(() => {

            })
    }

    formatBytes(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    performValidation() {
        var validValue = true;

        if(this.childComponentName != undefined && this.childComponentName.length > 1) {
            const currentQuestionChild = this.template.querySelector(this.childComponentName);
            validValue = (currentQuestionChild != undefined && currentQuestionChild != null) ? currentQuestionChild.isValidValue: true;
        }
        
        return validValue == undefined ? true: validValue; 
    }

    handleNext(event) {
        if(!this.performValidation()){
            return;
        }
        // this.selectedpage 
        // this.currentIndex++;
        // this.currentQuestion = this.questions[this.currentIndex];
        // this.isLastQuestion = (this.currentIndex + 1 == this.questions.length);
        // this.isFirstQuestion = (this.currentIndex < 1);
        // this.pageTitle = this.surveyName;  // update page title;
        // this.pageTitleClass = 'slds-text-heading_medium';
        // this.showQuestionComponent(this.currentQuestion, this.currentIndex, this.questions.length);

        this.currentPageIndex++;
        this.currentPageDisplayIndex = this.currentPageIndex + 1;
        this.totalPageNo = this.pageslist.length;
        this.currentpageprogress = (this.currentPageDisplayIndex * 100)/this.totalPageNo;
        this.selectedpage = this.pageslist[this.currentPageIndex];
        this.isLastQuestion = (this.currentPageIndex + 1 == this.totalPageNo);
        this.isFirstQuestion = (this.currentPageIndex < 1);
        this.pageTitle = this.surveyName;  // update page title;
        this.pageTitleClass = 'slds-text-heading_medium';
        
        this.showQuestionComponent(this.selectedpage, this.currentPageIndex, this.totalPageNo);

        this.startAnimation();
    }

    handleBack(event) {
        // this.currentIndex--;
        // this.currentQuestion = this.questions[this.currentIndex];
        // this.isLastQuestion = (this.currentIndex + 1 == this.questions.length);
        // this.isFirstQuestion = (this.currentIndex < 1);
        // this.showQuestionComponent(this.currentQuestion, this.currentIndex, this.questions.length);

        this.currentPageIndex--;
        this.currentPageDisplayIndex = this.currentPageIndex + 1;
        this.totalPageNo = this.pageslist.length;
        this.currentpageprogress = (this.currentPageDisplayIndex * 100)/this.totalPageNo;

        this.selectedpage = this.pageslist[this.currentPageIndex];
        this.isLastQuestion = (this.currentPageIndex + 1 == this.totalPageNo);
        this.isFirstQuestion = (this.currentPageIndex < 1);
        this.showQuestionComponent(this.selectedpage, this.currentPageIndex, this.totalPageNo);

        this.startAnimation();
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

    saveAnswers() {
        saveAnswers({
            surveyGUID: this.getQueryParameters('seqnum'),
            answerJsonString: JSON.stringify(this.answers)
        })
            .then(result => {

                var resObj = JSON.parse(result);

                if (resObj.statusCode == '2000') {

                    if (Object.entries(this.files).length > 0) {
                        // uploading files
                        var answerIdMap = resObj.responseDetails;
                        this.uploadFiles(answerIdMap);
                    } else {
                        this.showComplete = true;
                        this.showNextBtn = false;
                        this.showBackBtn = false;
                        this.isLastQuestion = false;
                        this.showSpinner = false;
                    }
                } else if (resObj.statusCode == '2100') {
                    console.log('error!!!!!!!!!!!');
                    this.hanldeCatchBlock(resObj.responseMessage);
                }

            })
            .catch(error => {
                console.log(error);
                this.hanldeCatchBlock(error);
            });
    }

    showQuestionComponent(currentQuestion, currentPageIndex, totalNumber) {
        // if (currentIndex == 0) {
        //     this.showNextBtn = (totalNumber == 1 ? false : true);
        //     this.showBackBtn = false;
        //     this.showWelcome = false;
        //     this.showQuestionProgress = true;
        // } else {
        //     this.showNextBtn = ((currentIndex + 1 == totalNumber || this.showWelcome) ? false : true);
        //     this.showBackBtn = true;
        // }
        if (currentPageIndex == 0) {
            this.showNextBtn = (totalNumber == 1 ? false : true);
            this.showBackBtn = false;
            this.showWelcome = false;
            this.showQuestionProgress = true;
        } else {
            this.showNextBtn = ((currentPageIndex + 1 == totalNumber || this.showWelcome) ? false : true);
            this.showBackBtn = true;
        }
    }

    handleValueChanged(event) {
        //const index = event.detail.index;
        const questionAnswer = event.detail.answer;
        var question = event.detail.question;
        var answer = this.getAnswerWrapper(question, questionAnswer);
        if(answer.answer != undefined && answer.answer != null && ((answer.answer)+'').length > 0) {
            this.answers[question.surveyQuestionId] = answer;
        } else {
            delete this.answers[question.surveyQuestionId];
        }

        this.result = JSON.stringify(this.answers);
    }

    getAnswerWrapper(question, questionAnswer) {
        var answer = {};
        answer.index = question.index;
        answer.surveyQuestionId = question.surveyQuestionId;
        answer.questionId = question.questionId;
        answer.questionDetails = question.questionDetails;
        answer.fieldType = question.fieldType;
        answer.questionValues = question.questionValues;
        if (answer.fieldType == 'File') {
            answer.answer = questionAnswer.name;
            // answer.file = questionAnswer;
            this.files[question.surveyQuestionId] = questionAnswer;
            this.updateQuestion(question, questionAnswer.name);
        } else if (answer.fieldType == 'Signature') {
            answer.answer = '';
            delete this.files[question.surveyQuestionId];
            if(questionAnswer != undefined && questionAnswer != null && questionAnswer.length > 0) {
                answer.answer = 'Signature_' + question.surveyInviteId + '_' + question.surveyQuestionId + '.png';
                this.files[question.surveyQuestionId] = questionAnswer;
            }
            // answer.file = questionAnswer;
            this.updateQuestion(question, answer.answer);
        } else {
            answer.answer = questionAnswer;
            answer.attainedScore = this.getObtainedScore(question.surveyQuestionId, answer.answer);
            this.updateQuestion(question, questionAnswer);
        }
       
        return answer;
    }

    updateQuestion(q, answer) {
        // this.totalScore = 0;
        for (var i = 0; i < this.questions.length; i++) {
            if (this.questions[i].index == q.index 
                && this.questions[i].surveyQuestionId == q.surveyQuestionId) {
                this.questions[i].answer = answer;
                this.totalScore = this.totalScore + ((answer != undefined && answer.attainedScore) || 0);
                break;
            }
        }
    }

}