import { LightningElement, api, track } from 'lwc';

export default class VisualPicker extends LightningElement {
    @api typeCollection;
    @api selectedValue;
    @api fieldname;
    @track selectedOption;
    
    handleChange(event) {   
        let tempObj = this.cloneObject(this.selectedValue);
        tempObj[event.target.name] = event.target.value;
        this.selectedValue = tempObj;

        const customevent = new CustomEvent('fieldvalueupdate', {
            detail: {selectedValue:this.selectedValue}
        });
        this.dispatchEvent(customevent);
    }

    //Get Javascript object equivalent to Proxy
    cloneObject(obj){
        return JSON.parse(JSON.stringify(obj));
    }
    renderedCallback() {
        this.updateRadioboxSelection(this.selectedValue);
    }
    @api
    updateSelectedValue(selectedValue) {
        this.updateRadioboxSelection(selectedValue);
    }
    updateRadioboxSelection(selectedValue) {
        if (selectedValue != null 
            && selectedValue[this.fieldname] != null
            && this.template.querySelector('[data-id="' + selectedValue[this.fieldname] + '"]') != null) {
              this.template.querySelector('[data-id="' + selectedValue[this.fieldname] + '"]').checked = true;
        }
    }
}