import { api, LightningElement, track, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Question_Object from '@salesforce/schema/Kinetic_Question__c';


export default class TbQuestionFieldLinkPopup extends LightningElement {
    
    @track errormessage;
    @track requiredOptions = {
        'controllingPicklist_objectnames': [],
        'dependentFieldList': []
    };
    @track dependentDisabled = true;
    @track controllingDisabled = true;

    @api currentquestion;
    @track isLoading = true;

    connectedCallback() {
        this.isLoading = true;
       
        this.isLoading = false;
    }
    handleCancel(event){
        this.errormessage = undefined;
        const valueChangeEvent = new CustomEvent('questionupdate', {
            detail: { currentquestion: undefined, isShowFieldReferenceModal: false }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }

    handleSave(event){
        this.errormessage = undefined;
        const valueChangeEvent = new CustomEvent('questionupdate', {
            detail: { currentquestion: this.currentquestion, isShowFieldReferenceModal: false }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleToggleChangeOnQuestion(event) {
        var currentQuestion = this.cloneValue(this.currentquestion);
        currentQuestion[event.target.dataset.name] = event.target.checked;
        this.currentquestion = currentQuestion;
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: Question_Object, recordTypeId: '012000000000000AAA' })
    fetchPicklist({error,data}){
       
        if(data && data.picklistFieldValues){
            this.requiredOptions = {
                'controllingPicklist_objectnames': [],
                'dependentFieldList': []
            };
            let optionsValue = {}
            optionsValue["label"] = "--None--";
            optionsValue["value"] = "--None--";
            this.requiredOptions.controllingPicklist_objectnames.push(optionsValue);
            data.picklistFieldValues["Kinetics__Related_To_Object__c"].values.forEach(optionData => {
                this.requiredOptions.controllingPicklist_objectnames.push({label : optionData.label, value : optionData.value});
            });
            this.controllingDisabled = false;
            this.dependentPicklist = data.picklistFieldValues["Kinetics__Related_Field_API_Name__c"];
            this.adjustDependentFieldValues(this.currentquestion.Kinetics__Related_To_Object__c);
        }
        this.isLoading = false;
    }

    handleonchange(event) {
        var fieldname = event.target.dataset.name;
        var currentQuestion = this.cloneValue(this.currentquestion);
        currentQuestion[fieldname] = event.target.value;
        this.currentquestion = currentQuestion;
    }

    fetchDependentFieldValue(event){
        this.adjustDependentFieldValues(event.target.value);
    }
    adjustDependentFieldValues(selectedVal) {
        this.isLoading = true;
        this.requiredOptions.dependentFieldList=[];
        var currentQuestion = this.cloneValue(this.currentquestion);
        currentQuestion.Kinetics__Related_To_Object__c = selectedVal;
        this.currentquestion = currentQuestion;

        this.requiredOptions.dependentFieldList.push({label : "--None--", value : "--None--"})
        let controllerValues = this.dependentPicklist.controllerValues;
        this.dependentPicklist.values.forEach(depVal => {
            depVal.validFor.forEach(depKey =>{
                if(depKey === controllerValues[selectedVal]){
                    this.dependentDisabled = false;
                    this.requiredOptions.dependentFieldList.push({label : depVal.label, value : depVal.value});
                }
            });
            
        });
        this.isLoading = false;
    }
}