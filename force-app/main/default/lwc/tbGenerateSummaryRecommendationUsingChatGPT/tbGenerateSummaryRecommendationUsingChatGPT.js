import { api, LightningElement, track } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGPTParameters from '@salesforce/apex/tbChatGPTController.getGPTParameters';
import createGPTJob from '@salesforce/apex/tbChatGPTController.createGPTJob';


export default class TbGenerateSummaryRecommendationUsingChatGPT extends LightningElement {

    gptParameter = {};
    response = undefined;
    showSpinner = false;
    @api recordId;
    @track summary;
    @api autoGenerateReportOnLoad = false;
    retryCount = 0;
    connectedCallback() {
        this.showSpinner = true;
        // this.gptParameter['yourrole'] = 'food safety inspector';
        // this.gptParameter['description'] = 'summary and recommendations';
        // this.gptParameter['inspectionobjective'] = 'improve food safety';
        this.gptParameter['yourrole'] = '';
        this.gptParameter['description'] = '';
        this.gptParameter['inspectionobjective'] = '';
        this.summary = '<h2>Summary </h2>';
        if (this.isValidValue(this.recordId)) {
            getGPTParameters({ inspRecordId: this.recordId }).then(inspRecListString => {
                var gptParameterObj = JSON.parse(inspRecListString);
                console.log(gptParameterObj);
                if (gptParameterObj == null) {
                    this.showSpinner = false;
                    this.showErrorMessage('Please ensure that GPT parameters are set on template');
                    this.closeQuickAction();
                } else {
                    if (gptParameterObj.hasOwnProperty('yourrole')) {
                        this.gptParameter['yourrole'] = gptParameterObj['yourrole'];
                    }
                    if (gptParameterObj.hasOwnProperty('checklistneed')) {
                        this.gptParameter['description'] = gptParameterObj['checklistneed'];
                    }
                    if (gptParameterObj.hasOwnProperty('inspectionobjective')) {
                        this.gptParameter['inspectionobjective'] = gptParameterObj['inspectionobjective'];
                    }
                    if (this.autoGenerateReportOnLoad) {
                        this.generateInspectionSummary(null);
                    }
                    this.showSpinner = false;
                }
            }).catch(error => {
                this.showErrorMessage(error.body.message);
                this.showSpinner = false;
            });
        } else {
            this.showSpinner = false;
        }

    }

    handleGPTParameterInputChange(event) {
        this.gptParameter[event.target.dataset.name] = event.target.value;
    }

    generateInspectionSummary(event) {
        this.showSpinner = true;

        if (!this.isValidValue(this.gptParameter['yourrole'])
            || !this.isValidValue(this.gptParameter['description'])
            || !this.isValidValue(this.gptParameter['inspectionobjective'])) {
            this.showSpinner = false;
            this.showErrorMessage('Please provide required values.');
            return 0;
        }

        createGPTJob({ gptParameterString: JSON.stringify(this.gptParameter), inspRecordId: this.recordId }).then(success => {
            var res = JSON.parse(success);
            console.log(res);

            if (res.statusCode == 2000) {
                this.showSpinner = false;
                this.closeQuickAction();
                const popupevent = new ShowToastEvent({
                    title: 'Summary Request Successful',
                    message: 'You will be notified shortly when your Summary and Activities have been generated',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(popupevent);
            } else if (res.statusCode == 2100) {
                if (res.responseMessage == 'duplicate jobs') {
                    var exJob = res.responseDetails;
                    var message = 'An existing job ' + exJob.Name + ' has been already created. Please check again.'
                    this.showSpinner = false;
                    this.closeQuickAction();
                    const popupevent = new ShowToastEvent({
                        title: 'Warning: existing job identified',
                        message: message,
                        variant: 'warning',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(popupevent);
                }
            } else {

            }


        }).catch(error => {
            this.showSpinner = false;
            this.closeQuickAction();
            this.showErrorMessage('We encountered an issue when creating a job. Please try again later. ');
        });
    }

    closeQuickAction() {
        const closepopup = new CustomEvent('closepopup');
        // Dispatches the event.
        this.dispatchEvent(closepopup);
    }

    isValidValue(valObj) {
        if (valObj != undefined && valObj != '' && valObj.length != 0) {
            return true;
        }
        return false;
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Inspection',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

}