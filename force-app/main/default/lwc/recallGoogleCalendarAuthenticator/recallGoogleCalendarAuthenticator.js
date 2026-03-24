import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserEmail from '@salesforce/apex/RecallGoogleAuthenticator.getUserEmail';
import getRecallCalendarAuthToken from '@salesforce/apex/RecallGoogleAuthenticator.getRecallCalendarAuthToken';
import updateRecordingPreferences from '@salesforce/apex/RecallGoogleAuthenticator.updateRecordingPreferences';
import deleteCalendarUser from '@salesforce/apex/RecallGoogleAuthenticator.deleteCalendarUser';

export default class RecallGoogleCalendarAuthenticator extends LightningElement {
    @track userEmail;
    recallCalendarAuthToken;
    @track authTokenValid = false;
    @track showPreferences = false;

    value = ['option1'];

    get preferenceOptions() {
        return [
            { label: 'Meeting will be recorded only if the connected account is not the host of the meeting', value: 'record_non_host' },
            { label: 'Meeting will be recorded only if it has at least 1 external attendee', value: 'record_external' },
            { label: 'Meeting will be recorded only if it has no external attendee', value: 'record_internal' },
            { label: 'Meeting will be recorded only if it is a recurring meeting', value: 'record_recurring' },
            { label: 'Meeting will only be recorded if the calendar account has "accepted" it', value: 'record_confirmed' },
            { label: 'Meeting will only be recorded if the calendar account is the host of the meeting', value: 'record_only_host' },
        ];
    }

    get selectedValues() {
        return this.value.join(',');
    }

    handlePreferenceChange(e) {
        this.value = e.detail.value;
    }

    connectedCallback() {
        this.handleGetUserEmail();
    }

    handleConfirmUsername(event) {
        console.log('handleConfirmUsername');
        getRecallCalendarAuthToken({ userEmail: this.userEmail })
            .then(result => {
                if (result != 'error') {
                    console.log(result);
                    window.location = result;
                }
            })
            .catch(error => {
                console.log('error');
            })
    }


    handleGetUserEmail() {
        console.log('getUserEmail');

        getUserEmail()
            .then(result => {
                if (result != 'error') {
                    var userObj = JSON.parse(result);
                    this.userEmail = userObj.userEmail;
                    this.recallCalendarAuthToken = userObj.recallCalendarAuthToken;

                    if (this.recallCalendarAuthToken) {
                        this.authTokenValid = true;
                        this.showPreferences = true;
                    }
                }
            })
            .catch(error => {
                console.log('error');
            })
    }

    haneldUpdateRecordingPreference(event) {
        console.log('haneldUpdateRecordingPreference');
        updateRecordingPreferences({ recallCalendarAuthToken: this.recallCalendarAuthToken })
            .then(result => {
                if (result != 'error') {
                    console.log(result);
                    const updateEvent = new ShowToastEvent({
                        "title": 'Success',
                        "variant": 'success',
                        "message": 'Bot recording preference updated'
                    });
                    this.dispatchEvent(updateEvent);
                }
            })
            .catch(error => {
                console.log('error');
            })
    }

    haneldDeleteCalendarUser(event) {
        console.log('haneldDeleteCalendarUser');
        deleteCalendarUser({ recallCalendarAuthToken: this.recallCalendarAuthToken })
            .then(result => {
                if (result != 'error') {
                    console.log(result);
                    const updateEvent = new ShowToastEvent({
                        "title": 'Success',
                        "variant": 'success',
                        "message": 'Calendar integration has been revoked.'
                    });
                    this.dispatchEvent(updateEvent);
                }
            })
            .catch(error => {
                console.log('error');
            })
    }


}