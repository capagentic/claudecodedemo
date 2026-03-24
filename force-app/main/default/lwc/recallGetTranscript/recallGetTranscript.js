import { LightningElement, api } from 'lwc';
import retrieveBotTranscriptByMeetingId from '@salesforce/apex/MeetingTranscriptService.retrieveBotTranscriptByMeetingId';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RecallGetTranscript extends NavigationMixin(LightningElement) {
    @api isLoaded = false;

    _recordId;

    @api set recordId(value) {
        this._recordId = value;

        // do your thing right here with this.recordId / value
        this.callRecall();
    }

    get recordId() {
        return this._recordId;
    }

    connectedCallback() {
        this.isLoaded = true;
    }

    callRecall() {
        retrieveBotTranscriptByMeetingId({
            meetingId: this.recordId
        }).then(success => {
            this.showToast('Success', 'The transcript has been retrieved successfully.', 'success');

        }).catch(error => {
            console.log('error: ' + JSON.stringify(error));
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.isLoaded = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Success',
                message: message || 'Meeting Record Updated!',
                variant: variant || 'success'
            })
        );
    }

}