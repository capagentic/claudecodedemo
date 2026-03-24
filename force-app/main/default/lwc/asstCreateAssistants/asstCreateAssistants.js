import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAssistants from '@salesforce/apex/AsstCreateAssistantsController.createAssistants';



export default class AsstCreateAssistants extends LightningElement {

    @api isLoaded = false;
    
    connectedCallback() {
        this.isLoaded = false;
    }

    showToast(title, message, variant) {
        this.isLoaded = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Success',
                message: message || 'Assistant Records created successfully',
                variant: variant || 'success'
            })
        ); 
    }
   
    createRecords(event) {
        this.isLoaded = true;
       
        createAssistants({}).then(success => {
            
            this.showToast('Success', 'Assistant Records created successfully', 'success');
            this.isLoaded = false;
        }).catch(error => {
            this.showToast('Error', error.body.message, 'error');
            this.isLoaded = false;
        });
    }
}