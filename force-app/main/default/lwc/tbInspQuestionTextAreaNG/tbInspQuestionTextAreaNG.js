import { LightningElement, api } from 'lwc';

export default class TbInspQuestionTextAreaNG extends LightningElement {

    @api question = {};
    @api readOnly = false;

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }

    handleChange(event) {
        console.log('text handleChange..');
        const selectedValue = event.detail.value;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}