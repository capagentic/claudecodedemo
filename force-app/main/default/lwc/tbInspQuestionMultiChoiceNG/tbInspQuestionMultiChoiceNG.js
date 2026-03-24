import { LightningElement, api } from 'lwc';

export default class TbInspQuestionMultiChoiceNG extends LightningElement {
    @api readOnly = false;
    options = [];
    currentquestion = {};

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        this.initQuestion();
    }
    _question;
    @api
    get question() {
        return this._question;
    }
    set question(value) {
        this._question = value;
        this.initQuestion();
    }

    connectedCallback() {
    }

    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }
    initQuestion() {
        this.currentquestion = this.cloneValue(this.question);
        var optionValues = this.currentquestion.questionValues;
        this.options = [];
        for (var i = 0; i < optionValues.length; i++) {
            var option = optionValues[i];
            option['questionId'] = this.question.questionId;
            option['label'] = option.value;
            option['styleAtt'] = '';//'background-color:'+option.color;
            option['checked'] = (this.isValueSelected(option.value, this.question.answer));
            if (option.checked) {
                option.styleAtt = 'background:' + option.color + ' !important; color: white;';
            }
            this.options.push(option);
        }
        this.currentquestion.questionValues = this.options;
    }

    isValueSelected(optionValue, answers) {
        var checked = false;
        if (answers) {
            var answerArray = answers.split(';');
            for (var i = 0; i < answerArray.length; i++) {
                if (optionValue == answerArray[i]) {
                    checked = true;
                }
            }
        }
        return checked;
    }
    handleOptionSelected(event) {
        if (this.readOnly) {
            return;
        }
        var questionlocal = this.cloneValue(this.currentquestion);
        var optionValues = questionlocal.questionValues;
        this.options = [];
        var clickedValue = event.target.value;
        var finalAnswers = '';
        for (var i = 0; i < optionValues.length; i++) {
            // toggle the style	
            var option = optionValues[i];
            if (option.value == clickedValue) {
                option.checked = !option.checked;
            }
            // add the value clicked to the answers	
            option.styleAtt = '';
            if (option.checked) {
                finalAnswers = finalAnswers + option.value + ';'
                option.styleAtt = 'background:' + option.color + ' !important; color: white;';
            }
            this.options.push(option);
        }

        questionlocal.questionValues = this.options;
        //this.question = questionlocal;
        this.currentquestion = questionlocal;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: finalAnswers, question: questionlocal }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}