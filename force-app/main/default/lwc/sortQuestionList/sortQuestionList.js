import { LightningElement, track, api } from 'lwc';
import kineticsIcon from '@salesforce/resourceUrl/kineticsIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Kinetic_Form_Edit from '@salesforce/label/c.Kinetic_Form_Edit';
import LightningPrompt from "lightning/prompt";

export default class SortQuestionList extends LightningElement {
    @track isLoading = false;
    //@api isScoringEnabled = false;
    @api sectionTitle;
    @api selectedQuestionsList;

    @track icons = {};

    @track queSelectedForScoring = {};
    @api pageNumberCounter = 0;
    pageNumberByFirstQuestionIndex = {};
    firstQuestionIndexByPageNumber = {};

    @api sectionNumberCounter = 0;
    sectionNumberByFirstQuestionIndex = {};
    firstQuestionIndexBySectionNumber = {};
    sectionMetadataBySectionNumber = {};

    connectedCallback() {
        this.icons['pagebreak'] = kineticsIcon + '/kineticsIcon/pagebreak.png';
        this.icons['section'] = kineticsIcon + '/kineticsIcon/section.png';
        this.icons['leftarrow'] = kineticsIcon + '/kineticsIcon/leftarrow.png';
        this.icons['rightarrow'] = kineticsIcon + '/kineticsIcon/rightarrow.png';

        this.processQuestions();
    }

    get noquestionsfound() {
        return this.selectedQuestionsList.length <= 0;
    }

    Change(event) {
        this.Data = event.detail.join(', ');
    }

    processQuestions() {
        this.pageNumberByFirstQuestionIndex = {};
        this.sectionNumberByFirstQuestionIndex = {};
        this.firstQuestionIndexByPageNumber = {};
        this.firstQuestionIndexBySectionNumber = {};
        var tempArr = this.cloneValue(this.selectedQuestionsList);
        
        for (var i = 0; i < tempArr.length; i++) {

            // processQuestionsForPageBreak
            if (tempArr[i].isPageBreakAdded) {
                this.pageNumberByFirstQuestionIndex[i] = tempArr[i].pagebreak.pagenumber;
                this.firstQuestionIndexByPageNumber[tempArr[i].pagebreak.pagenumber] = i;
            }
            // processQuestionsForSectionBreak
            if (tempArr[i].isSectionBreakAdded) {
                this.sectionNumberByFirstQuestionIndex[i] = tempArr[i].sectionbreak.sectionnumber;
                this.firstQuestionIndexBySectionNumber[tempArr[i].sectionbreak.sectionnumber] = i;
                this.sectionMetadataBySectionNumber[parseInt(tempArr[i].sectionbreak.sectionnumber)] = tempArr[i].sectionbreak;
            }

            //add property used for showing droppable area
            tempArr[i]['isdragover'] = false;
        }

        this.selectedQuestionsList = tempArr;

    }

    removePageBreak(event) {

        var loopindex = parseInt(event.target.dataset.forloopindex);
        if(loopindex == 0) {
            this.showMessage('This page break is required and can not be removed');
            return 0;
        }
        var tempArr = this.cloneValue(this.selectedQuestionsList);
        tempArr[loopindex].isPageBreakAdded = false;
        tempArr[loopindex].pagebreak = this.getPageBreakWrapper(-1);
        this.selectedQuestionsList = this.adjustPageBreakPosition(tempArr);

        this.updateOrderAtParent();
    }
    removeSectionBreak(event) {

        var loopindex = parseInt(event.target.dataset.forloopindex);
        var tempArr = this.cloneValue(this.selectedQuestionsList);
        tempArr[loopindex].isSectionBreakAdded = false;
        tempArr[loopindex].sectionbreak = this.getSectionBreakWrapper(-1);
        this.selectedQuestionsList = this.adjustSectionBreakPosition(tempArr);

        this.updateOrderAtParent();
    }

    pageBreakElementDrag(event) {
        event.dataTransfer.setData("elementType", 'pageBreakElement');
    }
    sectionBreakElementDrag(event) {
        event.dataTransfer.setData("elementType", 'sectionBreakElement');
    }

    pageBreakDrag(event) {
        event.dataTransfer.setData("elementType", 'pageBreak');
        event.dataTransfer.setData("pagenumber", parseInt(event.target.dataset.pagenumber));
    }
    sectionBreakDrag(event) {
        event.dataTransfer.setData("elementType", 'sectionBreak');
        event.dataTransfer.setData("sectionnumber", parseInt(event.target.dataset.sectionnumber));
    }

