import { LightningElement, api, wire, track } from 'lwc';

export default class TbQuestionTypes extends LightningElement {
    @api currentquestion;
    @track availableQuestionTypes = [];
    @track isShowOptionModal = false;
    @track isShownObjectReferenceModal = false;

    connectedCallback() {
        this.initializeTypes();
        this.initForm();
    }

    initializeTypes() {
        this.availableQuestionTypes.push({ 'label': '-- Select Question Type --', 'value': '', 'icon': '' });
        this.availableQuestionTypes.push({ 'label': 'Text', 'value': 'Text', 'icon': 'utility:text' });
        this.availableQuestionTypes.push({ 'label': 'Text Area', 'value': 'Text Area', 'icon': 'utility:new_direct_message' });
        this.availableQuestionTypes.push({ 'label': 'Picklist (Multi Select)', 'value': 'Checkbox', 'icon': 'utility:picklist_choice' });
        this.availableQuestionTypes.push({ 'label': 'Picklist', 'value': 'Radio Button', 'icon': 'utility:picklist_type' });
        this.availableQuestionTypes.push({ 'label': 'Pass Fail', 'value': 'Pass Fail', 'icon': 'utility:task' });
        this.availableQuestionTypes.push({ 'label': 'Yes No', 'value': 'Yes No', 'icon': 'utility:task' });
        this.availableQuestionTypes.push({ 'label': 'Compliant Non Compliant', 'value': 'Compliant Non Compliant', 'icon': 'utility:task' });
        this.availableQuestionTypes.push({ 'label': 'Number', 'value': 'Number', 'icon': 'utility:number_input' });
        this.availableQuestionTypes.push({ 'label': 'Percentage', 'value': 'Percentage', 'icon': 'utility:percent' });
        this.availableQuestionTypes.push({ 'label': 'Currency', 'value': 'Currency', 'icon': 'utility:currency' });
        this.availableQuestionTypes.push({ 'label': 'Date', 'value': 'Date', 'icon': 'utility:monthlyview' });
        this.availableQuestionTypes.push({ 'label': 'Date & Time', 'value': 'Date & Time', 'icon': 'utility:monthlyview' });
        this.availableQuestionTypes.push({ 'label': 'Email', 'value': 'Email', 'icon': 'utility:email' });
        this.availableQuestionTypes.push({ 'label': 'URL', 'value': 'URL', 'icon': 'utility:apex' });
        this.availableQuestionTypes.push({ 'label': 'Signature', 'value': 'Signature', 'icon': 'utility:signature' });
        this.availableQuestionTypes.push({ 'label': 'File', 'value': 'File', 'icon': 'utility:attach' });
        this.availableQuestionTypes.push({ 'label': 'Rating', 'value': 'Rating', 'icon': 'utility:rating' });
        this.availableQuestionTypes.push({ 'label': 'Net Promoter Score', 'value': 'Net Promoter Score', 'icon': 'utility:smiley_and_people' });
        this.availableQuestionTypes.push({ 'label': 'Geo Location', 'value': 'Geo Location', 'icon': 'utility:location' });
        this.availableQuestionTypes.push({ 'label': 'Salesforce Field', 'value': 'Salesforce Field', 'icon': 'utility:database' });
        this.availableQuestionTypes.push({ 'label': 'Voice Memo', 'value': 'Voice Memo', 'icon': 'utility:unmuted' });
        this.availableQuestionTypes.push({ 'label': 'Barcode Scan', 'value': 'Barcode Scan', 'icon': 'utility:scan' });
        this.availableQuestionTypes.push({ 'label': 'Salesforce Flow', 'value': 'Salesforce Flow', 'icon': 'utility:apex' });
    }

    initForm() {
        if (!this.currentquestion && !this.currentquestion['icon']) {
            this.currentquestion['icon'] = 'utility:text';
        }
    }

