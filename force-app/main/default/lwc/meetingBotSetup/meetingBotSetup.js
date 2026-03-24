import { LightningElement, track } from 'lwc';
import sendBot2Meeting from '@salesforce/apex/MeetingTranscriptService.sendBot2Meeting';
import retrieveBot from '@salesforce/apex/MeetingTranscriptService.retrieveBot';
import retrieveBotTranscript from '@salesforce/apex/MeetingTranscriptService.retrieveBotTranscript';

export default class MeetingBotSetup extends LightningElement {
    meetingUrl;
    @track botId;
    @track botObj;
    @track transcript;


    handleMeetingUrlChange(event) {
        this.meetingUrl = event.detail.value;
    }

    handleBotIdChange(event) {
        this.botId = event.detail.value;
    }

    handleInvite(event) {
        console.log('handleInvite');

        sendBot2Meeting({
            meetingUrl: this.meetingUrl,
            botName: 'Meeting Assistant'
        })
            .then(result => {
                if (result != 'error') {
                    console.log(result);
                    this.botObj = JSON.parse(result);
                    this.botId = this.botObj.id;
                }
            })
            .catch(error => {
                console.log('error');
            })
    }

    handleGetTranscript(event) {

        console.log('handleGetTranscript');
        var botId = this.botId;
        retrieveBotTranscript({
            botID: botId
        })
            .then(result => {
                if (result != 'error') {
                    console.log(result);
                    this.transcript = JSON.parse(result);
                    // this.transcript = result;
                }
            })
            .catch(error => {
                console.log('error');
            })
    }
}