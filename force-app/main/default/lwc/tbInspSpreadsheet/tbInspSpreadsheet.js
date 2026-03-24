import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import { loadStyle } from "lightning/platformResourceLoader";
import WrappedHeaderTable from "@salesforce/resourceUrl/WrappedHeaderTable";
import getHeader from '@salesforce/apex/InspSpreadsheetController.getHeader';
import getSpreadsheetData from '@salesforce/apex/InspSpreadsheetController.getSpreadsheetData';
import createCustomObjectRecord from '@salesforce/apex/InspSpreadsheetController.createCustomObjectRecord';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';


export default class TbInspSpreadsheet extends NavigationMixin(LightningElement) {
    @track isQuickAction = false;

    @api recordId;
    @track data = [];
    draftValues = [];
    @api columns;
    rowOffset = 0;
    stylesLoaded = false;

    @track jobName = 'Test Job';
    @track jobNumber = 'TES123HAYW456789';
    @track propertyName = 'ABC Property';
    @track pmName = 'Blake Takata';
    objectapiname = 'Kinetics__Inspection__c';
    @track showHeader = true;

    @track tableStyleClass = 'sdatatable100';


    fields = {
        'Kinetics__Status__c': 'Not Started',
        'Id': undefined
    };
   // existingRecordsList = [];
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('TbInspSpreadsheet>getStateParameters');
        if (currentPageReference.type === "standard__quickAction") {
            this.isQuickAction = true;
            this.recordId = currentPageReference.state.recordId;
            this.fullscreenLink = '/lightning/n/Kinetics__Spreadsheet_Inspection?c__recordId=' + this.recordId;
            this.gotoFullScreen();
        } else if (currentPageReference.type === "standard__recordPage") {
            this.showHeader = false;
        }