    pageBreakElementDrop(event) {
        const dropRowIndex = parseInt(event.target.dataset.forloopindex);
        this.addPageBreak(dropRowIndex);
    }
    sectionBreakElementDrop(event) {
        const dropRowIndex = parseInt(event.target.dataset.forloopindex);
        this.addSectionBreak(dropRowIndex);
    }

    pageBreakDrop(event) {
        var dropRowIndex = parseInt(event.target.dataset.forloopindex);
        var pagenumber = parseInt(event.dataTransfer.getData("pagenumber"));
        var olderQuestionIndex = this.firstQuestionIndexByPageNumber[pagenumber];
        if(olderQuestionIndex == 0 && pagenumber == 1) {
            this.showMessage('This page break is required at this position and can not be moved');
            return 0;
        }
        this.updatePageBreak(dropRowIndex, pagenumber, olderQuestionIndex);
    }
    sectionBreakDrop(event) {
        var dropRowIndex = parseInt(event.target.dataset.forloopindex);
        var sectionnumber = parseInt(event.dataTransfer.getData("sectionnumber"));
        var olderQuestionIndex = this.firstQuestionIndexBySectionNumber[sectionnumber];
        this.updateSectionBreak(dropRowIndex, sectionnumber, olderQuestionIndex);
    }

    DragStart(event) {
        event.target.classList.add('drag');
        event.target.classList.add('slds-is-selected');
    }

    DragOver(event) {
        event.preventDefault();
        var questionId = event.target.dataset.name;
        this.updateIsDragOver(questionId);
    }

    updateIsDragOver (questionId) {
        var tempArr = this.cloneValue(this.selectedQuestionsList);
        for (var i = 0; i < tempArr.length; i++) {
            tempArr[i]['isdragover'] = false;
            if(questionId && tempArr[i].id == questionId) {
                tempArr[i]['isdragover'] = true;
            }
        }
        this.selectedQuestionsList = tempArr;
    }

    Drop(event) {
        event.stopPropagation();
        event.target.classList.add('slds-drop-zone');
        event.target.classList.add('slds-drop-zone_drag');
        this.updateIsDragOver(undefined);

        var elementType = event.dataTransfer.getData("elementType");
        //return from here if page break element is dropped
        if (elementType == 'pageBreak') {
            event.target.classList.remove('slds-drop-zone');
            return this.pageBreakDrop(event);
        }
        //return from here if page break element is dropped
        if (elementType == 'pageBreakElement') {
            event.target.classList.remove('slds-drop-zone');
            return this.pageBreakElementDrop(event);
        }

        //return from here if section break element is dropped
        if (elementType == 'sectionBreakElement') {
            event.target.classList.remove('slds-drop-zone');
            return this.sectionBreakElementDrop(event);
        }
        //return from here if page break element is dropped
        if (elementType == 'sectionBreak') {
            event.target.classList.remove('slds-drop-zone');
            return this.sectionBreakDrop(event);
        }

        const elementList = this.template.querySelectorAll('.Items');
        const dragRowIndex = parseInt(this.template.querySelector(".drag").getAttribute('data-forloopindex'));
        const dropRowIndex = parseInt(event.target.dataset.forloopindex);

        if (dragRowIndex === dropRowIndex) {
            return false;
        }

        var tempArr = this.cloneValue(this.selectedQuestionsList);
        const draggedRow = tempArr[dragRowIndex];
        if (dropRowIndex < dragRowIndex) {
            //add the dragged element at new position
            tempArr.splice(dropRowIndex, 0, draggedRow);
            //delete the dragged element from row
            tempArr.splice((dragRowIndex + 1), 1);
        } else {
            //add the dragged element at new position
            tempArr.splice((dropRowIndex + 1), 0, draggedRow);
            //delete the dragged element from row
            tempArr.splice(dragRowIndex, 1);
        }

        //update index on record to updated value
        for (var i = 0; i < tempArr.length; i++) {
            tempArr[i].index = (i + 1);
            tempArr[i].isPageBreakAdded = false;
            tempArr[i].isPageBreakAdded = this.pageNumberByFirstQuestionIndex.hasOwnProperty(i) == true;
            tempArr[i].pagebreak = this.getPageBreakWrapper(this.pageNumberByFirstQuestionIndex[i]);

        }
        this.selectedQuestionsList = tempArr;

        elementList.forEach(element => {
            element.classList.remove('drag');
            element.classList.remove('slds-is-selected');
        });
        event.target.classList.remove('slds-drop-zone');
        this.sortList();
        this.updateOrderAtParent();
    }

    sortList() {
        this.selectedQuestionsList.sort(function (x, y) {
            return (parseInt(x['index']) === parseInt(y['index'])) ? 0 : (parseInt(x['index']) - parseInt(y['index']));
        });
    }

