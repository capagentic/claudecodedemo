import { api, LightningElement, track } from 'lwc';
import getRelatedFieldInformation from '@salesforce/apex/TbInspTemplateQuestionRendererController.getRelatedFieldInformation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TbInspQuestionSalesforceFieldNG extends LightningElement {


    @api question = {};
    @api readOnly = false;
    @api inspectionRec;
    @track salesforcefieldplaceholder = '';
    showSpinner = true;
    @track extraQuestionInfo = null;
    connectedCallback() {
        var requiredInformationObj = {};
        if (this.inspectionRec) {
            //console.log(JSON.parse(JSON.stringify(this.inspectionRec)));
            var inspectionId = this.inspectionRec.Id;
            requiredInformationObj['inspectionRecId'] = inspectionId;
        }

        //console.log(JSON.parse(JSON.stringify(this.question)));
        //var questionId = this.question.questionId;
        //var templateQuestionId = this.question.templateQuestionId;
        this.salesforcefieldplaceholder = '{' + this.question.relatedObjectName + '.' + this.question.relatedObjectFieldName + '}';

        requiredInformationObj['relatedObjectName'] = this.question.relatedObjectName;
        requiredInformationObj['relatedObjectFieldName'] = this.question.relatedObjectFieldName;
        if (requiredInformationObj.hasOwnProperty('inspectionRecId')
            && this.isValidaValue(requiredInformationObj['inspectionRecId'])
            && this.isValidaValue(requiredInformationObj['relatedObjectName'])
            && this.isValidaValue(requiredInformationObj['relatedObjectFieldName'])) {
            getRelatedFieldInformation({
                requiredInformationMapJSON: JSON.stringify(requiredInformationObj)
            }).then(resultMapByFieldNameString => {
                var resultObjByFieldName = JSON.parse(resultMapByFieldNameString);
                if (resultObjByFieldName.hasOwnProperty(this.question.relatedObjectFieldName)) {
                    var questionLocal = JSON.parse(JSON.stringify(this.question));
                    if (this.question.showRelatedInfoAsaAnswer
                        && (!this.isValidaValue(this.question.answer))) {
                        questionLocal.answer = resultObjByFieldName[this.question.relatedObjectFieldName];
                        this.question = questionLocal;
                        this.broadcastChanges(questionLocal.answer);
                    }
                    if (this.question.showRelatedInfoInQuestionText) {
                        questionLocal.questionDetails = questionLocal.questionDetails + ' ' + resultObjByFieldName[this.question.relatedObjectFieldName];
                        this.question = questionLocal;
                        this.broadcastChanges(questionLocal.answer);
                    }
                }
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                this.showToast('Inspection', 'error', JSON.stringify(error));
            });
        } else {
            this.showSpinner = false;
        }
    }

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }

    handleChange(event) {
        console.log('text handleChange..');
        const selectedValue = event.detail.value;
        this.broadcastChanges(selectedValue);
    }

    broadcastChanges(selectedValue) {
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    showToast(title, variant, message) {
        this.showSpinner = false;
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message
        });
        this.dispatchEvent(event);
    }
    isValidaValue(value) {
        return value != null && value != undefined && value != '';
    }
}