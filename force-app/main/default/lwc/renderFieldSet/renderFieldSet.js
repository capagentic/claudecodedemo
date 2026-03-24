import { LightningElement, api, track } from 'lwc';

export default class RenderFieldSet extends LightningElement {

    @api objectname;
    @api fieldsetname;
    @api isforinput;
    @api extraDetailFields = [];
    @api recordId;
    @api selectedvalue;
    @track isLoading = true;
    @api cardtitle;

    connectedCallback(){
        this.isLoading = false;
    }
    handleChange(event) {   
        let tempObj = this.cloneObject(this.selectedvalue);
        tempObj[event.target.fieldName] = event.target.value;
        this.selectedvalue = tempObj;

        const customevent = new CustomEvent('fieldvalueupdate', {
            detail: {selectedValue:this.selectedvalue}
        });
        this.dispatchEvent(customevent);
    }

    //Get Javascript object equivalent to Proxy
    cloneObject(obj){
        return JSON.parse(JSON.stringify(obj));
    }
}