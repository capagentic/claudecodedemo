import { api, LightningElement, track } from 'lwc';

export default class TbQuestionRow extends LightningElement {
    // @api currentquestion;
    @api questionNumber;
    @track logicList = [];
    @api allowLogicBuilder = false;
    @track triggerOptions = [];


    // only applicable for additional questions
    @api isAdditionalQuestion = false;
    @api triggerAnswer;
    logicQuestionType = ["Yes No", "Radio Button", "Pass Fail", "Compliant Non Compliant"];

    _currentquestion
    @api
    get currentquestion() {
        return this._currentquestion;
    }
    set currentquestion(value) {
        this._currentquestion = value;
        if (this._currentquestion.dependantQuestions) {
            this.loadLogicList();
            this.triggerOptions = this._currentquestion.Kinetics__Values__c;
        } else {
            this.logicList = [];
            this.triggerOptions = [];
        }

        if (this._currentquestion.Kinetics__Field_Type__c && this.logicQuestionType.includes(this._currentquestion.Kinetics__Field_Type__c)) {
            this.allowLogicBuilder = true;
            this.triggerOptions = this._currentquestion.Kinetics__Values__c;
        }
    }


    loadLogicList() {
        // load the logic list if it has not been populated 
        this.logicList = [];
        if (this.logicList.length == 0 && this.currentquestion.dependantQuestions) {
            let logicId = 0;
            for (const ans in this.currentquestion.dependantQuestions) {
                var logic = {};
                logic.id = logicId;
                logic.triggerAnswer = ans;
                logic.triggerAction = 'Ask a Question';
                logic.showAdditionalQuestionBox = true;
                logic.additionalQuestion = this.currentquestion.dependantQuestions[ans].question;
                logic.showTriggerOptions = false;
                logic.showTriggerActions = false;
                this.logicList.push(logic);
                logicId++;
            }

            for (const ans in this.currentquestion.flows) {
                var logic = {};
                logic.id = logicId;
                logic.triggerAnswer = ans;
                logic.triggerAction = 'Invoke Salesforce Flow';
                logic.showFlowBox = true;
                logic.flowName = this.currentquestion.flows[ans];
                logic.showTriggerOptions = false;
                logic.showTriggerActions = false;
                this.logicList.push(logic);
                logicId++;
            }
        }
    }


    cloneValue(inputObject) {
        return JSON.parse(JSON.stringify(inputObject));
    }

