import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getObjectAndFieldMapping from '@salesforce/apex/TbSpreadsheetTemplateBuilderController.getObjectAndFieldMapping';
import spreadsheetBuilderProcess from '@salesforce/resourceUrl/spreadsheetBuilderProcess';

export default class TbSpreadsheetTemplateBuilder extends NavigationMixin(LightningElement) {

    isLoading = false;
    @track objectapiname = 'Kinetics__Spreadsheet_Configuration__c';
    @api recordId;
    @track spreadsheetMetadata = {};
    @track objectList = [];
    selectedObjectName = '';
    @track selectedObjectsFieldWrapperList = [];
    @track objectListPresent = false;
    fieldWrapperListByObjectName = {};
    @track selectedObjectFieldsOptions = [];
    columnTypeOptions = [];

    processImage = spreadsheetBuilderProcess + '';
    showHelp = true;


    @wire(getRecord, {
        recordId: '$recordId', fields: ['Kinetics__Spreadsheet_Configuration__c.Name',
            'Kinetics__Spreadsheet_Configuration__c.Kinetics__Row_Metadata__c',
            'Kinetics__Spreadsheet_Configuration__c.Kinetics__Object_API_Name__c',
            'Kinetics__Spreadsheet_Configuration__c.Kinetics__Instructions__c'
        ]
    })
    spreadsheetformconfrecord({ error, data }) {
        if (data) {
            this.loadRecord(data);
        }
        if (error) {
            this.showErrorMessage(error);
        }
    }

    connectedCallback() {
        this.resetToDefaults();
        this.initializeLabels();
        this.isLoading = true;
        console.log('***** connectedCallback>getObjectAndFieldMapping');
        getObjectAndFieldMapping().then(success => {
            var resultObj = JSON.parse(success);
            var fieldListByObjectName = resultObj.objFieldsMap;
            this.objectList = resultObj.objectList;
            for (let [objectName, fieldlist] of Object.entries(fieldListByObjectName)) {
                this.fieldWrapperListByObjectName[objectName] = fieldlist;
            }
            this.objectListPresent = true;

            if (this.selectedObjectName) {
                this.selectedObjectFieldsOptions = [];
                this.selectedObjectsFieldWrapperList = this.fieldWrapperListByObjectName[this.selectedObjectName];
                for (var i = 0; i < this.selectedObjectsFieldWrapperList.length; i++) {
                    var fieldwrapper = this.selectedObjectsFieldWrapperList[i];
                    this.selectedObjectFieldsOptions.push({
                        value: fieldwrapper.fieldName,
                        label: fieldwrapper.fieldLabel
                    });
                }
            }
            // if (this.objectList.length > 0) {
            //     if (this.recordId == undefined) {
            //         this.spreadsheetMetadata.selectedFormValue.Kinetics__Object_API_Name__c = this.objectList[0].value;
            //         this.selectedObjectName = this.spreadsheetMetadata.selectedFormValue.Kinetics__Object_API_Name__c;
            //     }
            //     this.handleFieldOptions();
            //     this.objectListPresent = true;
            // }
            this.isLoading = false;
        }).catch(error => {
            this.isLoading = false;
            this.handleErrorBlock(error);
        });
    }

    get ObjectOptions() {
        return this.objectList;
    }

    handleObjectChange(event) {
        this.selectedObjectName = event.detail.value;
        this.spreadsheetMetadata.selectedFormValue.Kinetics__Object_API_Name__c = event.detail.value;
        this.selectedObjectsFieldWrapperList = this.fieldWrapperListByObjectName[this.selectedObjectName];
        this.handleFieldOptions();
    }
    handleFieldOptions() {
        this.selectedObjectFieldsOptions = [];
        for (var i = 0; i < this.selectedObjectsFieldWrapperList.length; i++) {
            var fieldwrapper = this.selectedObjectsFieldWrapperList[i];
            this.selectedObjectFieldsOptions.push({
                value: fieldwrapper.fieldName,
                label: fieldwrapper.fieldLabel
            });
        }
    }

    handleErrorBlock(error) {
        this.isLoading = false;
        this.showErrorMessage(error.body.message);
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Spreadsheet Builder',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    initializeLabels() {
        // this.labels['headerTitle'] = 'Spreadsheet Builder';
        // this.labels['headerSubTitle'] = 'Edit Spreadsheet';
        // this.labels['firstStepHelpText'] = 'Specify Spreadsheet Name';
        // this.labels['invalidSurveyText'] = 'Please provide valid name for Spreadsheet';
    }

    updateLastModifiedMetadata() {
        //this is done to have one place from where the changes are broadcasted, so that child component get the updated version
        //this.spreadsheetMetadata = JSON.parse(JSON.stringify(this.spreadsheetMetadata));
    }

