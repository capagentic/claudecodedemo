import { api, LightningElement, track } from 'lwc';

export default class TbQuestionOptionsPopup extends LightningElement {

    @api currentquestion;
    @track hasRendered = false;
    isPassFailQuestion = false;
    @track errormessage = undefined;

    colors = ["#ea001e", "#2e844a", "#dd7a01", "#ca8501", "#0176d3", "#2f2cb7", "#ba01ff", "#fe5c4c", "#41b658", "#f38303", "#e4a201", "#0d9dda", "#5867e8", "#cb65ff", "#fe7765", "#45c65a", "#fe9339", "#fcc003", "#1ab9ff", "#9ea9f1", "#d892fe", "#feb8ab", "#91db8b", "#ffba90", "#f9e3b6", "#90d0fe", "#bec7f6", "#e5b9fe"];
    renderedCallback() {
        this.isPassFailQuestion = (this.currentquestion.Kinetics__Field_Type__c == 'Pass Fail');

        if (this.hasRendered == false) {
            const style = document.createElement('style');
            style.innerText = `c-tb-question-options-popup .slds-color-picker__summary-input {
                display: none !important;
            }`;
            this.template.querySelector('div.externalstyle').appendChild(style);
            this.hasRendered = true;
        }
    }
    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }

    addOptionInList(event) {
        var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentQuestion.Kinetics__Values__c || [];

        optionsArr.push(
            {
                'value': '',
                'label': '',
                'color': '#3273CB',
                'optionno': (optionsArr.length + 1),
                'score': ''
            });

        currentQuestion.Kinetics__Values__c = optionsArr;
        this.currentquestion = currentQuestion;
    }

    handleOptionInputChange(event) {
        event.preventDefault();
        this.errormessage = undefined;
        var attributename = event.target.dataset.name;
        var optionnumber = event.target.dataset.optionnumber;
        var currentQuestion = this.cloneValue(this.currentquestion);
        for (var i = 0; i < currentQuestion.Kinetics__Values__c.length; i++) {
            if (optionnumber == currentQuestion.Kinetics__Values__c[i]['optionno']) {
                currentQuestion.Kinetics__Values__c[i][attributename] = event.target.value;
                currentQuestion.Kinetics__Values__c[i]['label'] = event.target.value;
            }
        }
        this.currentquestion = this.cloneValue(currentQuestion);
    }

    handleCancel(event) {
        this.errormessage = undefined;
        this.isShowOptionModal = false;
        const valueChangeEvent = new CustomEvent('questionupdate', {
            detail: { currentquestion: undefined, isShowOptionModal: this.isShowOptionModal }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleSave(event) {
        this.errormessage = undefined;

        if (this.currentquestion.Kinetics__Values__c.length < 2) {
            this.errormessage = 'Please add at least two options.';
            return 0;
        }
        for (var i = 0; i < this.currentquestion.Kinetics__Values__c.length; i++) {
            if (this.currentquestion.Kinetics__Values__c[i].value == undefined
                || this.currentquestion.Kinetics__Values__c[i].value == '') {
                this.errormessage = 'Please ensure each Picklist Value option is populated';
                return 0;
            }
        }
        this.isShowOptionModal = false;
        const valueChangeEvent = new CustomEvent('questionupdate', {
            detail: { currentquestion: this.currentquestion, isShowOptionModal: this.isShowOptionModal }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    deleteOption(event) {
        this.errormessage = undefined;
        var optionnumber = event.target.dataset.optionnumber;
        var indexToDelete = -1;
        var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentQuestion.Kinetics__Values__c;
        for (var i = 0; i < optionsArr.length; i++) {
            if (optionnumber == optionsArr[i]['optionno']) {
                indexToDelete = i;
                break;
            }
        }
        if (indexToDelete != -1) {
            optionsArr.splice(indexToDelete, 1);
        }
        //to adjust the options numbers after delete
        for (var i = 0; i < optionsArr.length; i++) {
            optionsArr[i].optionno = (i + 1);
        }

        currentQuestion.Kinetics__Values__c = optionsArr;
        this.currentquestion = currentQuestion;
    }

    cloneOption(event) {
        this.errormessage = undefined;
        var optionnumber = event.target.dataset.optionnumber;
        var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentQuestion.Kinetics__Values__c;
        var option2Clone = {};
        for (var i = 0; i < optionsArr.length; i++) {
            if (optionnumber == optionsArr[i]['optionno']) {
                option2Clone = optionsArr[i];
            }
        }
        var newOption = this.cloneValue(option2Clone);
        optionsArr.push(newOption);

        //to adjust the options numbers after insert
        for (var i = 0; i < optionsArr.length; i++) {
            optionsArr[i].optionno = (i + 1);
        }

        currentQuestion.Kinetics__Values__c = optionsArr;
        this.currentquestion = currentQuestion;
    }
}