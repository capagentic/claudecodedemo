import { LightningElement, api } from 'lwc';
import getAllTemplateDetailsByTemplateId from '@salesforce/apex/TemplatesManager.getAllTemplateDetailsByTemplateId';

export default class TemplateExporter extends LightningElement {
    @api recordId;

    connectedCallback() {
    }

    renderedCallback() {
        console.log('22 recordId=' + this.recordId);

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

                var element = document.createElement('a');
                element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(JSON.stringify(resObj)));
                element.setAttribute('download', 'TemplateExport.txt');
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);
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