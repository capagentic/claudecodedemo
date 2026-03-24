import { api, LightningElement } from 'lwc';

export default class TbQuestionFooterActions extends LightningElement {
    @api currentquestion;


    get showRequiredToggleButton() {
        return this.currentquestion.Kinetics__Field_Type__c != 'Salesforce Flow';
    } 
    get showAttachPhotoToggleButton () {
        return this.currentquestion.Kinetics__Field_Type__c != 'Salesforce Flow';
    }
    get showNotesToggleButton () {
        return this.currentquestion.Kinetics__Field_Type__c != 'Salesforce Flow';
    }
    get showTasksToggleButton () {
        return this.currentquestion.Kinetics__Field_Type__c != 'Salesforce Flow';
    }
    get showGptGuidenceToggleButton () {
        return this.currentquestion.Kinetics__Field_Type__c != 'Salesforce Flow';
    }
    get showInstructionsToggleButton () {
        return true;
    }

    handleToggleChangeOnQuestion(event) {
        var uid = event.target.dataset.uid
        var currentQuestion = this.cloneValue(this.currentquestion);
        if(this.currentquestion.uid == uid) {
            currentQuestion[event.target.name] = event.target.checked;
        }
        this.currentquestion = currentQuestion;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { question: currentQuestion }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }
}