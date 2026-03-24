import { LightningElement, api } from 'lwc';

export default class InspQuestionNPS extends LightningElement {
    @api question = {};
    @api maxNumber = 9;
    options = [];


    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        //this.initQuestion();
    }

    connectedCallback() {
        this.options = [];
        for (var i = 0; i <= this.maxNumber; i++) {
            var option = {}
            option.label = String(i);
            option.value = String(i);
            //option.checked = (i + 1 == this.question.answer);
            this.options.push(option);
        }
    }

    initQuestion() {
        // var optionValues = this.question.questionValues.split(',');
        this.options = [];
        for (var i = 0; i < 10; i++) {
            var option = {}
            option.label = i + 1;
            option.value = i + 1;
            option.checked = (i + 1 == this.question.answer);
            this.options.push(option);
        }
    }

    handleChange(event) {
        console.log(event.detail.value);
        const selectedValue = event.detail.value;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}