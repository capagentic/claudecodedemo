import { LightningElement, track } from 'lwc';
import getGptJobList from '@salesforce/apex/ChatGptManagerController.getGptJobList';
import getCurrentUsage from '@salesforce/apex/ChatGptManagerController.getCurrentUsage';



export default class GptManager extends LightningElement {

    @track jobs;
    @track currentToken;
    @track showSpinner = false;

    jobColumns = [
        {
            label: 'Link', fieldName: 'link', type: 'url', typeAttributes: {
                label: {
                    fieldName: 'name'
                }, target: '_blank'
            },
            sortable: true,
            initialWidth: 120
        },
        { label: 'Token Consumed', fieldName: 'totalToken', wrapText: true, sortable: true, initialWidth: 160 },
        { label: 'Type', fieldName: 'type', wrapText: true, sortable: true },
        { label: 'Created Date', fieldName: 'createdDate', wrapText: false, sortable: true, initialWidth: 280 },
        { label: 'Created By', fieldName: 'createdBy', wrapText: false, sortable: true, initialWidth: 180 },
    ];

    connectedCallback() {
        this.handleGetGptJobList();
        this.handleGetCurrentUsage();
    }

    handleGetGptJobList() {
        this.showSpinner = true;
        getGptJobList()
            .then((result) => {
                var resObj = JSON.parse(result);
                if (resObj.statusCode == 2000) {
                    this.jobs = resObj.responseDetails;
                    console.log('********* handleGetGptJobList>resObj.responseDetails: ' + JSON.stringify(resObj.responseDetails));
                } else {
                    console.log('********* error: ' + resObj.responseDetails);
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    handleGetCurrentUsage() {
        this.showSpinner = true;
        getCurrentUsage()
            .then((result) => {
                var resObj = JSON.parse(result);
                if (resObj.statusCode == 2000) {
                    this.currentToken = resObj.responseDetails;
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error(error);
            });
    }
}