        if (currentPageReference.type === "standard__navItemPage") {
            this.recordId = currentPageReference.state.c__recordId;
        }
    }


    @wire(getRecord, {
        recordId: '$recordId', fields: ['Kinetics__Inspection__c.Name',
            'Kinetics__Inspection__c.Kinetics__Spreadsheet_Configuration__r.Name',
            'Kinetics__Inspection__c.Kinetics__Inspection_Date__c',
            'Kinetics__Inspection__c.Owner.Name', 'Kinetics__Inspection__c.Kinetics__Spreadsheet_Answers__c',
            'Kinetics__Inspection__c.Kinetics__Status__c',
            'Kinetics__Inspection__c.Kinetics__Account__r.Name'
        ]
    })
    inspectionRecord({ error, data }) {
        console.log('TbInspSpreadsheet>>inspectionRecord');
        if (data) {
            this.jobName = data.fields.Kinetics__Spreadsheet_Configuration__r.value.fields.Name.value;
            this.jobNumber = data.fields.Name.value;
            this.pmName = data.fields.Owner.value.fields.Name.value;
            this.propertyName = data.fields.Kinetics__Account__r.Name;


            if (data.fields.Kinetics__Status__c.value == 'Not Started') {
                this.fields = {
                    'Kinetics__Status__c': 'In Progress',
                    'Id': this.recordId
                };
                this.updateRecordHelper();
            }
            this.data = [];
            if (data.fields.Kinetics__Spreadsheet_Answers__c.value != undefined) {
                this.data = JSON.parse(data.fields.Kinetics__Spreadsheet_Answers__c.value);
               // this.existingRecordsList = JSON.parse(JSON.stringify(this.data));
            }
        }
        if (error) {
            this.showErrorMessage(error);
        }
    }
    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Spreadsheet',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    renderedCallback() {

        // if (!this.stylesLoaded) {
        //     Promise.all([loadStyle(this, WrappedHeaderTable + '')])
        //         .then(() => {
        //             console.log("Custom styles loaded");
        //             this.stylesLoaded = true;
        //         })
        //         .catch((error) => {
        //             console.error("Error loading custom styles");
        //         });
        // }
    }

    connectedCallback() {
        console.log('TbInspSpreadsheet>connectedCallback>recordId=' + this.recordId);
        // if (!this.stylesLoaded) {
        //     Promise.all([loadStyle(this, WrappedHeaderTable + '')])
        //         .then(() => {
        //             console.log("Custom styles loaded");
        //             this.stylesLoaded = true;
        //         })
        //         .catch((error) => {
        //             console.error("Error loading custom styles");
        //         });
        // }
        this.fullscreenLink = '/lightning/n/Kinetics__Spreadsheet_Inspection?c__recordId=' + this.recordId;
        getHeader({ inspId: this.recordId }).then(result => {
            console.log('TbInspSpreadsheet>getHeader...');
            var res = JSON.parse(result);
            if (res.statusCode == 2000) {
                var responseWrapper = res.responseDetails;
                
                for(var i=0;i<responseWrapper.column.length;i++) {
                    if(responseWrapper.column[i].type=='time') {
                        responseWrapper.column[i].type = 'date';
                        responseWrapper.column[i]['typeAttributes'] = {
                            hour: '2-digit',
                            minute: '2-digit',
                            hour12: true
                        }
                    }
                }
                this.columns = responseWrapper.column;
                this.jobName = responseWrapper.SpreadsheetConf.confName;
                if (this.data.length == 0) {
                    this.handleNewRow();
                }


            } else {
                this.showErrorMessage(res.responseMessage);
            }
        }).catch(error => {
            this.showErrorMessage(error.body.message);
        });

    }


    // getData() {
    //     getSpreadsheetData().then(result => {
    //         console.log('TbInspSpreadsheet>getSpreadsheetData...');
    //         var res = JSON.parse(result);
    //         if (res.statusCode == 2000) {
    //             this.data = res.responseDetails;
    //         }
    //     }).catch(error => {
    //         this.showErrorMessage(error.body.message);
    //     });
    // }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                //this.deleteRow(row);
                console.log('TbInspSpreadsheet>delete row action triggered ');
                break;
            case 'show_details':
                //this.showRowDetails(row);
                console.log('TbInspSpreadsheet>show details action triggered ');
                break;
            default:
        }
    }

    @track saveDraftValues;
    handleSave(event) {
        console.log('TbInspSpreadsheet>handleSave');

        // Clear all datatable draft values
        this.draftValues = event.detail.draftValues;
        this.updateFullData();
        // this.data = this.draftValues;
        this.handleSubmit(event);
    }

    updateFullData() {
        for (var i = 0; i < this.data.length; i++) {
            var localKey = this.data[i].localKey;
            for (var j = 0; j < this.draftValues.length; j++) {
                if (this.draftValues[j].localKey == localKey) {
                    //this.data[i] = this.draftValues[j];
                    let entries = Object.entries(this.draftValues[j]);
                    entries.map( ([key, val] = entry) => {
                        this.data[i][key] = val;
                    });
                }
            }
        }
    }

    handleNewRow(event) {
        var currentDataString = JSON.stringify(this.data);
        var currentData = JSON.parse(currentDataString);
        var newRow = {};
        for (var i = 0; i < this.columns.length; i++) {
            newRow[this.columns[i].fieldName] = undefined;
        }
        newRow['localKey'] = 'key-' + currentData.length;
        currentData.push(newRow);
       // this.existingRecordsList.push(JSON.parse(JSON.stringify(newRow)));
        this.data = currentData;
    }

    handleNewColumn(event) {
        console.log('TbInspSpreadsheet>handleNewColumn...');

        var newColumn = { "label": "Room 4-RH%", "fieldName": "name", "wrapText": true, "editable": true };
        var columnString = JSON.stringify(this.columns);
        var currentColumnes = JSON.parse(columnString);
        currentColumnes.push(newColumn);
        this.columns = currentColumnes;
    }

    handleZoomIn() {
        if (this.tableStyleClass == 'sdatatable100') {
            this.tableStyleClass = 'sdatatable110';
        } else if (this.tableStyleClass == 'sdatatable90') {
            this.tableStyleClass = 'sdatatable100';
        } else if (this.tableStyleClass == 'sdatatable80') {
            this.tableStyleClass = 'sdatatable90';
        } else if (this.tableStyleClass == 'sdatatable70') {
            this.tableStyleClass = 'sdatatable80';
        }
    }

    handleZoomOut() {
        if (this.tableStyleClass == 'sdatatable110') {
            this.tableStyleClass = 'sdatatable100';
        } else if (this.tableStyleClass == 'sdatatable100') {
            this.tableStyleClass = 'sdatatable90';
        } else if (this.tableStyleClass == 'sdatatable90') {
            this.tableStyleClass = 'sdatatable80';
        } else if (this.tableStyleClass == 'sdatatable80') {
            this.tableStyleClass = 'sdatatable70';
        }
    }

    gotoFullScreen() {
        window.location = this.fullscreenLink;
    }

    // deleteRow(row) {
    //     const { id } = row;
    //     const index = this.findRowIndexById(id);
    //     if (index !== -1) {
    //         this.data = this.data
    //             .slice(0, index)
    //             .concat(this.data.slice(index + 1));
    //     }
    // }

    navigateToRecordPage() {

        if (this.recordId !== undefined) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: this.objectapiname,
                    actionName: 'view'
                }
            });
        } else {
            // Navigate to the Question home page
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.objectapiname,
                    actionName: 'home',
                },
            });
        }
    }

    handleSubmit(event) {
        // console.log(this.draftValues);
        // console.log(JSON.parse(JSON.stringify(this.draftValues)));
        this.handleCreateCustomObjectRecords();

    }

    updateInspection() {
        this.fields = {
            'Kinetics__Status__c': 'Complete',
            'Id': this.recordId,
            'Kinetics__Spreadsheet_Answers__c': JSON.stringify(this.data)
        };
        this.isLoading = true;

        this.recordCreaterHelper().
            then(rec => {
                this.recordId = rec.id;
                this.navigateToRecordPage();
            }).catch(error => {
                this.handleErrorBlock(error);
            }
            );
    }

    handleCreateCustomObjectRecords() {
        console.log('TbInspSpreadsheet>handleCreateCustomObjectRecords');
        var updatedValuesRows = JSON.parse(JSON.stringify(this.draftValues));
        var newRecordList = [];
        var updatedRecordList = [];
        for (var i = 0; i < updatedValuesRows.length; i++) {
            var localKey = updatedValuesRows[i].localKey;
            var existingRec = false;
            var existingRecordObj = {};
            for (var j = 0; j < this.data.length; j++) {
                if (this.data[j].localKey == localKey && this.data[j].Id) {
                    existingRec = true;
                    existingRecordObj = this.data[j];
                }
            }
            // if (updatedValuesRows[i].hasOwnProperty('Id')) {
            if (existingRec) {
                delete updatedValuesRows[i].localKey;
                let entries = Object.entries(updatedValuesRows[i]);
                entries.map( ([key, val] = entry) => {
                    existingRecordObj[key] = val;
                });
                updatedRecordList.push(existingRecordObj);
            } else {
                newRecordList.push(updatedValuesRows[i]);
            }
        }
        createCustomObjectRecord({ inspId: this.recordId, newRecordListString: JSON.stringify(newRecordList), updatedRecordListString: JSON.stringify(updatedRecordList) }).
            then(result => {


                console.log('createCustomRecords successful...');
                var resultObj = JSON.parse(result);
                var createdRecords = resultObj.responseDetails;

                for (var i = 0; i < this.data.length; i++) {
                    var localKey = this.data[i].localKey;
                    for (var j = 0; j < createdRecords.length; j++) {
                        if (createdRecords[j].Kinetics__Reference_ID__c == localKey) {
                            this.data[i]['Id'] = createdRecords[j].Id;
                           // this.existingRecordsList[i]['Id'] = createdRecords[j].Id;
                        }
                    }
                }
                this.updateInspection();
            }).catch(error => {
                console.log('createCustomRecords error...');
            });
    }

    recordCreaterHelper() {
        if (this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }

    getRecordToSave() {
        const recordInput = { apiName: this.objectapiname, fields: this.fields };
        return recordInput;
    }

    createRecordHelper() {
        const recordInput = this.getRecordToSave();
        return createRecord(recordInput);
    }

    updateRecordHelper() {
        const recordInput = this.getRecordToSave();
        delete recordInput.apiName;
        return updateRecord(recordInput);
    }
    handleCancel(event) {
        this.navigateToRecordPage();
    }
}