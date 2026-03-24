import { LightningElement, track } from 'lwc';
import hasManagerPanelAccess from '@salesforce/apex/ChatGptManagerController.hasManagerPanelAccess';


export default class ChatgptManagerPanel extends LightningElement {

    showPanel = false;
    @track showAdvancedSetting = false;
    @track tempBtnVariant = {};
    connectedCallback() {
        console.log('******** connectedCallback');
        this.checkHasManagerPanelAccess();
        this.initVariables();
    }

    checkHasManagerPanelAccess() {
        hasManagerPanelAccess()
            .then((result) => {
                var resObj = JSON.parse(result);
                if (resObj.statusCode == 2000) {
                    this.showPanel = resObj.responseDetails;
                } else {
                    console.log('********* error: ' + resObj.responseMessage);
                }
            }).catch((error) => {
                console.error(error);
            });
    }

    initVariables() {
        this.tempBtnVariant['Low'] = 'neutral';
        this.tempBtnVariant['Medium'] = 'neutral';
        this.tempBtnVariant['High'] = 'neutral';
    }

    handleAdvancedSetting() {
        console.log('handleAdvancedSetting');
        this.showAdvancedSetting = !this.showAdvancedSetting;
    }


    handleTemperatureSetting(event) {
        const buttonLabel = event.target.label;
        console.log('handleTemperatureSetting>buttonLabel=' + buttonLabel);
        this.initVariables();
        var v = 'success';
        if (buttonLabel == 'Low') {
            v = 'success';
        } else if (buttonLabel == 'Medium') {
            v = 'destructive-text';
        } else if (buttonLabel == 'High') {
            v = 'destructive';
        }
        this.tempBtnVariant[buttonLabel] = v;
    }
}