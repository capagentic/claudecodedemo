import { api, LightningElement } from 'lwc';

export default class TbInspQuestionPassFailNG extends LightningElement {
    //@api question = {};
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
        var optionValues = this.cloneValue(this.question.questionValues);
        var triggerAnswers = [];
        // if(this.question.flows){
        //     triggerAnswers = this.getTriggerAnswers(this.question.flows);
        // }

        this.options = [];
        for (var i = 0; i < optionValues.length; i++) {
            var option = optionValues[i];
            option['questionId'] = this.question.questionId;
            option['label'] = option.value;
            option['styleAtt'] = '';
            option['checked'] = (optionValues[i].value.trim() == this.question.answer) || false;
            if (option.checked) {
                option.styleAtt = 'background:' + option.color + ' !important; color: white;';
            }

            option['showBtnIcon'] = this.question.flows && this.question.flows[option.value];
            this.options.push(option);
        }
    }

    // getTriggerAnswers(flows){
    //     var ansList = [];
    //     for(anw in ){

    //     }
    // }

    handleOptionSelected(event) {
        const selectedValue = event.target.value;
        var options = this.cloneValue(this.options);
        for (var i = 0; i < options.length; i++) {
            options[i].styleAtt = '';
            if (options[i].value === selectedValue) {
                options[i].styleAtt = 'background:' + options[i].color + ' !important; color: white;';
            }
        }
        this.options = options;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}