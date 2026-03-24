import { LightningElement, api, track } from 'lwc';

export default class TbTemplatePreviewerNG extends LightningElement {
    _templatePageMetadata
    @api
    set templatePageMetadata(value) {
        var valueLocal = JSON.parse(JSON.stringify(value));
        valueLocal['ispreviewshown'] = true;
        this._templatePageMetadata = valueLocal;
    }
    get templatePageMetadata() {
        return this._templatePageMetadata;
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


}