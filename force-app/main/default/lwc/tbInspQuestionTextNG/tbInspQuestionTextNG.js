import { api, LightningElement } from 'lwc';

export default class TbInspQuestionTextNG extends LightningElement {

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

    handleOnblur(event) {
        console.log('handleOnblur');
        const onblurEvent = new CustomEvent('questiononblur', {
            detail: { index: this.question.index, question: this.question }
        });
        this.dispatchEvent(onblurEvent);
    }
}