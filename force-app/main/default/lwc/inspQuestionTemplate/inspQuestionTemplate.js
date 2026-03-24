import { api, LightningElement, track } from 'lwc';

export default class InspQuestionTemplate extends LightningElement {
    @api currentQuestion;
    @api inspectionRec;
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


    connectedCallback() {
        this.showQuestionComponent(this.currentQuestion);
    }

    showQuestionComponent(currentQuestion) {
        this.childComponentName = '';
        this.showRadio = false;
        if((currentQuestion.fieldType == 'Radio Button')) {
            this.showRadio = true;
            //this.childComponentName = 'c-insp-question-radio'
        }
        this.showText = false;
        if((currentQuestion.fieldType == 'Text')) {
            this.showText = true;
            //this.childComponentName = 'c-insp-question-text';
        }
        this.showTextArea = false;
        if((currentQuestion.fieldType == 'Text Area')) {
            this.showTextArea = true;
            //this.childComponentName = 'c-insp-question-text-area';
        }
        this.showFile = false;
        if((currentQuestion.fieldType == 'File')){
            this.showFile = true;
            //this.childComponentName = 'c-insp-question-file-upload';
        }

        this.showRating = false;
        if((currentQuestion.fieldType == 'Rating')) {
            this.showRating = true;
            //this.childComponentName = 'c-insp-question-star-rating';
        }

        this.showNPS = false;
        if((currentQuestion.fieldType == 'Net Promoter Score')){
            this.showNPS = true;
            //this.childComponentName = 'c-insp-question-n-p-s';
        }

        this.showGeoLocation = false;
        if((currentQuestion.fieldType == 'Geo Location')){
            this.showGeoLocation = true;
            //this.childComponentName = 'c-insp-question-geo-location';
        }

        this.showNum = false;
        if((currentQuestion.fieldType == 'Number')){
            this.showNum = true;
            //this.childComponentName = 'c-insp-question-number';
        }

        this.showMultiChoice = false;
        if((currentQuestion.fieldType == 'Checkbox')){
            this.showMultiChoice = true;
            //this.childComponentName = 'c-insp-question-multi-choice';
        }

        this.showEmail = false;
        if((currentQuestion.fieldType == 'Email')){
            this.showEmail = true;
            this.childComponentName = 'c-insp-question-email';
        }

        this.showUrl = false;
        if((currentQuestion.fieldType == 'URL')){
            this.showUrl = true;
            this.childComponentName = 'c-insp-question-url';
        }

        this.showCurrency = false;
        if((currentQuestion.fieldType == 'Currency')){
            this.showCurrency = true;
            this.childComponentName = 'c-insp-question-currency';
        }

        this.showPercentage = false;
        if((currentQuestion.fieldType == 'Percentage')){
            this.showPercentage = true;
            this.childComponentName = 'c-insp-question-percentage';
        }

        this.showDate = false;
        if((currentQuestion.fieldType == 'Date')){
            this.showDate = true;
            this.childComponentName = 'c-insp-question-date';
        }

        this.showDateTime = false;
        if((currentQuestion.fieldType == 'Date & Time')){
            this.showDateTime = true;
            this.childComponentName = 'c-insp-question-date-time';
        }

        this.showSignature = false;
        if((currentQuestion.fieldType == 'Signature')){
            this.showSignature = true;
            //this.childComponentName = 'c-insp-question-signature';
        }
        this.showPassFail = false;
        if((currentQuestion.fieldType == 'Pass Fail')){
            this.showPassFail = true;
        }
    }

    handleValueChanged(event) {
        const questionAnswer = event.detail.answer;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.currentQuestion.index, answer: questionAnswer, question: this.currentQuestion }
        });
        this.dispatchEvent(valueChangeEvent);                                                     
    }
}