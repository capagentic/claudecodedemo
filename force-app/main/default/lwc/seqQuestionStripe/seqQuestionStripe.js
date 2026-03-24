import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClientSecret from '@salesforce/apex/StripeController.getClientSecret';
import getAmountToPay from '@salesforce/apex/StripeController.getAmountToPay';


export default class SeqQuestionStripe extends LightningElement {
    @api question = {};
    @track isLoading = false;
    stripe;
    elements;
    @track showStatusMessage = false;
    @track paymentDone = false;
    @track questionDetails = '';
    @track validCurrency = true;
    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }
    stripScript = 'https://js.stripe.com/v3/';
    publishibleKey = 'pk_test_Ka1ryCRL0umwBDDvpBlkkhq700ztnpBGaU';
    getQueryParameters(param) {
        return (new URL(window.location.href).searchParams.get(param));
    }
    handleChange(selectedValue) {
        console.log('Stripe handleChange..');
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    @track clientSecret;
    connectedCallback() {
        this.paymentDone = false;
        this.isLoading = true;
        var seqGUID = this.getQueryParameters('seqnum');
        this.questionDetails = this.question.questionDetails;
        getAmountToPay({seqGUID: seqGUID, questionId : this.question.questionId}).then(result => {
            var resultAmount = JSON.parse(result);
            
            if(resultAmount.amountCurrency == undefined || resultAmount.amountToPay == undefined) {
                this.showToast('Stripe Payment', 'Invalid Amount and Currency received, Please contact support team', 'error');
                this.isLoading = false;
                this.validCurrency = false;
                return 0;
            }
            var amountToDisplay = resultAmount.amountCurrency + ' ' +resultAmount.amountToPay;
            this.questionDetails = this.questionDetails.replace('{{amount}}', amountToDisplay);
            if(this.question.answer != null && JSON.parse(this.question.answer).status != undefined) {
                this.checkStatusAndIsLoadedFirstTime(JSON.parse(this.question.answer));
                this.isLoading = false;
            }
            if(!this.paymentDone) {
                getClientSecret({seqGUID: seqGUID, questionId : this.question.questionId}).then(result => {
                    this.clientSecret = JSON.parse(result).client_secret;
                    loadScript(this, this.stripScript).then(() => {
                        this.loadStripeScript(this.clientSecret);
                    }).catch(error => {
                        this.isLoading = false;
                        this.showToast('Stripe Payment', error.body.message, 'error');
                        console.log(error);
                    });

                }).catch(error => {
                    this.isLoading = false;
                    this.showToast('Stripe Payment', error.body.message, 'error');
                    console.log(error);
                });
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Stripe Payment', error.body.message, 'error');
            console.log(error);
        });
    }


    loadStripeScript(clientSecret) {
        this.stripe = Stripe(this.publishibleKey);
        this.initialize(clientSecret);
    }

    async initialize(clientSecret) {

        const appearance = {
            theme: 'stripe',
            // labels: 'floating',
        };
        this.elements = this.stripe.elements({ appearance, clientSecret, loader:'always' });
        this.mountTheElement();
    }

    mountTheElement() {
        var paymentElement = this.elements.getElement('payment');
        if (paymentElement == null) {
            paymentElement = this.elements.create('payment');
        }

        // paymentElement.update({fields: {
        //     billingDetails: {
        //       name: 'auto',
        //       email: 'auto',
        //       phone: 'auto',
        //       address: 'never'
        //     }
        // }});

        console.log('paymentElement=' + paymentElement);
        
        var requiredDivHTML = this.template.querySelector('div[data-id=payment-element]');
        paymentElement.mount(requiredDivHTML);

        this.isLoading = false;
    }

    checkStatusAndIsLoadedFirstTime(paymentIntent) {
        this.statusMessage = '';
        this.showStatusMessage = true;
        this.paymentDone = true;
        switch (paymentIntent.status) {
            case "succeeded":
                this.statusMessage = 'Your Payment has been submitted successfully.';
                break;
            case "processing":
                this.statusMessage = 'Your payment is processing.';
                break;
            case "requires_payment_method":
                this.paymentDone = false;
                this.statusMessage = 'Your payment was not successful, please try again.';
                break;
            default:
                this.paymentDone = false;
                this.statusMessage = 'Something went wrong.';
                break;
        }

        return false;
    }

    showToast(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    async handleSubmit(event){
        event.preventDefault();
        this.isLoading = true;
        const { error, paymentIntent } = await this.stripe.confirmPayment({
            elements: this.elements,
            confirmParams: {
            // Make sure to change this to your payment completion page
            return_url: document.location.href,
            },
            redirect: "if_required"
        });
        
        this.isLoading = false;

        if(paymentIntent != undefined ) {
            this.checkStatusAndIsLoadedFirstTime(paymentIntent);
            this.handleChange(JSON.stringify(paymentIntent));
            return 0;
        }

        if (error != undefined && (error.type === "card_error" || error.type === "validation_error" || error.type === "invalid_request_error")) {
            this.showToast('Stripe Payment', error.message, 'error');
        } else if(error != undefined && paymentIntent == undefined) {
            this.showToast('Stripe Payment', JSON.stringify(error), 'error');
        }
        return 0;
    }
}