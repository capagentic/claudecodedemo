import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import invokeSummaryGPTJob from '@salesforce/apex/ProcessCallTranscriptionHomeController.invokeSummaryGPTJob';
import runSummaryGPTJob from '@salesforce/apex/ProcessCallTranscriptionHomeController.runSummaryGPTJob';
import createMessageForSummaryGPTJob from '@salesforce/apex/ProcessCallTranscriptionHomeController.createMessageForSummaryGPTJob';
import pushCallTranscription from '@salesforce/apex/ProcessCallTranscriptionHomeController.pushCallTranscription';

import { NavigationMixin } from 'lightning/navigation';


export default class ProcessCallTranscriptionHome extends NavigationMixin(LightningElement) {


    //THIS COMPONENT IS NOT BEING USED
    
    @api isLoaded = false;

    _recordId;

    @api set recordId(value) {
         this._recordId = value;

         // do your thing right here with this.recordId / value
        // this.invokeGPT();
    }

    get recordId() {
        return this._recordId;
    }

    connectedCallback() {
        this.isLoaded = true;
    }

    // showToast(title, message, variant) {
    //     this.isLoaded = false;
    //     this.dispatchEvent(
    //         new ShowToastEvent({
    //             title: title || 'Success',
    //             message: message || 'Meeting Record Updated!',
    //             variant: variant || 'success'
    //         })
    //     ); 
    // }

    // invokeGPT() {
        
    //     invokeSummaryGPTJob({
    //         recordId: this.recordId
    //     }).then(success => {
    //         pushCallTranscription({
    //             recordId: this.recordId
    //         }).then(pushResult => {
    //             createMessageForSummaryGPTJob( {
    //                 recordId: this.recordId
    //             }).then(success => {
    //                 runSummaryGPTJob({
    //                     recordId: this.recordId
    //                 }).then(runresult => {
    //                     console.log('success: '+success);
    //                     this.showToast('Success', 'The record is processing and will be updated in a few minutes', 'success');
    //                     this.dispatchEvent(new CloseActionScreenEvent());
    //                 }).catch(runerror=> {
    //                     console.log('error: '+runerror);
    //                     this.showToast('Error', runerror.body.message, 'error');
    //                     this.dispatchEvent(new CloseActionScreenEvent());
    //                 });
    //             }).catch(messageerror => {
    //                 console.log('error: '+messageerror);
    //                 this.showToast('Error', messageerror.body.message, 'error');
    //                 this.dispatchEvent(new CloseActionScreenEvent());
    //             });
    //         }).catch(error => {

    //         })
    //     }).catch(error=> {
    //         console.log('error: '+error);
    //         this.showToast('Error', error.body.message, 'error');
    //         this.dispatchEvent(new CloseActionScreenEvent());
    //     });
    // }

    invokeGPT(){
        //THIS COMPONENT IS NOT BEING USED
        // invokeSummaryGPTJob({
        //     recordId: this.recordId
        // }).then(success => {
        //     // runSummaryGPTJob({
        //     //     recordId: this.recordId
        //     // }).then(runresult => {
        //         pushCallTranscription( {
        //             recordId: this.recordId
        //         }).then(success => {
        //             createMessageForSummaryGPTJob({
        //                 recordId: this.recordId,
        //                 assessmentType: 'assessment'
        //             }).then(pushResult => {
        //                 runSummaryGPTJob({
        //                     recordId: this.recordId
        //                 }).then(runresult => {
        //                     createMessageForSummaryGPTJob({
        //                         recordId: this.recordId,
        //                         assessmentType: 'next_steps'
        //                     }).then(pushResult => {
        //                         runSummaryGPTJob({
        //                             recordId: this.recordId
        //                         }).then(runresult => {

        //                             console.log('success: '+runresult);
        //                             this.showToast('Success', 'The record is processing and will be updated in a few minutes', 'success');
        //                             this.dispatchEvent(new CloseActionScreenEvent());
        //                         }).catch(error => {
        //                             console.log('error: '+error);
        //                             this.showToast('Error', error.body.message, 'error');
        //                             this.dispatchEvent(new CloseActionScreenEvent());
        //                         });
        //                     }).catch(error =>{
        //                         console.log('error: '+error);
        //                         this.showToast('Error', error.body.message, 'error');
        //                         this.dispatchEvent(new CloseActionScreenEvent());
        //                     }); 
        //                 }).catch(error => {
        //                     console.log('error: '+error);
        //                     this.showToast('Error', error.body.message, 'error');
        //                     this.dispatchEvent(new CloseActionScreenEvent());
        //                 })
        //             }).catch(runerror=> {
        //                 console.log('error: '+runerror);
        //                 this.showToast('Error', runerror.body.message, 'error');
        //                 this.dispatchEvent(new CloseActionScreenEvent());
        //             });
        //         }).catch(messageerror => {
        //             console.log('error: '+messageerror);
        //             this.showToast('Error', messageerror.body.message, 'error');
        //             this.dispatchEvent(new CloseActionScreenEvent());
        //         });
        //     // }).catch(error => {
        //     //     console.log('error: '+error);
        //     //     this.showToast('Error', error.body.message, 'error');
        //     //     this.dispatchEvent(new CloseActionScreenEvent());
        //     // })
        // }).catch(error=> {
        //     console.log('error: '+error);
        //     this.showToast('Error', error.body.message, 'error');
        //     this.dispatchEvent(new CloseActionScreenEvent());
        // });
    }
}