    handleQuestionInputChange(event) {
        var attributename = event.target.dataset.name;
        var currentQuestion = this.cloneValue(this.currentquestion);
        var oldValue = currentQuestion[attributename];
        currentQuestion[attributename] = event.target.value;
        if (attributename === 'Kinetics__AI_Guidance__c'
            && currentQuestion[attributename] != undefined
            && currentQuestion[attributename].length > 499) {
            alert('Please ensure that the Guidance text is not more than 499 long');
            currentQuestion[attributename] = oldValue;
            return 0;
        }
        this.currentquestion = currentQuestion;
        var valueChangeEvent;
        if (!this.isAdditionalQuestion) {
            valueChangeEvent = new CustomEvent('valuechanged', {
                detail: { question: currentQuestion }
            });
        } else {
            valueChangeEvent = new CustomEvent('valuechanged', {
                detail: { question: currentQuestion, triggerAnswer: this.triggerAnswer, parent: currentQuestion.uid }
            });
        }

        this.dispatchEvent(valueChangeEvent);

        this.resetLogic(currentQuestion);
    }
    handleonfocus(event) {

        var uid = event.target.dataset.uid
        var currentQuestion = this.cloneValue(this.currentquestion);
        currentQuestion['gotfocus'] = true;
        this.currentquestion = currentQuestion;
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { question: currentQuestion, isFocusChange: true }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleofffocus(event) {
        // var uid = event.target.dataset.uid
        // for(var i = 0;i<this.questionWrapperList.length;i++){
        //     this.questionWrapperList[i].gotfocus = false;
        // } 
    }
    handleQuestionUpdate(event) {
        var currentQuestion = event.detail.question;

        this.currentquestion = currentQuestion;
        var valueChangeEvent = {};
        if (!this.isAdditionalQuestion) {
            valueChangeEvent = new CustomEvent('valuechanged', {
                detail: { question: currentQuestion }
            });
        } else {
            valueChangeEvent = new CustomEvent('valuechanged', {
                detail: { question: currentQuestion, triggerAnswer: this.triggerAnswer, parent: this.currentquestion.uid }
            });
        }

        this.dispatchEvent(valueChangeEvent);
        this.resetLogic(currentQuestion);
    }

    resetLogic(question) {
        if (question["Kinetics__Field_Type__c"] != "Yes No") {
            this.logicList = [];
            this.allowLogicBuilder = false;
            this.triggerOptions = [];
        } else {
            this.allowLogicBuilder = true;
        }
    }

    get isSalesforceFlowQuestion() {
        return this.currentquestion.Kinetics__Field_Type__c == 'Salesforce Flow';
    }

    get currentquestionselectedActions() {
        var selectedAttributesString = '';
        // if(this.currentquestion.Kinetics__Required__c){
        //     selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">Required </span>';
        // }
        if (this.currentquestion.Kinetics__Capture_Notes__c) {
            selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">Capture Notes </span>';
        }
        if (this.currentquestion.Kinetics__Attach_Photos_or_Files__c) {
            selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">Attach Photo or File</span>';
        }
        if (this.currentquestion.Kinetics__Assign_Tasks__c) {
            selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">Assign Tasks</span>';
        }
        if (this.currentquestion.captureGuidanceForGPT) {
            selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">GPT Guidance</span>';
        }
        if (this.currentquestion.captureQuestionInstructions) {
            selectedAttributesString = selectedAttributesString + '<span class=\"slds-badge\">Instructions</span>';
        }
        return selectedAttributesString;
    }
    get showguidanceforgpttext() {
        return this.currentquestion.captureGuidanceForGPT && this.currentquestion.gotfocus;
    }
    get showQuestionInstructions() {
        return this.currentquestion.captureQuestionInstructions && this.currentquestion.gotfocus;
    }

    addLogicBuilder() {

        console.log('TbQuestionRow>addLogicBuilder');

        if (this.currentquestion.Kinetics__Values__c) {
            this.allowLogicBuilder = (true && !this.isAdditionalQuestion);
            this.triggerOptions = this.currentquestion.Kinetics__Values__c;
        }

        var logicListSize = this.logicList.length;
        var logic = {};
        logic.id = logicListSize;
        logic.triggerAnswer = '-- select --';
        logic.triggerAction = '-- select --';
        // logic.options = this.triggerOptions;
        logic.showTriggerOptions = false;
        logic.showTriggerActions = false;
        this.logicList.push(logic);
        return false;
    }


    actionOptions = [
        { label: 'Ask a Question', value: 'Ask a Question' },
        { label: 'Invoke Flow (when the record is saved)', value: 'Invoke Salesforce Flow' }
    ];

    selectTriggerAnswer(event) {
        var lid = event.target.dataset.lid;
        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].showTriggerOptions = !this.logicList[i].showTriggerOptions;
            } else {
                this.logicList[i].showTriggerOptions = false;
            }
            this.logicList[i].showTriggerActions = false;
        }
        // return false;
    }

    selectTriggerAction(event) {
        var lid = event.target.dataset.lid;
        console.log('lid=' + lid);

        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].showTriggerActions = !this.logicList[i].showTriggerActions;
            } else {
                this.logicList[i].showTriggerActions = false;
            }
            this.logicList[i].showTriggerOptions = false;
        }
    }

    handleTriggerOptionSelected(event) {
        const selectedValue = event.currentTarget.dataset.value;
        var lid = event.target.dataset.lid;

        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].triggerAnswer = selectedValue;
            }
            this.logicList[i].showTriggerOptions = false;
            this.logicList[i].showTriggerActions = false;
        }
    }

    handleTriggerActionSelected(event) {
        const selectedValue = event.currentTarget.dataset.value;
        var lid = event.target.dataset.lid;
        var cQuestion = this.cloneValue(this.currentquestion);
        console.log('handleTriggerActionSelected>action selected=' + selectedValue);
        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].triggerAction = selectedValue;

                this.logicList[i].showAdditionalQuestionBox = false;
                this.logicList[i].showFlowBox = false;

                if (this.logicList[i].triggerAction == 'Ask a Question') {
                    this.logicList[i].showAdditionalQuestionBox = true;
                    this.logicList[i].additionalQuestion = {
                        "uid": cQuestion.uid + '-child-' + "1",
                        "Name": "",
                        "Kinetics__Field_Type__c": "Text",
                        "Kinetics__Assign_Tasks__c": false,
                        "Kinetics__Attach_Photos_or_Files__c": false,
                        "Kinetics__Capture_Notes__c": false,
                        "Kinetics__Required__c": false,
                        "Kinetics__Values__c": [],
                        "displayQuestionNo": cQuestion.uid + '-child-' + "1",
                        "pageno": cQuestion.pageno,
                        "sectionno": cQuestion.sectionno, "isdragover": false
                    };
                    this.logicList[i].additionalQuestionNum = '';

                } else if (this.logicList[i].triggerAction == 'Invoke Salesforce Flow') {
                    this.logicList[i].showFlowBox = true;
                    this.logicList[i].flowName = '';
                }
            }
            this.logicList[i].showTriggerOptions = false;
            this.logicList[i].showTriggerActions = false;
        }
    }

    handleLogicDelete(event) {
        console.log('handleLogicDelete');
        var lid = event.target.dataset.lid;

        var logic = this.logicList[lid];
        var cQuestion = this.cloneValue(this.currentquestion);

        if (logic.triggerAction == 'Ask a Question') {
            cQuestion.dependantQuestions = {};
            for (const ans in this.currentquestion.dependantQuestions) {
                if (ans != logic.triggerAnswer) {
                    cQuestion.dependantQuestions[ans] = this.currentquestion.dependantQuestions[ans];
                }
            }
        } else if (logic.triggerAction == 'Invoke Salesforce Flow') {
            cQuestion.flows = {};
            for (const ans in this.currentquestion.flows) {
                if (ans != logic.triggerAnswer) {
                    cQuestion.flows[ans] = this.currentquestion.flows[ans];
                }
            }
        }
        this.currentquestion = Object.assign({}, cQuestion);
        this.logicList.splice(lid, 1);

        this.broadcastCurrentQuestionEvent();
    }

    handleAdditionalQuestionUpdate(event) {
        console.log('handleAdditionalQuestionUpdate');
        var additionalQuestionChild = event.detail.question;
        var parent = event.detail.parent;
        var triggerAnswer = event.detail.triggerAnswer;
        if (triggerAnswer) {
            var currentQuestion = this.cloneValue(this.currentquestion);
            var additionalQuestionObj = {};
            additionalQuestionObj['question'] = additionalQuestionChild;
            additionalQuestionObj['sign'] = 'is';

            currentQuestion.dependantQuestions = currentQuestion.dependantQuestions || {};
            currentQuestion.dependantQuestions[triggerAnswer] = additionalQuestionObj;

            this.currentquestion = currentQuestion;
            this.broadcastCurrentQuestionEvent();
        }
    }

    handleFlowNameUpdate(event) {
        const flowName = event.target.value;
        var lid = event.target.dataset.lid;
        console.log('lid=' + lid);

        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].flowName = flowName;
                var triggerAnswer = this.logicList[i].triggerAnswer;

                var currentQuestion = this.cloneValue(this.currentquestion);
                currentQuestion.flows = currentQuestion.flows || {};
                currentQuestion.flows[triggerAnswer] = flowName;

                this.currentquestion = currentQuestion;
                this.broadcastCurrentQuestionEvent();
            }
        }
    }

    lookupFlowRecord(event) {
        var lid = event.detail.parentUid;
        var flowObj = event.detail.selectedRecord;

        console.log('lookupFlowRecord>>lid=' + lid);
        console.log('lookupFlowRecord>>flowObj=' + JSON.stringify(flowObj));
        var flowName = flowObj.ApiName;

        console.log('lookupFlowRecord>>flowName=' + flowName);

        for (var i = 0; i < this.logicList.length; i++) {
            if (this.logicList[i].id == lid) {
                this.logicList[i].flowName = flowName;
                var triggerAnswer = this.logicList[i].triggerAnswer;

                var currentQuestion = this.cloneValue(this.currentquestion);
                currentQuestion.flows = currentQuestion.flows || {};

                console.log('triggerAnswer=' + triggerAnswer);

                currentQuestion.flows[triggerAnswer] = flowName;
                // currentQuestion.flows.set(triggerAnswer, flowName);

                this.currentquestion = currentQuestion;
                this.broadcastCurrentQuestionEvent();
            }
        }
    }

    lookupFlowRecordForQuestionType(event) {
        var flowObj = event.detail.selectedRecord;

        var attributename = event.target.dataset.name;
        var currentQuestion = this.cloneValue(this.currentquestion);
        var oldValue = currentQuestion[attributename];
        currentQuestion[attributename] = '';
        currentQuestion['flowName'] = '';
        if (flowObj != null && flowObj != undefined && flowObj != '') {
            currentQuestion[attributename] = flowObj.Label;
            var flowName = flowObj.ApiName;
            if (flowObj.NamespacePrefix != undefined
                && flowObj.NamespacePrefix != ''
                && flowObj.NamespacePrefix != null) {
                flowName = flowObj.NamespacePrefix + '__' + flowObj.ApiName;
            }
            currentQuestion['flowName'] = flowName;
        }

        this.currentquestion = currentQuestion;
        this.broadcastCurrentQuestionEvent();
    }

    broadcastCurrentQuestionEvent() {
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { question: this.currentquestion }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}