import { LightningElement, api } from 'lwc';
import uploadFile from '@salesforce/apex/OpenAIFileController.uploadFile';
import deleteFile from '@salesforce/apex/OpenAIFileController.deleteFile';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import { RefreshEvent } from 'lightning/refresh';

export default class OpenaiFileUpload extends LightningElement {

    @api recordId;
    @api objectApiName;
    contentDocId;
    showDeleteBtn = false;

    get acceptedFormats() {
        return ['.pdf', '.png', '.docx', '.txt', '.json'];
    }

    handleUploadFinished(event) {
        console.log('handleUploadFinished');
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        var result = JSON.stringify(uploadedFiles);
        console.log('uploadedFiles=' + result);

        var uploadedFile = uploadedFiles[0];
        this.contentDocId = uploadedFile.documentId;

        uploadFile({
            fileName: uploadedFile.name,
            contentDocumentId: uploadedFile.documentId
        }).then(result => {
            if (result != 'error') {
                var resultObj = JSON.parse(result);
                this.showDeleteBtn = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "File Uploaded successfully",
                        variant: "success",
                    }),
                );
                if(this.objectApiName == 'Kinetics__Meeting__c') {
                    // Create the recordInput object
                    const fields = {};
                    fields['Id'] = this.recordId;
                    fields['Kinetics__Files_Ids__c'] = resultObj.id;
                    const recordInput = { fields };

                    updateRecord(recordInput).then(() => {
                        this.dispatchEvent(new RefreshEvent());
                    }).catch((error) => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error uploading file",
                                message: error.body.message,
                                variant: "error",
                            }),
                        );
                    });    
                }
            }
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error uploading file",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }

    handleDeleteFile(event) {
        deleteFile({
            contentDocumentId: this.contentDocId
        }).then(result => {
            alert('Result: ' + result);
            this.showDeleteBtn = false;
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error uploading file",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }
}