    getPageBreakWrapper(pageNumber) {
        return {
            'pagenumber': pageNumber,
            'pagenumberName': '&lt;---------   Page Break   ---------&gt;'
        };
    }

    getSectionBreakWrapper(sectionNumber, title) {

        if (this.sectionMetadataBySectionNumber.hasOwnProperty(sectionNumber)) {
            var existingSectionWrp = this.sectionMetadataBySectionNumber[sectionNumber];
            if (title != null && title != undefined
                && existingSectionWrp.title != title) {
                existingSectionWrp.title = title;
                this.sectionMetadataBySectionNumber[sectionNumber] = existingSectionWrp;
            }
            return existingSectionWrp;
        } else {
            var obj = {
                'sectionnumber': sectionNumber,
                'sectionNumberName': '&lt;---------   Section Break   ---------&gt;'
            };
            if (title) {
                obj['title'] = title;
            }
            this.sectionMetadataBySectionNumber[sectionNumber] = obj;
            return obj;
        }
    }

    updatePageBreak(dropRowIndex, pagenumber, olderQuestionIndex) {
        if (this.pageNumberByFirstQuestionIndex.hasOwnProperty(dropRowIndex)) {
            this.showMessage('Page break is already added at this question, Please drop page break at correct question.');
            return 0;
        }

        this.pageNumberByFirstQuestionIndex[dropRowIndex] = pagenumber;
        delete this.pageNumberByFirstQuestionIndex[olderQuestionIndex];
        this.firstQuestionIndexByPageNumber[pagenumber] = dropRowIndex;

        var selectedQuestionsListClone = this.cloneValue(this.selectedQuestionsList);
        selectedQuestionsListClone[olderQuestionIndex]['pagebreak'] = this.getPageBreakWrapper(-1);
        selectedQuestionsListClone[olderQuestionIndex]['isPageBreakAdded'] = false;

        selectedQuestionsListClone[dropRowIndex]['pagebreak'] = this.getPageBreakWrapper(pagenumber);
        selectedQuestionsListClone[dropRowIndex]['isPageBreakAdded'] = true;

        this.selectedQuestionsList = selectedQuestionsListClone;

        this.updateOrderAtParent();
    }
    
    updateSectionBreak(dropRowIndex, sectionnumber, olderQuestionIndex) {
        if (this.sectionNumberByFirstQuestionIndex.hasOwnProperty(dropRowIndex)) {
            this.showMessage('Section break is already added at this question, Please drop section break at correct question.');
            return;
        }

        this.sectionNumberByFirstQuestionIndex[dropRowIndex] = sectionnumber;
        this.firstQuestionIndexBySectionNumber[sectionnumber] = dropRowIndex;

        var selectedQuestionsListClone = this.cloneValue(this.selectedQuestionsList);
        selectedQuestionsListClone[olderQuestionIndex]['sectionbreak'] = this.getSectionBreakWrapper(-1);
        selectedQuestionsListClone[olderQuestionIndex]['isSectionBreakAdded'] = false;

        selectedQuestionsListClone[dropRowIndex]['sectionbreak'] = this.getSectionBreakWrapper(sectionnumber);
        selectedQuestionsListClone[dropRowIndex]['isSectionBreakAdded'] = true;

        this.selectedQuestionsList = selectedQuestionsListClone;

        this.updateOrderAtParent();
    }


