import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ListBuilder extends LightningElement {

    @api sectionTitle;
    @api allActiveQuestionsById;
    @api selectedQuestionCount;
    @track questionsToDisplay = [];
    questionsToDisplayMapById = {};
    @api isLoading = false;
    connectedCallback() {
        this.questionsToDisplay = Object.values(this.allActiveQuestionsById);
        this.maintainQuestionsDisplayMap();
    }
    
    handleSearch(event){
        this.isLoading = true;
        var searchText = event.target.value;
        
        if(searchText.length < 3) {
            this.questionsToDisplay = Object.values(this.allActiveQuestionsById);
        } else {
            searchText = searchText.toLowerCase();
            var allQuestionsWrapperList = Object.values(this.allActiveQuestionsById);
            this.questionsToDisplay  = allQuestionsWrapperList.filter(function (record) {
                return record.name.toLowerCase().includes(searchText)  ||
                        record.text.toLowerCase().includes(searchText) ||
                        record.values.toLowerCase().includes(searchText) ||
                        record.type.toLowerCase().includes(searchText);
                }
            );
        }
        if(this.questionsToDisplay.length == 0){
            this.showErrorMessage('No Active questions found, Please use correct search string');
        }
        this.maintainQuestionsDisplayMap();
        this.isLoading = false;
    }
    maintainQuestionsDisplayMap() {
        this.questionsToDisplayMapById = {};
        this.questionsToDisplay = this.questionsToDisplay.slice(0, 200);
        for(var i=0;i<this.questionsToDisplay.length;i++){
            this.questionsToDisplayMapById[this.questionsToDisplay[i].id] = this.questionsToDisplay[i];
        }

        var tempObj = this.cloneObject(this.allActiveQuestionsById);
        var tempDisplayList = this.cloneObject(this.questionsToDisplay);
        for(var i=0;i<tempDisplayList.length;i++) {
            tempDisplayList[i].index = (i+1);
            if(tempObj.hasOwnProperty(tempDisplayList[i].name)) {
                tempObj[tempDisplayList[i].name] = tempDisplayList[i];
            }
        }
        this.questionsToDisplay = tempDisplayList;
        this.allActiveQuestionsById = tempObj;
    }
    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Kinetic Form Edit',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    
    selectquestion(event) {
        this.isLoading = true;
        if(this.questionsToDisplayMapById.hasOwnProperty(event.target.name)
            && this.allActiveQuestionsById.hasOwnProperty(event.target.name)) {
            var tempObj = this.cloneObject(this.allActiveQuestionsById);
            var questwrapper = tempObj[event.target.name];
            questwrapper.isselected = !questwrapper.isselected;
            questwrapper['rowclass'] = 'slds-hint-parent';
            if(questwrapper.isselected){
                questwrapper.rowclass = questwrapper.rowclass + ' slds-is-selected';
                this.selectedQuestionCount = this.selectedQuestionCount + 1;
            } else {
                this.selectedQuestionCount = this.selectedQuestionCount - 1;
            }
            questwrapper['index'] = event.target.dataset.index;
            tempObj[event.target.name] = questwrapper;
            this.allActiveQuestionsById = tempObj;
            
            var displayTempMap = this.cloneObject(this.questionsToDisplayMapById);
            displayTempMap[event.target.name] = questwrapper;
            this.questionsToDisplayMapById = displayTempMap;
            this.questionsToDisplay = Object.values(this.questionsToDisplayMapById);
            this.maintainQuestionsDisplayMap();

            const customevent = new CustomEvent('questionselected', {
                detail: {allActiveQuestionsById:this.allActiveQuestionsById,
                        selectedQuestionCount: this.selectedQuestionCount}
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
    get noquestionsfound() {
        return (this.questionsToDisplay.length <= 0);
    }
}