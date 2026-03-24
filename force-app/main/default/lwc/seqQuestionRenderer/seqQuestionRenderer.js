import { LightningElement, api, track } from 'lwc';

export default class SeqQuestionRenderer extends LightningElement {

    // question type visibility
    @track showRadio = false;
    @track showText = false;
    @track showTextArea = false;
    @track showFile = false;
    @track showRating = false;
    @track showNPS = false;
    @track showGeoLocation = false;
    @track showNum = false;
    @track showMultiChoice = false;
    @track showEmail = false;
    @track showUrl = false;
    @track showCurrency = false;
    @track showPercentage = false;
    @track showDate = false;
    @track showDateTime = false;
    @track showSignature = false;
    @track showCalendly = false;
    @track showStripe = false;
    @track showPassFail = false;

    childComponentName = '';

    @api currentQuestion;
    
    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        this.initQuestion();
    }
    initQuestion() {
        this.childComponentName = '';
        this.showRadio = false;
        if((this.currentQuestion.fieldType == 'Radio Button')) {
            this.showRadio = true;
            //this.childComponentName = 'c-seq-question-radio'
        }
        this.showText = false;
        if((this.currentQuestion.fieldType == 'Text')) {
            this.showText = true;
            //this.childComponentName = 'c-seq-question-text';
        }
        this.showTextArea = false;
        if((this.currentQuestion.fieldType == 'Text Area')) {
            this.showTextArea = true;
            //this.childComponentName = 'c-seq-question-text-area';
        }
        this.showFile = false;
        if((this.currentQuestion.fieldType == 'File')){
            this.showFile = true;
            //this.childComponentName = 'c-seq-question-file-upload';
        }

        this.showRating = false;
        if((this.currentQuestion.fieldType == 'Rating')) {
            this.showRating = true;
            //this.childComponentName = 'c-seq-question-star-rating';
        }

        this.showNPS = false;
        if((this.currentQuestion.fieldType == 'Net Promoter Score')){
            this.showNPS = true;
            //this.childComponentName = 'c-seq-question-n-p-s';
        }

        this.showGeoLocation = false;
        if((this.currentQuestion.fieldType == 'Geo Location')){
            this.showGeoLocation = true;
            //this.childComponentName = 'c-seq-geo-location';
        }

        this.showNum = false;
        if((this.currentQuestion.fieldType == 'Number')){
            this.showNum = true;
            //this.childComponentName = 'c-seq-question-number';
        }

        this.showMultiChoice = false;
        if((this.currentQuestion.fieldType == 'Checkbox')){
            this.showMultiChoice = true;
            //this.childComponentName = 'c-seq-question-multi-choice';
        }

        this.showEmail = false;
        if((this.currentQuestion.fieldType == 'Email')){
            this.showEmail = true;
            this.childComponentName = 'c-seq-question-email';
        }

        this.showUrl = false;
        if((this.currentQuestion.fieldType == 'URL')){
            this.showUrl = true;
            this.childComponentName = 'c-seq-question-url';
        }

        this.showCurrency = false;
        if((this.currentQuestion.fieldType == 'Currency')){
            this.showCurrency = true;
            this.childComponentName = 'c-seq-question-currency';
        }

        this.showPercentage = false;
        if((this.currentQuestion.fieldType == 'Percentage')){
            this.showPercentage = true;
            this.childComponentName = 'c-seq-question-percentage';
        }

        this.showDate = false;
        if((this.currentQuestion.fieldType == 'Date')){
            this.showDate = true;
            this.childComponentName = 'c-seq-question-date';
        }

        this.showDateTime = false;
        if((this.currentQuestion.fieldType == 'Date & Time')){
            this.showDateTime = true;
            this.childComponentName = 'c-seq-question-date-time';
        }

        this.showSignature = false;
        if((this.currentQuestion.fieldType == 'Signature')){
            this.showSignature = true;
            //this.childComponentName = 'c-seq-question-signature';
        }

        this.showCalendly = false;
        if((this.currentQuestion.fieldType == 'Calendly')) {
            this.showCalendly = true;
            //this.childComponentName = 'c-seq-question-calendly';
        }

        this.showStripe = false;
        if((this.currentQuestion.fieldType == 'Stripe')) {
            this.showStripe = true;
            //this.childComponentName = 'c-seq-question-stripe';
        }
        this.showPassFail = false;
        if((this.currentQuestion.fieldType == 'Pass Fail')) {
            this.showPassFail = true;
            //this.childcomponentName = 'c-seq-question-pass-fail;
        }
    }

    handleValueChanged(event) {
        //const index = event.detail.index;
        const questionAnswer = event.detail.answer;
        var question = event.detail.question;
        
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: question.index, answer: questionAnswer, question: question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}