    showMessage(message) {
        const event = new ShowToastEvent({
            title: Kinetic_Form_Edit,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    async updateSectionTitle(event) {
        var questionId = event.target.dataset.questid;
        var sectionnumber = event.target.dataset.sectionnumber;
        const result = await this.getSectionTitlePopup(sectionnumber);
        if (result == null || result == undefined || result == '') {
            return;
        }
        var sectionTitle = 'Section ' + (sectionnumber + 1);
        if (result) {
            sectionTitle = result;
        }

        var selectedquestionListLocal = this.cloneValue(this.selectedQuestionsList);
        for (var i = 0; i < selectedquestionListLocal.length; i++) {
            if (selectedquestionListLocal[i].id == questionId) {
                selectedquestionListLocal[i].sectionbreak.title = sectionTitle;
                break;
            }
        }
        this.selectedQuestionsList = selectedquestionListLocal;
        this.updateOrderAtParent();
    }

    addPageBreak(rowIndex) {
        if (this.selectedQuestionsList.length == 0) {
            return;
        }

        if (this.pageNumberByFirstQuestionIndex.hasOwnProperty(rowIndex)) {
            this.showMessage('Page break is already added at this question, Please drop page break at correct question.');
            return;
        }

        var selectedQuestionsListClone = this.cloneValue(this.selectedQuestionsList);
        selectedQuestionsListClone[rowIndex]['pagebreak'] = this.getPageBreakWrapper(this.pageNumberCounter);
        selectedQuestionsListClone[rowIndex]['isPageBreakAdded'] = true;



        this.selectedQuestionsList = this.adjustPageBreakPosition(selectedQuestionsListClone);

        this.updateOrderAtParent();
    }

    async getSectionTitlePopup(sectionNumberCounter) {
        var sectionWrapperObj = this.getSectionBreakWrapper(sectionNumberCounter);
        var defaultValue = 'Section ' + sectionNumberCounter;
        if (sectionWrapperObj.title) {
            defaultValue = sectionWrapperObj.title;
        }
        const result = await LightningPrompt.open({
            message: 'What is the title of the section?',
            theme: 'warning',
            label: 'Section Title',
            variant: 'header',
            defaultValue: defaultValue,
        });
        return result;
    }
    async addSectionBreak(rowIndex) {
        if (this.selectedQuestionsList.length == 0) {
            return;
        }

        if (this.sectionNumberByFirstQuestionIndex.hasOwnProperty(rowIndex)) {
            this.showMessage('Section break is already added at this question, Please drop section break at correct question.');
            return;
        }

        var selectedQuestionsListClone = this.cloneValue(this.selectedQuestionsList);
        const result = await this.getSectionTitlePopup((this.sectionNumberCounter + 1));

        if (result == null || result == undefined || result == '') {
            return;
        }
        var sectionTitle = 'Section ' + (this.sectionNumberCounter + 1);
        if (result) {
            sectionTitle = result;
        }
        this.sectionNumberCounter = this.sectionNumberCounter + 1;
        selectedQuestionsListClone[rowIndex]['sectionbreak'] = this.getSectionBreakWrapper(this.sectionNumberCounter, sectionTitle);
        selectedQuestionsListClone[rowIndex]['isSectionBreakAdded'] = true;

        this.selectedQuestionsList = this.adjustSectionBreakPosition(selectedQuestionsListClone);

        this.updateOrderAtParent();
    }

    adjustPageBreakPosition(selectedQuestionsListClone) {
        var pagenumber = 0;
        this.pageNumberByFirstQuestionIndex = {};
        this.firstQuestionIndexByPageNumber = {};
        for (var i = 0; i < selectedQuestionsListClone.length; i++) {
            if (selectedQuestionsListClone[i].isPageBreakAdded) {
                pagenumber = pagenumber + 1;
                this.pageNumberByFirstQuestionIndex[i] = pagenumber;
                this.firstQuestionIndexByPageNumber[pagenumber] = i;
                selectedQuestionsListClone[i]['pagebreak'] = this.getPageBreakWrapper(pagenumber);
            }
        }
        this.pageNumberCounter = pagenumber;
        return selectedQuestionsListClone;
    }

    adjustSectionBreakPosition(selectedQuestionsListClone) {
        var sectionnumber = 0;
        this.sectionNumberByFirstQuestionIndex = {};
        this.firstQuestionIndexBySectionNumber = {};
        for (var i = 0; i < selectedQuestionsListClone.length; i++) {
            if (selectedQuestionsListClone[i].isSectionBreakAdded) {
                sectionnumber = sectionnumber + 1;
                this.sectionNumberByFirstQuestionIndex[i] = sectionnumber;
                this.firstQuestionIndexBySectionNumber[sectionnumber] = i;
                selectedQuestionsListClone[i]['sectionbreak'] = this.getSectionBreakWrapper(sectionnumber);
            }
        }
        this.sectionNumberCounter = sectionnumber;
        return selectedQuestionsListClone;
    }

    updateOrderAtParent() {
       // console.log(this.pageNumberByFirstQuestionIndex);
        const customevent = new CustomEvent('questionmoved', {
            detail: {
                selectedQuestionsList: this.selectedQuestionsList, pageNumberByFirstQuestionIndex: this.pageNumberByFirstQuestionIndex,
                sectionNumberByFirstQuestionIndex: this.sectionNumberByFirstQuestionIndex
            }
        });
        this.dispatchEvent(customevent);
        return this.selectedQuestionsList;
    }

    cloneValue(inputObjectArra) {
        return JSON.parse(JSON.stringify(inputObjectArra));
    }

    @track sidePanelCls = 'sidepanelClosed';
    @track showOpenIcon = true;
    openNav() {
        console.log('sidepanelOpen');
        this.sidePanelCls = 'sidepanelOpen';
        this.showOpenIcon = false;
    }

    /* Set the width of the sidebar to 0 (hide it) */
    closeNav() {
        console.log('sidepanelClosed');
        this.sidePanelCls = 'sidepanelClosed';
        this.showOpenIcon = true;
    }
}