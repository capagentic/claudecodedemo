import { LightningElement, api, track } from 'lwc';
//import calendlyScript from '@salesforce/resourceUrl/calendlyScript';
import { loadScript } from 'lightning/platformResourceLoader';
import getDetailsForCalendly from '@salesforce/apex/seqCalendlyController.getDetailsForCalendly';
export default class SeqQuestionCalendly extends LightningElement {

    @api question = {};
    @track eventbooked = false;
    @track isLoading = false;

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }
    getQueryParameters(param) {
        return (new URL(window.location.href).searchParams.get(param));
    }
    handleChange(selectedValue) {
        console.log('Calendly handleChange..');
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    connectedCallback() {
        this.isLoading = true;
        var seqGUID = this.getQueryParameters('seqnum');
        getDetailsForCalendly({seqGUID: seqGUID}).then(result => {
            //var calendlyScript = 'https://assets.calendly.com/assets/external/widget.js';
            //var calendlyBookingURL = 'https://calendly.com/shankar-dupade/fieldko-catchup??hide_event_type_details=1&hide_landing_page_details=1';
            
            var calendlyWrapper = JSON.parse(result);
            var contactName  = '';
            var contactEmail = '';
            if(calendlyWrapper.conRec != undefined) {
                contactEmail = calendlyWrapper.conRec.Email;
                contactName = calendlyWrapper.conRec.Name;
            }
            var calendlyBookingURL = '';
            var calendlyScript = '';
            if(calendlyWrapper.calendlyConfig != undefined) {
                calendlyBookingURL = calendlyWrapper.calendlyConfig.Kinetics__Base_Booking_URL__c;
                calendlyScript = calendlyWrapper.calendlyConfig.Kinetics__Calendly_Script_URL__c;
                if(calendlyWrapper.calendlyConfig.Kinetics__Hide_Event_Type_Details__c){
                    calendlyBookingURL = calendlyBookingURL + '?hide_event_type_details=1';//'&hide_gdpr_banner=1';
                }
            }

            loadScript(this, calendlyScript)
            .then(() => {
                this.isLoading = false;
                console.log('Loaded sayHello');
                Calendly.initInlineWidget({
                    url: calendlyBookingURL,
                    parentElement: this.template.querySelector('div.calendlyDiv'),
                    prefill: {
                        name: contactName,
                        email: contactEmail
                    },
                    utm: {}
                    }
                );
            })
            .catch(error => {
                this.isLoading = false;
                console.log(error);
                alert(error);
            });
        }).catch(error => {
            this.isLoading = false;
            console.log(error);
            alert(error);
        });

        window.addEventListener('message', this.postMessageEventListenerHelper.bind(this));
    }
    postMessageEventListenerHelper (e) {
        if (this.isCalendlyEvent(e)) {
            //console.log(JSON.stringify(e.data));
            if(e.data.event == 'calendly.event_scheduled'){
                //alert('succcessfully scheduled');
                this.eventbooked = true;
                //'{"event":"calendly.event_scheduled","payload":{"event":{"uri":"https://api.calendly.com/scheduled_events/d5cc0445-f1b5-47bd-8a17-8984094ba1ae"},"invitee":{"uri":"https://api.calendly.com/scheduled_events/d5cc0445-f1b5-47bd-8a17-8984094ba1ae/invitees/eb9f116e-11fa-4cb0-96ef-07bd11d50a32"}}}'
                this.handleChange(JSON.stringify(e.data.payload));
            }
        }
    }
    isCalendlyEvent(e) {
        return e.data.event && e.data.event.indexOf('calendly') === 0;
    }
}