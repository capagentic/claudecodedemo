import { LightningElement, api, track } from 'lwc';
import sendSms from "@salesforce/apex/SeqSenderController.sendSms";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SeqSender extends LightningElement {
    @api recordId;
    @track surveyId;
    url;

    handleSendSeqSms(event) {
        console.log('handleSendSeqSms');
        sendSms({
            surveyId: this.surveyId,
            contactId: this.recordId
        })
            .then((result) => {
                console.log(result);
                this.url = result;
                const event = new ShowToastEvent({
                    title: 'Congratulations',
                    message: 'The sequence form has been sent successfully',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            })
            .catch((error) => {
                console.error(error);
            });
    }

    recordSelectionHandler(event) {
        const selecteRecordId = event.detail.selectedRecordId;
        this.surveyId = selecteRecordId;
    }
}