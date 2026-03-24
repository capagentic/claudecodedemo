import { api, LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TbTemplatePreviewContainerOnTemplate extends LightningElement {

    @track templatePageMetadata = {};
    @api recordId;
    @track newTemplateFound = true;

    @wire(getRecord, {
        recordId: '$recordId', fields: ['Kinetics__Kinetic_Form__c.Name', 'Kinetics__Kinetic_Form__c.Kinetics__Instructions__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Status__c', 'Kinetics__Kinetic_Form__c.Kinetics__Questions_By_Page_No__c',
            'Kinetics__Kinetic_Form__c.Kinetics__Section_Metadata__c', 'Kinetics__Kinetic_Form__c.Kinetics__Template_Metadata__c']
    })
    templateformrecord({ error, data }) {
        if (data) {
            this.loadRecord(data);
        }
        if (error) {
            this.showErrorMessage(error);
        }
    }

    loadRecord(existingRecord) {
        // this.resetToDefaults();
        this.templatePageMetadata.selectedFormValue = {
            'Name': '',
            'Kinetics__Instructions__c': '',
            'Kinetics__Status__c': 'Active',
            'Kinetics__Questions_By_Page_No__c': '{}',
            'Kinetics__Section_Metadata__c': '{}',
            'Kinetics__Template_Metadata__c': '{}'
        };
        this.templatePageMetadata.selectedFormValue.Name = existingRecord.fields.Name.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Instructions__c = existingRecord.fields.Kinetics__Instructions__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Status__c = existingRecord.fields.Kinetics__Status__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Questions_By_Page_No__c = existingRecord.fields.Kinetics__Questions_By_Page_No__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Section_Metadata__c = existingRecord.fields.Kinetics__Section_Metadata__c.value;
        this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c = existingRecord.fields.Kinetics__Template_Metadata__c.value;
        //this needs to be changed
        this.newTemplateFound = false;
        if (this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != undefined
            && this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != ''
            && this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c != null) {
            this.newTemplateFound = true;
            this.templatePageMetadata.pagelist = JSON.parse(this.templatePageMetadata.selectedFormValue.Kinetics__Template_Metadata__c);//.replaceAll('\\', ''));
        }
        this.templatePageMetadata.ispreviewshown = true;
        this.updateLastModifiedMetadata();
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
    updateLastModifiedMetadata() {
        console.log(JSON.parse(JSON.stringify(this.templatePageMetadata)));
        //this is done to have one place from where the changes are broadcasted, so that child component get the updated version
        this.templatePageMetadata = JSON.parse(JSON.stringify(this.templatePageMetadata));
    }
    @track answers = {};
    updateQuestionAnswer(event) {
        var question = event.detail.question;
        var questionAnswer = event.detail.questionAnswer;
        var answer = this.getAnswerWrapper(question, questionAnswer);

        if (answer.answer != undefined && answer.answer != null && answer.answer.length > 0) {
            this.answers[question.templateQuestionId] = answer;
        } else {
            delete this.answers[question.templateQuestionId];
        }

        // this.calculateScore();
        this.templatePageMetadata.answers = this.answers;

        // update show dependant question flag based on the event from the child
        for (var i = 0; i < this.templatePageMetadata.pagelist.length; i++) {
            for (var j = 0; j < this.templatePageMetadata.pagelist[i].sectionlist.length; j++) {
                for (var k = 0; k < this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList.length; k++) {
                    var quest = this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k];
                    if (quest.uid == question.questionId) {
                        quest.showDependantQuestion = question.showDependantQuestion;
                        quest.currentDependantQuestion = question.currentDependantQuestion;
                        this.templatePageMetadata.pagelist[i].sectionlist[j].questionWrapperList[k] = quest;
                        break;
                    }
                }
            }
        }
        this.updateLastModifiedMetadata();
    }

    updateLastModifiedMetadata() {
        //this is done to have one place from where the changes are broadcasted, so that child component get the updated version
        this.templatePageMetadata = JSON.parse(JSON.stringify(this.templatePageMetadata));
        this.showSpinner = false;
    }

    getAnswerWrapper(question, questionAnswer) {
        var answer = {};
        answer.index = question.index;
        answer.templateQuestionId = question.templateQuestionId;
        answer.questionId = question.questionId;
        answer.questionDetails = question.questionDetails;
        answer.fieldType = question.fieldType;
        answer.questionValues = question.questionValues;
        answer.inspectionId = (this.inspectionRec && this.inspectionRec.Id) ? this.inspectionRec.Id : null;
        answer.inspectionTemplateId = (this.templateRec && this.templateRec.Id) ? this.templateRec.Id : null;
        answer.existingAnswerId = question.existingAnswerId;
        answer.chatgptguidance = question.chatgptguidance;

        if (answer.fieldType == 'File') {
            answer.answer = questionAnswer.name;
            this.files[question.templateQuestionId] = questionAnswer;
            // this.updateQuestion(question, questionAnswer.name);
        } else if (answer.fieldType == 'Signature') {
            answer.answer = '';
            delete this.files[question.templateQuestionId];
            if (questionAnswer != undefined && questionAnswer != null && questionAnswer.length > 0) {
                answer.answer = 'Signature_' + this.inspectionRec.Id + '_' + question.templateQuestionId + '.png';
                this.files[question.templateQuestionId] = questionAnswer;
            }
            // answer.file = questionAnswer;
            // this.updateQuestion(question, answer.answer);
        } else {
            answer.answer = questionAnswer;
            // this.updateQuestion(question, questionAnswer);
        }
        return answer;
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