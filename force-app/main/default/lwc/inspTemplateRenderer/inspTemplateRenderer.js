import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class InspTemplateRenderer extends NavigationMixin(LightningElement) {
    @api inspectionRecordId;
    connectedCallback(){
       this.navigateToTemplate();
    }

    navigateToTemplate() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__inspTemplateQuestionRenderer'
            },
            state: {
                c__inspectionRecordId: this.inspectionRecordId
            }
        });
    }
}