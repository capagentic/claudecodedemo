import { LightningElement, track, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTaskRecord from '@salesforce/apex/InspTemplateRendererController.createTaskRecord';

import currentUserId from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import UserNameFld from '@salesforce/schema/User.Name';
import LightningModal from 'lightning/modal';

export default class TbInspFooterActionCreateTaskNG extends LightningModal {

    @api inspectionRec;
    @api templateName;
    @api question;
    @api ispreviewshown;
    @track taskRecord = {};
    isLoading = false;
    activesectionnames = ['Task_Information','Additional_Information'];
    priorityOptions =[{'label':'High', 'value':'High'}, {'label':'Normal', 'value':'Normal'}, {'label':'Low', 'value':'Low'}];
    statusOptions =[{'label':'Not Started', 'value':'Not Started'}, {'label':'In Progress', 'value':'In Progress'}, {'label':'Completed', 'value':'Completed'}, {'label':'Waiting on someone else', 'value':'Waiting on someone else'}, {'label':'Deferred', 'value':'Deferred'}];
    
    @track currentUserName;
    @wire(getRecord, { recordId: currentUserId, fields: [UserNameFld]}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        } else if (error) {
            this.showToast('Task', 'error', JSON.stringify(error));
        }
    }

    connectedCallback() {
        var dueDate = new Date();
        dueDate = new Date(dueDate.setDate(dueDate.getDate() + 7));
        dueDate = dueDate.toISOString().slice(0, 10);

        this.taskRecord['Subject'] = this.templateName;
        this.taskRecord['ActivityDate'] = dueDate;
        this.taskRecord['Status'] = 'Not Started';
        this.taskRecord['Priority'] = 'Normal';
        this.taskRecord['WhatId'] = this.inspectionRec?.Id;
        this.taskRecord['Description'] = this.question.questionDetails;
        this.taskRecord['WhoId'] = this.inspectionRec?.Kinetics__Contact__c;
        this.taskRecord['OwnerId'] = currentUserId;
      //  this.taskRecord['Kinetics__Template_Answer__c'] = this.question.existingAnswerId;

        setTimeout(() => {
            this.template.querySelector('[name="Priority"]').selectedIndex = 2;
        },10);
    }

    closeModal(event) {
        const valueChangeEvent = new CustomEvent('close', {
            detail: { closeTaskCreationPopup: false }
        });
        this.dispatchEvent(valueChangeEvent);
        this.close('success');
    }

    recordSelectionHandler(event) {
        this.taskRecord[event.target.dataset.fieldname] = event.detail.selectedRecordId;
    }
    isValidValue (value) {
        if(value == undefined || value =='' || value.length ==0) {
            return false;
        }
        return true;
    }

    isValidData() {
        if(this.isValidValue(this.taskRecord['Priority'])
            && this.isValidValue(this.taskRecord['Subject'])) {
                return true;
            }
        return false;
    }

    @api
    handleSubmit(event) {
        event.preventDefault();
        if(!this.isValidData()){
            this.showToast('Task', 'error', 'Please provide value for required fields');
            return;
        }

        if(this.ispreviewshown) {
            this.closeModal(undefined);
        }

        this.isLoading = true;
        this.taskRecord['Type'] = 'Other';
        console.log(JSON.stringify(this.taskRecord));
        createTaskRecord({taskRecordJSON: JSON.stringify([this.taskRecord])}).then(result => {
            this.taskRecord['Id'] = JSON.parse(result)[0].Id;
            this.showToast('', 'success', 'New Task created.');
            this.updateTaskRecords();
            this.isLoading = false;
            this.closeModal(undefined);
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Task', 'error', JSON.stringify(error));
        });
    }

    updateTaskRecords() {
        var question = this.question;
        var taskId = this.taskRecord['Id'];
        var taskRec = this.taskRecord;
        const valueChangeEvent = new CustomEvent('taskrecordcreate', {
            detail: { question: question, taskId: taskId, taskRec: taskRec }
        });
        this.dispatchEvent(valueChangeEvent);  
    }

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message
        });
        this.dispatchEvent(event);
    }

    handleChange(event) {
        this.taskRecord[event.target.dataset.fieldname] = event.target.value;
    }
}