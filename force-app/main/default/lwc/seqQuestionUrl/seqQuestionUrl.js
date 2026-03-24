import { LightningElement, api } from 'lwc';

export default class SeqQuestionUrl extends LightningElement {

    @api question = {};

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }

    @api get isValidValue() {
        var inputField = this.template.querySelector('lightning-input');
        inputField.reportValidity();
        var isValidValue = inputField.checkValidity();
        return isValidValue;
    }

    handleChange(event) {
        console.log('Url handleChange..');
        const selectedValue = event.detail.value;
       
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}