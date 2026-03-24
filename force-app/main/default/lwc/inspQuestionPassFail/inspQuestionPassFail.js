import { api, LightningElement } from 'lwc';

export default class InspQuestionPassFail extends LightningElement {
    @api question = {};
    options = [];

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
            option.checked = (optionValues[i].trim() == this.question.answer);
            this.options.push(option);
        }
    }

    handleOptionSelected(event) {
        const selectedValue = event.currentTarget.value;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}