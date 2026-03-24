import { LightningElement, api } from 'lwc';

export default class InspQuestionMultiChoice extends LightningElement {
    @api question = {};
    options = [];
    @api readOnly = false;

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        this.initQuestion();
    }

    connectedCallback() {
    }

    initQuestion() {
        var optionValues = this.question.questionValues.split(',');
        this.options = [];
        for (var i = 0; i < optionValues.length; i++) {
            var option = {}
            option.questionId = this.question.questionId;
            option.label = optionValues[i].trim();
            option.value = optionValues[i].trim();
            option.checked = this.isValueSelected(optionValues[i].trim(), this.question.answer);
            this.options.push(option);
        }
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

        var clickedValue = event.currentTarget.value;
        var finalAnswers = '';
        for (var i = 0; i < this.options.length; i++) {
            // toggle the style	
            if (this.options[i].value == clickedValue) {
                this.options[i].checked = !this.options[i].checked;
            }
            // add the value clicked to the answers	
            if (this.options[i].checked) {
                finalAnswers = finalAnswers + this.options[i].value + ';'
            }
        }

        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: finalAnswers, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}