    loadRecord(existingRecord) {
        console.log('***** loadRecord..');
        this.spreadsheetMetadata.selectedFormValue = {
            'Name': '',
            'Kinetics__Row_Metadata__c': '[{}]',
            'Kinetics__Object_API_Name__c': '',
            'Kinetics__Instructions__c': '',
            'Id': undefined
        };

        this.spreadsheetMetadata.selectedFormValue.Name = existingRecord.fields.Name.value;
        this.spreadsheetMetadata.selectedFormValue.Kinetics__Row_Metadata__c = existingRecord.fields.Kinetics__Row_Metadata__c.value;
        this.spreadsheetMetadata.selectedFormValue.Kinetics__Object_API_Name__c = existingRecord.fields.Kinetics__Object_API_Name__c.value;
        this.spreadsheetMetadata.selectedFormValue.Kinetics__Instructions__c = existingRecord.fields.Kinetics__Instructions__c.value;
        this.spreadsheetMetadata.selectedFormValue.Id = this.recordId;

        this.spreadsheetMetadata.rowMetadata = JSON.parse(this.spreadsheetMetadata.selectedFormValue.Kinetics__Row_Metadata__c) || [this.getDefaultRow()];
        this.selectedObjectName = this.spreadsheetMetadata.selectedFormValue.Kinetics__Object_API_Name__c;
        this.handleFieldOptions();
    }

    resetToDefaults() {
        this.initializeTypeOptions();
        this.spreadsheetMetadata.selectedFormValue = {
            'Name': '',
            'Kinetics__Row_Metadata__c': '[{}]',
            'Kinetics__Object_API_Name__c': '',
            'Kinetics__Instructions__c': '',
            'Id': undefined
        };

        this.spreadsheetMetadata.rowMetadata = [this.getDefaultRow(0)];
    }

    initializeTypeOptions() {
        this.columnTypeOptions.push({ value: 'Text', label: 'Text' });
        this.columnTypeOptions.push({ value: 'Number', label: 'Number' });
        this.columnTypeOptions.push({ value: 'Currency', label: 'Currency' });
        this.columnTypeOptions.push({ value: 'Date', label: 'Date' });
        this.columnTypeOptions.push({ value: 'Time', label: 'Time' });
    }

    getDefaultRow(rowno) {
        return {
            'columnWrapperList': [this.getDefaultColumn(0)],
            'rowno': rowno
        };
    }
    getDefaultColumn(uid) {
        return {
            'label': '',
            'fieldName': '',
            'uid': uid,
            'type': 'Text',
            'wrapText': true,
            'editable': true
        };
    }
    handleInputFieldChange(event) {
        this.spreadsheetMetadata.selectedFormValue[event.target.dataset.name] = event.target.value;
        this.updateLastModifiedMetadata();
    }

    handleColumnInputChange(event) {
        console.log('***** handleColumnInputChange');
        var attributename = event.target.dataset.name;
        var value = event.target.value;
        var columnUId = event.target.dataset.uid;
        var fieldlabel = event.target.dataset.label;
        for (var j = 0; j < this.spreadsheetMetadata.rowMetadata.length; j++) {
            for (var i = 0; i < this.spreadsheetMetadata.rowMetadata[j].columnWrapperList.length; i++) {
                if (this.spreadsheetMetadata.rowMetadata[j].columnWrapperList[i].uid == columnUId) {
                    this.spreadsheetMetadata.rowMetadata[j].columnWrapperList[i][attributename] = value;
                    // if(attributename == 'fieldName') {
                    //     this.spreadsheetMetadata.rowMetadata.columnWrapperList[i]['label'] = fieldlabel;

                    // }
                    break;
                }
            }
        }
    }

    handleonfocus(event) {

    }

    handleofffocus(event) {

    }


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
    showSuccessNotification(message) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            }
        }).then(url => {
            const event = new ShowToastEvent({
                "title": 'Success',
                "variant": 'success',
                "message": message || 'Spreadsheet configuration has been created successfully.'
            });
            this.dispatchEvent(event);
        });
    }
    isvalidvalue(value) {
        return (value != null && value != undefined && value != '');
    }

    deleteRow(event) {

    }

    addcolumnInList(event) {
        var rowNo = event.target.dataset.rowno;
        for (var i = 0; i < this.spreadsheetMetadata.rowMetadata.length; i++) {
            if (this.spreadsheetMetadata.rowMetadata[i].rowno == rowNo) {
                this.spreadsheetMetadata.rowMetadata[i].columnWrapperList.push(this.getDefaultColumn(this.spreadsheetMetadata.rowMetadata[i].columnWrapperList.length));
                break;
            }
        }
    }

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
        console.log(this.spreadsheetMetadata);
        console.log(JSON.parse(JSON.stringify(this.spreadsheetMetadata)));

        this.spreadsheetMetadata.rowMetadata =
            this.spreadsheetMetadata.selectedFormValue.Kinetics__Row_Metadata__c = JSON.stringify(this.spreadsheetMetadata.rowMetadata);

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


    recordCreaterHelper() {
        if (this.recordId === undefined) {
            return this.createRecordHelper();
        } else {
            return this.updateRecordHelper();
        }
    }

    getRecordToSave() {
        const fields = JSON.parse(JSON.stringify(this.spreadsheetMetadata.selectedFormValue));
        const recordInput = { apiName: this.objectapiname, fields };
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

    toggleHelpContainer() {
        this.showHelp = !this.showHelp;
    }
}