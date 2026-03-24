import { LightningElement, track, api } from 'lwc';
import kineticsIcon from '@salesforce/resourceUrl/kineticsIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Kinetic_Form_Edit from '@salesforce/label/c.Kinetic_Form_Edit';
import LightningPrompt from "lightning/prompt";

export default class ScoreQuestionList extends LightningElement {

    @track isLoading = false;
    @api isScoringEnabled = false;
    @api sectionTitle;
    @api selectedQuestionsList;

    @track queSelectedForScoring = {};
    
    connectedCallback() {
        this.processQuestions();
    }

    get noquestionsfound() {
        return this.selectedQuestionsList.length <= 0;
    }

    Change(event) {
        this.Data = event.detail.join(', ');
    }

    processQuestions() {
        var tempArr = this.cloneValue(this.selectedQuestionsList);
        for (var i = 0; i < tempArr.length; i++) {

            // set button visibility
            if (tempArr[i].type == 'Radio Button' || tempArr[i].type == 'Checkbox' || tempArr[i].type == 'Pass Fail') {
                tempArr[i].scoringEnabled = true;
            } else {
                tempArr[i].scoringEnabled = false;
            }

            // set score confirm
            tempArr[i].scoreConfirmed = tempArr[i].scoreConfirmed || false;
        }

        this.selectedQuestionsList = tempArr;
    }

    
    sortList() {
        this.selectedQuestionsList.sort(function (x, y) {
            return (parseInt(x['index']) === parseInt(y['index'])) ? 0 : (parseInt(x['index']) - parseInt(y['index']));
        });
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

    cloneValue(inputObjectArra) {
        return JSON.parse(JSON.stringify(inputObjectArra));
    }

    @track isModalOpen = false;
    openModal(event) {
        var questionId = event.target.name;
        for (var i = 0; i < this.selectedQuestionsList.length; i++) {
            if ((this.selectedQuestionsList[i].type == 'Radio Button' || this.selectedQuestionsList[i].type == 'Checkbox' || this.selectedQuestionsList[i].type == 'Pass Fail') && this.selectedQuestionsList[i].id == questionId) {
                this.queSelectedForScoring = Object.assign({}, this.selectedQuestionsList[i]);
                this.queSelectedForScoring['optionsForScore'] = [];
                var optionsList = this.queSelectedForScoring.values.split(",");
                var scoreSetting = this.queSelectedForScoring.scoreSetting || {};
                for (var i = 0; i < optionsList.length; i++) {
                    this.queSelectedForScoring['optionsForScore'].push(
                        {
                            'optionName': optionsList[i].trim(),
                            'optionLabel': optionsList[i].trim(),
                            'selectedScore': scoreSetting.hasOwnProperty(optionsList[i].trim()) ? parseInt(scoreSetting[optionsList[i].trim()]) : 0
                        });
                }
                break;
            } else if (this.selectedQuestionsList[i].id == questionId) {
                this.queSelectedForScoring = Object.assign({}, this.selectedQuestionsList[i]);
            }
        }

        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    confirmScoreSetting() {
        this.isModalOpen = false;
        this.queSelectedForScoring.scoreConfirmed = true;
        for(var l=0;this.queSelectedForScoring.optionsForScore != undefined && l<this.queSelectedForScoring.optionsForScore.length; l++) {
            if(this.queSelectedForScoring.optionsForScore[l].optionName != undefined 
                && this.queSelectedForScoring.optionsForScore[l].selectedScore != undefined) {
                    if(this.queSelectedForScoring.scoreSetting == undefined){
                        this.queSelectedForScoring.scoreSetting = {};
                    }

                    if(!this.queSelectedForScoring.scoreSetting.hasOwnProperty(this.queSelectedForScoring.optionsForScore[l].optionName)) {
                        this.queSelectedForScoring.scoreSetting[this.queSelectedForScoring.optionsForScore[l].optionName] = this.queSelectedForScoring.optionsForScore[l].selectedScore;
                    }
                }
        }
        const scoreConfirmedEvent = new CustomEvent('scoreconfirmed', { detail: this.queSelectedForScoring });
        this.dispatchEvent(scoreConfirmedEvent);

        // confirm the score has been set 
        var questions = this.cloneValue(this.selectedQuestionsList);

        for (var i = 0; i < questions.length; i++) {
            if (questions[i].id == this.queSelectedForScoring.id) {
                questions[i].scoreConfirmed = true;
                questions[i].scoreSetting = this.queSelectedForScoring.scoreSetting;
            }
        }
        this.selectedQuestionsList = questions;
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

    onScoreChange(event) {
        var optname = event.currentTarget.dataset.optname;
        var qid = event.currentTarget.dataset.qid;
        var scoreVal = event.target.value;

        var selectedQueForScoringClone = this.cloneValue(this.queSelectedForScoring);

        var scoreSetting = selectedQueForScoringClone.scoreSetting || {};
        if (scoreVal != undefined && scoreVal != '') {
            scoreSetting[optname] = parseInt(scoreVal);
        }
        selectedQueForScoringClone.scoreSetting = scoreSetting;

        for (var i = 0; i < selectedQueForScoringClone['optionsForScore'].length; i++) {
            if (selectedQueForScoringClone['optionsForScore'][i].optionName === optname) {
                selectedQueForScoringClone['optionsForScore'][i].selectedScore = scoreVal;
                break;
            }
        }
        this.queSelectedForScoring = selectedQueForScoringClone;
    }
}