    handleTypeChange(event) {
        console.log('TbQuestionTypes>>handleTypeChange...');
        var uid = event.target.dataset.uid;

        var currentquestion = this.cloneValue(this.currentquestion);
        if (this.currentquestion.uid == uid) {
            currentquestion[event.target.dataset.name] = event.target.value;

            if (event.target.dataset.icon) {
                currentquestion['icon'] = event.target.dataset.icon;
            }
        }
        currentquestion.Kinetics__Values__c = [];
        if (event.target.value == 'Pass Fail') {
            currentquestion = this.addOptionsForPassFailQuestion(currentquestion);
        } else if (event.target.value == 'Yes No') {
            currentquestion = this.addOptionsForYesNoQuestion(currentquestion);
        } else if (event.target.value == 'Compliant Non Compliant') {
            currentquestion = this.addOptionsForCompliantNonCompliantQuestion(currentquestion);
        } else if (event.target.value == 'Salesforce Flow') {
            currentquestion = this.disableNonRequiredAttributes(currentquestion);
        }
        //do not allow to capture more files
        // if(event.target.value == 'File' || event.target.value == 'Voice Memo') {
        //     currentquestion.Kinetics__Attach_Photos_or_Files__c = false;
        // }

        
        this.currentquestion = currentquestion;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { question: currentquestion }
        });

        this.dispatchEvent(valueChangeEvent);

        if (event.target.value == 'Radio Button'
            || event.target.value == 'Checkbox'
            || event.target.value == 'Pass Fail'
            || event.target.value == 'Yes No'
            || event.target.value == 'Compliant Non Compliant') {
            this.openOptionPopup();
        }
        else if (event.target.value == 'Salesforce Field') {
            this.openReferenceObjectPopup();
        }
    }
    disableNonRequiredAttributes(currentquestion) {
        currentquestion['Kinetics__Assign_Tasks__c'] = false;
        currentquestion['Kinetics__Attach_Photos_or_Files__c'] = false;
        currentquestion['Kinetics__Capture_Notes__c'] = false;
        return currentquestion;
    }

    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }

    get questionTypeLabel() {
        var questionTypeLabel = '';
        for (var i = 0; i < this.availableQuestionTypes.length; i++) {
            if (this.availableQuestionTypes[i].value == this.currentquestion.Kinetics__Field_Type__c) {
                questionTypeLabel = this.availableQuestionTypes[i].label;
                break;
            }
        }
        return questionTypeLabel;
    }
    get isCheckboxRadioButtonType() {
        return (this.currentquestion != undefined
            && (this.currentquestion.Kinetics__Field_Type__c == 'Radio Button'
                || this.currentquestion.Kinetics__Field_Type__c == 'Checkbox'
                || this.currentquestion.Kinetics__Field_Type__c == 'Pass Fail'
                || this.currentquestion.Kinetics__Field_Type__c == 'Yes No'
                || this.currentquestion.Kinetics__Field_Type__c == 'Compliant Non Compliant'));
    }

    get isFieldReferenceType() {
        return (this.currentquestion != undefined
            && (this.currentquestion.Kinetics__Field_Type__c == 'Salesforce Field'));
    }

    get currentquestionOptionValues() {
        if (this.isShowOptionModal) {
            return 0;
        }

        var optionsArr = this.currentquestion.Kinetics__Values__c || [];
        var optionsWithColor = '';
        var optionstogether = '';
        var shownOptions = 0;
        for (var i = 0; i < optionsArr.length; i++) {
            if (optionstogether.length > 20) {
                optionsWithColor = optionsWithColor + ' +' + (optionsArr.length - shownOptions) + ' more';
                return optionsWithColor;
            }
            shownOptions = shownOptions + 1;
            optionstogether = optionstogether + optionsArr[i].value;
            var valueToUse = optionsArr[i].value;
            if (valueToUse.length > 20) {
                valueToUse = valueToUse.substr(1, 20) + '...';
            }
            optionsWithColor = optionsWithColor + '<span class=\"slds-badge\" style=\"color:white; background-color:' + optionsArr[i].color + ';\">' + valueToUse + ' </span>';
        }
        return optionsWithColor;
    }

    get currentselectObjectFieldName() {
        var selectedvalues = '';//'<span class=\"slds-badge\" style=\"color:white; background-color:grey;\">';
        if (this.currentquestion.Kinetics__Related_To_Object__c != undefined) {
            selectedvalues = selectedvalues + '<span class=\"slds-badge\" style=\"color:white; background-color:grey;\"> Object: ' + this.currentquestion.Kinetics__Related_To_Object__c + '</span>';
        }
        if (this.currentquestion.Kinetics__Related_Field_API_Name__c != undefined) {
            selectedvalues = selectedvalues + '<span class=\"slds-badge\" style=\"color:white; background-color:grey;\"> Field: ' + this.currentquestion.Kinetics__Related_Field_API_Name__c + '</span>';
        }
        return selectedvalues;
    }

    get maxscore() {
        var optionsArr = this.currentquestion.Kinetics__Values__c || [];
        var maxscoreLocal = 0;
        for (var i = 0; i < optionsArr.length; i++) {
            if (optionsArr[i].score != undefined
                && maxscoreLocal < parseInt(optionsArr[i].score)) {
                maxscoreLocal = parseInt(optionsArr[i].score);
            }
        }
        return maxscoreLocal;
    }

    get showMaxScore() {
        var showMaxScore = false;
        if (this.maxscore >= 1) {
            showMaxScore = true;
        }
        return showMaxScore;
    }

    addOptionsForPassFailQuestion(currentquestion) {
        //var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentquestion.Kinetics__Values__c || [];

        optionsArr.push(
            {
                'value': 'Pass',
                'label': 'Pass',
                'color': '#379941',
                'optionno': (optionsArr.length + 1),
                'score': 1
            });
        optionsArr.push(
            {
                'value': 'Fail',
                'label': 'Fail',
                'color': '#EE0707',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        optionsArr.push(
            {
                'value': 'NA',
                'label': 'NA',
                'color': '#BAB0B0',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        currentquestion.Kinetics__Values__c = optionsArr;
        //this.currentquestion = currentQuestion;
        return currentquestion;
    }
    addOptionsForYesNoQuestion(currentquestion) {
        //var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentquestion.Kinetics__Values__c || [];

        optionsArr.push(
            {
                'value': 'Yes',
                'label': 'Yes',
                'color': '#379941',
                'optionno': (optionsArr.length + 1),
                'score': 1
            });
        optionsArr.push(
            {
                'value': 'No',
                'label': 'No',
                'color': '#EE0707',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        optionsArr.push(
            {
                'value': 'NA',
                'label': 'NA',
                'color': '#BAB0B0',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        currentquestion.Kinetics__Values__c = optionsArr;
        //this.currentquestion = currentQuestion;
        return currentquestion;
    }
    addOptionsForCompliantNonCompliantQuestion(currentquestion) {
        //var currentQuestion = this.cloneValue(this.currentquestion);
        var optionsArr = currentquestion.Kinetics__Values__c || [];

        optionsArr.push(
            {
                'value': 'Compliant',
                'label': 'Compliant',
                'color': '#379941',
                'optionno': (optionsArr.length + 1),
                'score': 1
            });
        optionsArr.push(
            {
                'value': 'Non Compliant',
                'label': 'Non Compliant',
                'color': '#EE0707',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        optionsArr.push(
            {
                'value': 'NA',
                'label': 'NA',
                'color': '#BAB0B0',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        currentquestion.Kinetics__Values__c = optionsArr;
        //this.currentquestion = currentQuestion;
        return currentquestion;
    }

    openReferenceObjectPopup(event) {
        this.isShownObjectReferenceModal = true;
    }
    openOptionPopup(event) {
        // this.currentquestionlocal = this.currentquestion;
        this.isShowOptionModal = true;
    }

    updateQuestion(event) {
        var currentquestion = event.detail.currentquestion;
        this.isShowOptionModal = event.detail.isShowOptionModal || false;
        this.isShownObjectReferenceModal = event.detail.isShowFieldReferenceModal || false;
        if (currentquestion != undefined) {
            this.currentquestion = currentquestion;
        }

        console.log('updateQuestion>this.currentquestion=' + JSON.stringify(this.currentquestion));
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { question: this.currentquestion }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}