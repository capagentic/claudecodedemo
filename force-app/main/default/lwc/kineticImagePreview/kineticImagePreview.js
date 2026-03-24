import { LightningElement, api } from 'lwc';
import getImageURLForRelatedRecord from '@salesforce/apex/ImagePreviewController.getImageURLForRelatedRecord';

export default class KineticImagePreview extends LightningElement {
    @api imageUrl;
    @api recordId;
    @api objectApiName;
    @api urlFieldName;

    connectedCallback() {
        getImageURLForRelatedRecord({objectAPIName: this.objectApiName, recordId: this.recordId, urlFieldName: this.urlFieldName}).then(data => {
            this.imageUrl = data;
        }).catch(error => {
            this.imageUrl = '';
            alert(error);
            console.log(error);
        })
    }
}