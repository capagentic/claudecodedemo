import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import shareNoteRecord from '@salesforce/apex/InspTemplateRendererController.shareNoteRecord';
import LightningModal from 'lightning/modal';

export default class TbInspFooterActionCreateNoteNG extends LightningModal {
    @api inspectionRec;
    @api templateName;
    @api question;
    @api noteId;
    @track noteContent = '';
    popupTitle = 'New Note';
    isLoading = false;

    connectedCallback() {
        console.log(this.noteId);
        if (this.noteId != undefined && this.noteId.length > 0) {
            this.popupTitle = 'Edit Note';
        }
    }

    closeModal(event) {
        const valueChangeEvent = new CustomEvent('close', {
            detail: { closeTaskCreationPopup: false }
        });
        this.dispatchEvent(valueChangeEvent);
        this.close('canceled');
    }

    @api
    handleSubmit(event) {
        console.log('TbInspFooterActionCreateNoteNG>handleSubmit');
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        const noteContentEncoded = btoa(this.noteContent);
        fields['Content'] = noteContentEncoded;
        fields['Title'] = this.templateName;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleOnLoad(event) {
        // console.log(event.detail);
        //console.log(JSON.parse(JSON.stringify(event.detail)));
        if (event.detail != undefined && event.detail.hasOwnProperty('records')
            && event.detail.records.hasOwnProperty(this.noteId)) {
            var currentRecord = event.detail.records[this.noteId];
            if (currentRecord != undefined
                && currentRecord.hasOwnProperty('fields')
                && currentRecord.fields.hasOwnProperty('Content') && currentRecord.fields['Content'].value) {
                this.noteContent = atob(currentRecord.fields['Content'].value);
                // console.log(this.noteContent);
            }
        }

        if (this.noteId == undefined) {
            this.noteContent = this.question.questionDetails;
        }
    }

    handleSuccess(event) {
        console.log('TbInspFooterActionCreateNoteNG>handleSuccess');
        this.noteId = event.detail.id;
        var noteDescription = this.noteContent
        noteDescription = noteDescription.slice(0, 15);
        if (noteDescription.length != this.noteContent.length) {
            noteDescription = noteDescription + '...';
        }

        var inspectionId = this.inspectionRec.Id;
        var contactId = this.inspectionRec.Kinetics__Contact__c;
        var accountId = this.inspectionRec.Kinetics__Account__c;
        var shareWithIdListByNoteId = {};
        shareWithIdListByNoteId[this.noteId] = [];

        this.updateVisitNotesRecords(this.noteId, noteDescription);
        if (inspectionId != undefined && inspectionId != '') {
            shareWithIdListByNoteId[this.noteId].push(inspectionId);
        }
        if (accountId != undefined && accountId != '') {
            shareWithIdListByNoteId[this.noteId].push(accountId);
        }
        if (contactId != undefined && contactId != '') {
            shareWithIdListByNoteId[this.noteId].push(contactId);
        }
        // if(this.question.existingAnswerId != undefined && this.question.existingAnswerId != '') {
        //     shareWithIdListByNoteId[this.noteId].push(this.question.existingAnswerId);
        // }

        shareNoteRecord({ shareWithIdListByNoteId: shareWithIdListByNoteId }).then(result => {
            //console.log(result);
            this.showToast();
            this.isLoading = false;
            this.close('success');
        }).catch(error => {
            console.log(error);
            this.showToast();
            this.isLoading = false;
            this.close('success');
        });

    }
    showToast() {
        const event = new ShowToastEvent({
            title: '',
            variant: 'success',
            message:
                'New Note created.',
        });
        this.dispatchEvent(event);
    }

    handleChange(event) {
        if (event.target.dataset.fieldname == 'Title') {
            this.titleText = event.target.value;
        } else if (event.target.dataset.fieldname == 'Content') {
            this.noteContent = event.target.value;
        }
    }

    updateVisitNotesRecords(noteRecordId, noteDescription) {
        var question = this.question;
        var noteId = noteRecordId;
        var noteRec = noteDescription;
        const valueChangeEvent = new CustomEvent('noterecordcreate', {
            detail: { question: question, noteId: noteId, noteRec: noteRec }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}