import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactDetails from '@salesforce/apex/SeqSenderController.getContactDetails';

export default class RecordListBuilder extends LightningElement {

    @api sectionTitle;
    @api allAvailableRecordsById = {};
    @api selectedRecordsCount;
    @api columnsToDisplay;
    @track recordsToDisplay = [];
    recordsToDisplayMapById = {};
    @api isLoading = false;
    @api searchPlaceHolderText;

    connectedCallback() {
        this.isLoading = true;
        this.recordsToDisplay = Object.values(this.allAvailableRecordsById);
        this.maintainRecordsDisplayMap();
    }
    
    // handleSearch(event){
    //     this.isLoading = true;
    //     var searchText = event.target.value;
        
    //     if(searchText.length < 3) {
    //         this.recordsToDisplay = Object.values(this.allAvailableRecordsById);
    //     } else {
    //         searchText = searchText.toLowerCase();
    //         var allRecordsWrapperList = Object.values(this.allAvailableRecordsById);
    //         var columnsToDisplay = this.columnsToDisplay;
    //         this.recordsToDisplay  = allRecordsWrapperList.filter(function (record) {
    //             var recordFound = false;
    //             for(var i=0;i<columnsToDisplay.length;i++) {
    //                 if(record[columnsToDisplay[i].name] != undefined 
    //                     && (record[columnsToDisplay[i].name].toLowerCase().includes(searchText)
    //                         || (columnsToDisplay[i].isReferenceField 
    //                             && record[columnsToDisplay[i].referenceFieldAPIName]!= undefined 
    //                             && record[columnsToDisplay[i].referenceFieldAPIName].Name != undefined 
    //                             && record[columnsToDisplay[i].referenceFieldAPIName].Name.toLowerCase().includes(searchText)))
    //                  ) {
    //                     recordFound = true;
    //                     break;
    //                 }
    //             }
    //             if(recordFound === true) {
    //                 return true;
    //             }
    //             return false;
    //         });
    //     }

    //     if(this.recordsToDisplay.length == 0){
    //         this.isLoading = false;
    //         this.showErrorMessage('No record(s) found, Please use correct search string');
    //     }
    //     this.maintainRecordsDisplayMap();
    // }
    
    handleSearch(event) {

        const selectedRecordId = event.detail.selectedRecordId;
        const selecteRecordValue = event.detail.selectedValue;
        if (!selectedRecordId || !selecteRecordValue) {
            return;
        }

        if(this.recordsToDisplayMapById.hasOwnProperty(selectedRecordId)
            && this.allAvailableRecordsById.hasOwnProperty(selectedRecordId)) {
                if(this.recordsToDisplayMapById[selectedRecordId].isselected === true) {
                    this.selectedRecordsCount = this.selectedRecordsCount - 1;
                }
                this.handleSelectRecord(selectedRecordId, true);
        } else {
            this.isLoading = true;
            getContactDetails({ selectedContactIds: [selectedRecordId]}).then((records) => {
                var tempAllAvailableRecords = this.cloneObject(this.allAvailableRecordsById);
                var tempRecordsToDisplayMapById = this.cloneObject(this.recordsToDisplayMapById);
                for(var i=0;i<records.length;i++) {
                    var rec = records[i];
                    if(!rec.hasOwnProperty('MobilePhone')) {
                        rec['MobilePhone'] = '';
                    }
                    if(!rec.hasOwnProperty('Email')) {
                        rec['Email'] = '';
                    }
                    if(!rec.hasOwnProperty('Title')) {
                        rec['Title'] = '';
                    }
                    if(!rec.hasOwnProperty('AccountId') || !rec.hasOwnProperty('Account')){
                        rec['AccountId'] = '';
                        rec['Account'] = {'Name' : '', 'Id': ''};
                    }
                    rec['isselected'] = false;
                    rec['rowclass'] = 'slds-hint-parent';
                    this.recordsToDisplay.push(rec);
                    tempAllAvailableRecords[rec.Id] = rec;
                    tempRecordsToDisplayMapById[rec.Id] = rec;
                }
                this.allAvailableRecordsById = tempAllAvailableRecords;
                this.recordsToDisplayMapById = tempRecordsToDisplayMapById;

                this.handleSelectRecord(selectedRecordId);
                this.isLoading = false;
            }).catch((error) => {
                this.handleErrorBlock(error);
            });
        }
    }
    handleErrorBlock(error) {
        console.log('error',error);
        this.isLoading =false;
        this.showErrorMessage(error.body.message);
    }
    maintainRecordsDisplayMap() {
        this.recordsToDisplayMapById = {};
        this.recordsToDisplay = this.recordsToDisplay.slice(0, 200);
        for(var i=0;i<this.recordsToDisplay.length;i++){
            this.recordsToDisplayMapById[this.recordsToDisplay[i].Id] = this.recordsToDisplay[i];
        }
        this.isLoading = false;
    }
    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Kinetic Form Sender',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    
    selectrecord(event) {
        this.isLoading = true;
        var selectedRecordId = event.target.name;
        this.handleSelectRecord(selectedRecordId);
    }
    handleSelectRecord(selectedRecordId, selectRecordForcefully) {
        if(this.recordsToDisplayMapById.hasOwnProperty(selectedRecordId)
            && this.allAvailableRecordsById.hasOwnProperty(selectedRecordId)) {
            var tempObj = this.cloneObject(this.allAvailableRecordsById);
            var recordwrapper = tempObj[selectedRecordId];
            if(selectRecordForcefully != undefined && selectRecordForcefully !== null) {
                recordwrapper.isselected = selectRecordForcefully;
            } else {
                recordwrapper.isselected = !recordwrapper.isselected;
            }
            recordwrapper['rowclass'] = 'slds-hint-parent';
            if(recordwrapper.isselected){
                recordwrapper.rowclass = recordwrapper.rowclass + ' slds-is-selected';
                this.selectedRecordsCount = this.selectedRecordsCount + 1;
            } else {
                this.selectedRecordsCount = this.selectedRecordsCount - 1;
            }
            tempObj[selectedRecordId] = recordwrapper;
            this.allAvailableRecordsById = tempObj;
            
            var displayTempMap = this.cloneObject(this.recordsToDisplayMapById);
            displayTempMap[selectedRecordId] = recordwrapper;
            this.recordsToDisplayMapById = displayTempMap;
            this.recordsToDisplay = Object.values(this.recordsToDisplayMapById);
            this.maintainRecordsDisplayMap();

            const customevent = new CustomEvent('recordselected', {
                detail: {allAvailableRecordsById:this.allAvailableRecordsById,
                        selectedRecordsCount: this.selectedRecordsCount}
            });
            this.dispatchEvent(customevent);
            this.isLoading = false;
        } else {
            this.isLoading = false;
        }
    }
    //Get Javascript object equivalent to Proxy
    cloneObject(obj){
        return JSON.parse(JSON.stringify(obj));
    }
    // get norecordsfound() {
    //     return (this.recordsToDisplay.length <= 0);
    // }
}