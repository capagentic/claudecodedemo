import { LightningElement, track } from 'lwc';
//import getKineticCustomSettingMetadataDetails from '@salesforce/apex/seqSetupAssistantController.getKineticCustomSettingMetadataDetails';
//import getKineticCustomSettingRecordDetails from '@salesforce/apex/seqSetupAssistantController.getKineticCustomSettingRecordDetails';
export default class SeqSetupAssistantCustomSetting extends LightningElement {
     @track fieldkokineticssetting = {
         'createevent': true, 
         'googleapikey': '',
         'formrendereurl': '',
         'location': '',
         'smstemplate': '',
         'createeventhelp': 'createeventhelp',
         'googleapikeyhelp': 'googleapikeyhelp',
         'formrendereurlhelp': 'formrendereurlhelp',
         'smstemplatehelp' : 'smstemplatehelp',
         'createeventlabel': 'createeventlabel',
         'googleapikeylabel': 'googleapikeylabel',
         'formrendereurllabel': 'formrendereurllabel',
         'smstemplatelabel' : 'smstemplatelabel',
         'objkeyprefix': '',
         'objlabel': ''
     };

    //  renderedCallback() {
    //      console.log('renderedCallback ... called');
    //      if(this.fieldkokineticssetting.objkeyprefix === '') {
    //          this.getKineticCustomSettingMetadataDetails();
    //      }
    //      console.log('connected call back in child');
    //  }

    //  getKineticCustomSettingMetadataDetails() {
    //      getKineticCustomSettingMetadataDetails().then(result => {
           
    //          var mapofMap = JSON.parse(result);
    //          this.fieldkokineticssetting.objkeyprefix = mapofMap['settingkeyPrefix'];
    //          this.fieldkokineticssetting.objlabel = mapofMap['settinglabel'];
    //          this.fieldkokineticssetting.createeventhelp = mapofMap['createeventhelptext'];
    //          this.fieldkokineticssetting.createeventlabel = mapofMap['createeventlabel'];
    //          this.fieldkokineticssetting.googleapikeyhelp = mapofMap['googleapikeyhelptext'];
    //          this.fieldkokineticssetting.googleapikeylabel = mapofMap['googleapikeylabel'];
    //          this.fieldkokineticssetting.formrendereurlhelp = mapofMap['formrendereurlhelptext'];
    //          this.fieldkokineticssetting.formrendereurllabel = mapofMap['formrendereurllabel'];
    //          this.fieldkokineticssetting.smstemplatehelp = mapofMap['smstemplatehelptext'];
    //          this.fieldkokineticssetting.smstemplatelabel = mapofMap['smstemplatelabel'];

    //      }).catch(error => {
    //          this.handleError(error);
    //      });
    //      getKineticCustomSettingRecordDetails().then(result => {
    //          var settingValue = JSON.parse(result);
    //          this.fieldkokineticssetting.createevent = settingValue.Kinetics__Create_Event__c;
    //          this.fieldkokineticssetting.googleapikey = settingValue.Kinetics__Google_API_Key__c;
    //          this.fieldkokineticssetting.formrendereurl = settingValue.Kinetics__Form_Renderer_Page_URL__c;
    //          this.fieldkokineticssetting.smstemplate = settingValue.Kinetics__SMS_Template__c;

    //      }).catch(error => {
    //          this.handleError(error);
    //      });
    //  }
    //  handleError(error) {
    //      const navigateEvent = new CustomEvent(
    //          'handleerror', {
    //              detail: error
    //          });
    //      this.dispatchEvent(navigateEvent);
    //  }

    //  navigateToCustomSettingPage(event) {
    //      var objkeyprefix = 'a07';//event.target.id;
    //      var type = 'standard__webPage';
    //      var url = '/lightning/setup/CustomSettings/page?address=/setup/ui/listCustomSettingsData.apexp?id='+objkeyprefix;

    //      const navigateEvent = new CustomEvent(
    //          'navigatetopage', {
    //              detail: {
    //                  'type': type,
    //                  'url': url
    //                  }
    //          });
    //      this.dispatchEvent(navigateEvent);
    //  }

    //  saveCustomSettingSection() {
    //      console.log(JSON.stringify(this.fieldkokineticssetting));
    //  }

    //  cancelCustomSettingSection() {
    //      console.log(JSON.stringify(this.fieldkokineticssetting));
    //      this.toggleCustomSettingSection();
    //  }

    //  handleInputFieldChange(event) {
    //      if(event.target.name == 'createevent') {
    //          this.fieldkokineticssetting[event.target.name] = !this.fieldkokineticssetting[event.target.name];
    //      } else {
    //          this.fieldkokineticssetting[event.target.name] = event.target.value;
    //      }
    //  }
}