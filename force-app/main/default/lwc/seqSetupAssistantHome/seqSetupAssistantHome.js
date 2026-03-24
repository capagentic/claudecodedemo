import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getPermissionSetIds from '@salesforce/apex/seqSetupAssistantController.getPermissionSetIds';
// import setRunningUserForPlatformEvent from '@salesforce/apex/seqSetupAssistantController.setRunningUserForPlatformEvent';
// import CSPMapsScreenshots from '@salesforce/resourceUrl/CSPMapsScreenshots';
// import FileSettingScreenshot from '@salesforce/resourceUrl/FileSettingScreenshot';
// import ClassicEmailTemplateScreenshot from '@salesforce/resourceUrl/ClassicEmailTemplateScreenshot';
// import getRunningUserForPlatformEvent from '@salesforce/apex/seqSetupAssistantController.getRunningUserForPlatformEvent';
export default class SeqSetupAssistantHome extends NavigationMixin(LightningElement) {
    
    @api selectedUserId;
    @api selecteRecordValue;

    // permissionsetById;
    // CSPMapsScreenshots = CSPMapsScreenshots;
    // FileSettingScreenshot = FileSettingScreenshot;
    // ClassicEmailTemplateScreenshot = ClassicEmailTemplateScreenshot;
    // userSearchPlaceHolderText = 'Select User';
  
    // connectedCallBack() {
    //     getPermissionSetIds().then(result => {
    //         this.permissionsetById = JSON.parse(result);
    //     }).catch(error => {
    //         this.handleerror(error);
    //     });
    //     getRunningUserForPlatformEvent().then(result => {
    //         var userdetailsMap = JSON.parse(result);
    //         this.selectedUserId = userdetailsMap['userId'];
    //         this.selecteRecordValue = userdetailsMap['userName'];

    //     }).catch(error => {
    //         this.handleerror(error);
    //     });
    // }

    // navigateToSalesforceCSPSetup () {
    //     var type = 'standard__webPage';
    //     var url = '/lightning/setup/SecurityCspTrustedSite/home';
    //     this.navigateToPageHelper(type, url);
    // }

    // navigateToSalesforceFileSetup () {
    //     var type = 'standard__webPage';
    //     var url = '/lightning/setup/FilesGeneralSettings/home';
    //     this.navigateToPageHelper(type, url);
    // }

    // navigateToPackageLicensePage() {
    //     var type = 'standard__webPage';
    //     var url = '/lightning/setup/ImportedPackage/0A35g000000UksC/view';
    //     this.navigateToPageHelper(type, url);
    // }

    // navigateToClassicEmailTemplate() {
    //     var type = 'standard_webPage';
    //     var url = '/lightning/setup/CommunicationTemplatesEmail/home';
    //     this.navigateToPageHelper(type, url);
    // }

    // //Navigate to visualforce page
    // navigateToPageHelper(type, url) {
    //     this[NavigationMixin.GenerateUrl]({
    //         type: type,//'standard__webPage',
    //         attributes: {
    //             url: url//'/apex/AccountVFExample?id=' + this.recordId
    //         }
    //     }).then(generatedUrl => {
    //         window.open(generatedUrl);
    //     });
    // }

    // //this method is used to call it from child component so we can use same code if required.
    // navigateToPage(event) {
    //     var type = event.detail.type;
    //     var url = event.detail.url;
    //     this.navigateToPageHelper(type, url);
    // }

    // handleerror(event) {
    //     this.showToastMessage('Error creating record', error.body.message, 'error');
    // } 
    // showToastMessage(title, message, variant) {
    //     new ShowToastEvent({
    //         title: title,
    //         message: message,
    //         variant: variant,
    //     });
    // }

    // handleUserSearch(event) {

    //     const selectedRecordId = event.detail.selectedRecordId;
    //     const selecteRecordValue = event.detail.selectedValue;
    //     if (!selectedRecordId || !selecteRecordValue) {
    //         return;
    //     }
    //     this.selectedUserId = selectedRecordId;
    //     this.selecteRecordValue = selecteRecordValue;
    //     console.log('selectedRecordId: ' + selectedRecordId);
    //     console.log('selecteRecordValue: ' + selecteRecordValue);

    // }

    // setRunningUser() {
    //     if(this.selectedUserId === '' || this.selectedUserId === undefined) {
    //         this.showToastMessage('Error selecting record', 'Please select valid User', 'error');
    //         return;
    //     }
    //     //update running user from here in Apex
    //     setRunningUserForPlatformEvent({userId: this.selectedUserId}).then(result => {
    //         this.showToastMessage('Success', 'User has been successfully set', 'success');
    //     }).catch(error => {
    //         this.handleerror(error);
    //     });
    // }

    // cancelsetRunningUser() {

    // }

    // navigateToQuestionFieldSet() {
    //     var objectKeyprefix = '01I5g000001ytJC';
    //     var fieldSetId = '0IX5g000000PSilGAG';
    //     var url = 'lightning/setup/ObjectManager/'+objectKeyprefix+'/FieldSets/'+fieldSetId+'/view';
    //     var type = 'standard_webPage';
    //     this.navigateToPageHelper(type, url);
    // }
    
    // navigateToFormFieldSet() {
    //     var objectKeyprefix = '01I5g000001yt9f';
    //     var fieldSetId = '0IX5g000000PSj0GAG';
    //     var url = 'lightning/setup/ObjectManager/'+objectKeyprefix+'/FieldSets/'+fieldSetId+'/view';
    //     var type = 'standard_webPage';
    //     this.navigateToPageHelper(type, url);
    // }
}