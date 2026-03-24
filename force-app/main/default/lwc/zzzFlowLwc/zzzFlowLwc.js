import { LightningElement, track, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';


export default class ZzzFlowLwc extends LightningElement {
    @track _txtBoxVal = '';
    @api availableActions = [];


    @api
    get txtBoxVal() {
        return this._txtBoxVal;
    }

    set txtBoxVal(val) {
        this._txtBoxVal = val;
    }

    handleChange(event) {
        this._txtBoxVal = event.target.value;
    }

    //Change attribute on Flow
    handleClick(event) {
        const attributeChangeEvent = new FlowAttributeChangeEvent('txtBoxVal', this._txtBoxVal);
        this.dispatchEvent(attributeChangeEvent);
    }

    //Hook to Flow's Validation engine
    @api
    validate() {
        if (!this._txtBoxVal.includes('oracle')) {
            return { isValid: true };
        }
        //If the component is invalid, return the isValid parameter as false and return an error message. 
        return {
            isValid: false,
            errorMessage: 'You cannot have string oracle in String'
        };
    }

    //Go to Next screen of Flow
    handleNext(event) {
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}