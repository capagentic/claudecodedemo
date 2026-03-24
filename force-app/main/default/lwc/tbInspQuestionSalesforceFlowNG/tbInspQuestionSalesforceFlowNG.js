import { LightningElement, api, track } from 'lwc';

export default class TbInspQuestionSalesforceFlowNG extends LightningElement {

    @api question = {};
    @track flowname;
    @api inputVariables = [];

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }
    @api get isValidValue() {
        // var inputField = this.template.querySelector('lightning-input');
        // inputField.reportValidity();
        // var isValidValue = inputField.checkValidity();
        // return isValidValue;
        return true;
    }
    get ifAlreadyAnswered() {
        return this.isValidValue(this.question.answer);
    }

    connectedCallback() {
        console.log(JSON.stringify(this.question));
        this.flowname = this.question.flowName;
        var answerrecordId = this.question.existingAnswerId || '';
        this.inputVariables = [
            {
                name: 'answerRecordId',
                type: 'String',
                value: answerrecordId
            }];
    }

    handleChange(answerValue) {
        var answerValueLocal = this.flowname + ' Flow is completed and the output is - ';
        answerValueLocal = answerValueLocal + answerValue;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: answerValueLocal, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            title: title || 'Salesforce Flow',
            variant: variant || 'success',
            message: message || '',
        });
        this.dispatchEvent(event);
    }
    
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // set behavior after a finished flow interview
            console.log(JSON.stringify(event.detail));
            const outputVariables = event.detail.outputVariables;
            var answerValue = JSON.stringify(outputVariables);
            this.handleChange(answerValue);
        }
    }
}