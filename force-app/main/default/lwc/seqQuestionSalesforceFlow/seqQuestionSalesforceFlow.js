import { LightningElement, api, track } from 'lwc';

export default class SeqQuestionSalesforceFlow extends LightningElement {

    @api question = {};
    @track flowname;
    @api inputVariables = [];
    @api islastquestion= false;
    @api seqnumber = '';

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

    get ifQuestionAlreadyAnswered () {
        console.log('this.question.answer: ' + this.question.answer);
        return this.isvalidValue(this.question.answer);
    }

    isvalidValue (value) {
        return (value != '' && value != undefined && value != null);
    }

    get showFlow() {
        return !this.ifQuestionAlreadyAnswered && this.isvalidValue(this.flowname);
    }
  
    connectedCallback() {
       // console.log(JSON.stringify(this.question));
        this.flowname = this.question.flowName;
        var answerrecordId = this.question.existingAnswerId || '';
        this.inputVariables = [
            {
                name: 'answerRecordId',
                type: 'String',
                value: answerrecordId
            },
            {
                name: 'seqnumber',
                type: 'String',
                value: this.seqnumber
            }
        ];
    }

    handleChange(answerValue) {
        console.log('before dispatchEvent done - in flow lwc');
        var answerValueLocal = this.flowname + ' Flow is completed and the output is - ';
        answerValueLocal = answerValueLocal + answerValue;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: answerValueLocal, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
        console.log('after dispatchEvent done - in flow lwc');
        if(this.islastquestion) {
            //if this current question is last question then invoke submit button methods.
            const flowSubmitEvent = new CustomEvent('flowsubmit', {
                detail: { index: this.question.index, answer: answerValueLocal, question: this.question }
            });
            this.dispatchEvent(flowSubmitEvent);
        }
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
           // console.log(JSON.stringify(event.detail));
            const outputVariables = event.detail.outputVariables;
            var answerValue = JSON.stringify(outputVariables);
            this.handleChange(answerValue);
        }
    }
}