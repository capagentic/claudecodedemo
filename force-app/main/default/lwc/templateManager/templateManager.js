import { LightningElement, api } from 'lwc';
import getAllTemplateDetailsByTemplateId from '@salesforce/apex/TemplatesManager.getAllTemplateDetailsByTemplateId';

export default class TemplateManager extends LightningElement {
    @api recordId;

    connectedCallback() {
    }

    renderedCallback() {
        console.log('2 recordId=' + this.recordId);

        if (this.recordId) {
            console.log('1 getAllTemplateDetailsByTemplateIdDB...');
            this.getAllTemplateDetailsByTemplateIdDB();
        }
    }

    getAllTemplateDetailsByTemplateIdDB() {
        console.log('getAllTemplateDetailsByTemplateIdDB...');
        getAllTemplateDetailsByTemplateId({ templateId: this.recordId })
            .then((result) => {
                var resObj = JSON.parse(result);

                console.log(JSON.stringify(resObj));
            })
            .catch((error) => {
                // this.error = error;
                // this.errorCheck = true;
                // this.errorMessage = error.body.message;
            });
    }

    // getQueryParameters() {
    //     var params = {};
    //     var search = location.search.substring(1);
    //     if (search) {
    //         params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
    //             return key === "" ? value : decodeURIComponent(value)
    //         });
    //     }
    //     return params;
    // }
}