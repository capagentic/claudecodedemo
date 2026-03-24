import { api, LightningElement, track } from 'lwc';

export default class TbInspQuestionDependant extends LightningElement {

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
    @track showSalesforceField = false;
    @track showCaptureAudio = false;
    @track showYesNo = false;
    @track showComplientNonCompliant = false;
    @track showBarcodeScanner = false;
    @track showSalesforceFlow = false;

    @track showDependantQuestion = false;

    childComponentName = '';
    @api
    files = {};

    connectedCallback() {
    }

    _currentQuestion
    @api
    get currentQuestion() {
        return this._currentQuestion;
    }
    set currentQuestion(value) {
        this._currentQuestion = value;
        this.showQuestionComponent(value);
    }

    showQuestionComponent(currentQuestion) {
        this.childComponentName = '';
        this.showRadio = false;
        if ((currentQuestion.fieldType == 'Radio Button')) {
            this.showRadio = true;
            //this.childComponentName = 'c-tb-insp-question-radio-ng'
        }
        this.showText = false;
        if ((currentQuestion.fieldType == 'Text')) {
            this.showText = true;
            //this.childComponentName = 'c-tb-insp-question-text-n-g';
        }
        this.showTextArea = false;
        if ((currentQuestion.fieldType == 'Text Area')) {
            this.showTextArea = true;
            //this.childComponentName = 'c-tb-insp-question-text-area-n-g';
        }
        this.showFile = false;
        if ((currentQuestion.fieldType == 'File')) {
            this.showFile = true;
            //this.childComponentName = 'c-tb-insp-question-file-upload-n-g';
        }

        this.showRating = false;
        if ((currentQuestion.fieldType == 'Rating')) {
            this.showRating = true;
            //this.childComponentName = 'c-tb-insp-question-star-rating-n-g';
        }

        this.showNPS = false;
        if ((currentQuestion.fieldType == 'Net Promoter Score')) {
            this.showNPS = true;
            //this.childComponentName = 'c-tb-insp-question-n-p-s-n-g';
        }

        this.showGeoLocation = false;
        if ((currentQuestion.fieldType == 'Geo Location')) {
            this.showGeoLocation = true;
            //this.childComponentName = 'c-tb-insp-question-geo-location-n-g';
        }

        this.showNum = false;
        if ((currentQuestion.fieldType == 'Number')) {
            this.showNum = true;
            //this.childComponentName = 'c-tb-insp-question-number-n-g';
        }

        this.showMultiChoice = false;
        if ((currentQuestion.fieldType == 'Checkbox')) {
            this.showMultiChoice = true;
            //this.childComponentName = 'c-tb-insp-question-multi-choice-n-g';
        }

        this.showEmail = false;
        if ((currentQuestion.fieldType == 'Email')) {
            this.showEmail = true;
            this.childComponentName = 'c-tb-insp-question-email-n-g';
        }

        this.showUrl = false;
        if ((currentQuestion.fieldType == 'URL')) {
            this.showUrl = true;
            this.childComponentName = 'c-tb-insp-question-url-n-g';
        }

        this.showCurrency = false;
        if ((currentQuestion.fieldType == 'Currency')) {
            this.showCurrency = true;
            this.childComponentName = 'c-tb-insp-question-currency-n-g';
        }

        this.showPercentage = false;
        if ((currentQuestion.fieldType == 'Percentage')) {
            this.showPercentage = true;
            this.childComponentName = 'c-tb-insp-question-percentage-n-g';
        }

        this.showDate = false;
        if ((currentQuestion.fieldType == 'Date')) {
            this.showDate = true;
            this.childComponentName = 'c-tb-insp-question-date-n-g';
        }

        this.showDateTime = false;
        if ((currentQuestion.fieldType == 'Date & Time')) {
            this.showDateTime = true;
            this.childComponentName = 'c-tb-insp-question-date-time-n-g';
        }

        this.showSignature = false;
        if ((currentQuestion.fieldType == 'Signature')) {
            this.showSignature = true;
            //this.childComponentName = 'c-tb-insp-question-signature-n-g';
        }
        this.showPassFail = false;
        if ((currentQuestion.fieldType == 'Pass Fail')) {
            this.showPassFail = true;
            //this.childComponentName = 'c-tb-insp-question-pass-fail-n-g';
        }
        //trying to reuse the radio button quedtion type for this type as it is exct similar
        this.showYesNo = false;
        if ((currentQuestion.fieldType == 'Yes No')) {
            this.showYesNo = true;
            //this.childComponentName = 'c-tb-insp-question-radio-ng'
        }
        //trying to reuse the radio button quedtion type for this type as it is exct similar
        this.showComplientNonCompliant = false;
        if ((currentQuestion.fieldType == 'Compliant Non Compliant')) {
            this.showComplientNonCompliant = true;
            //this.childComponentName = 'c-tb-insp-question-radio-ng'
        }
        this.showSalesforceField = false;
        if ((currentQuestion.fieldType == 'Salesforce Field')) {
            this.showSalesforceField = true;
            //this.childComponentName = 'c-tb-insp-question-salesforce-field-n-g';
        }
        this.showCaptureAudio = false;
        if ((currentQuestion.fieldType == 'Voice Memo')) {
            this.showCaptureAudio = true;
            //this.childComponentName = 'c-tb-insp-question-audio-capture-n-g';
        }
        this.showBarcodeScanner = false;
        if ((currentQuestion.fieldType == 'Barcode Scan')) {
            this.showBarcodeScanner = true;
            //this.childComponentName = 'c-tb-insp-question-barcode-scanner-n-g';
        }
        this.showSalesforceFlow = false;
        if ((currentQuestion.fieldType == 'Salesforce Flow')) {
            this.showSalesforceFlow = true;
        }
    }

    handleValueChanged(event) {
        const questionAnswer = event.detail.answer;
        var currentQuestion = event.detail.question || this.currentQuestion;
        currentQuestion = JSON.parse(JSON.stringify(currentQuestion));
        currentQuestion.answer = questionAnswer;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.currentQuestion.index, answer: questionAnswer, question: currentQuestion }
        });
        this.dispatchEvent(valueChangeEvent);

        // if (currentQuestion.dependantQuestions) {
        //     for (var ans in currentQuestion.dependantQuestions) {
        //         if (currentQuestion.answer == ans) {
        //             this.handleShowDependantQuestion(currentQuestion.dependantQuestions[ans]);
        //             this.showDependantQuestion = true;
        //         }
        //     }
        // }
    }

}