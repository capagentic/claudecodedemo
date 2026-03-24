import { api, track, LightningElement } from 'lwc';
import invokeGeneratChecklistModel from '@salesforce/apex/tbChatGPTController.invokeGeneratChecklistModel';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import kineticsResources from '@salesforce/resourceUrl/kineticsresources';

export default class TbGenerateTemplateUsingChatGPT extends LightningElement {
    chatgptLogo = kineticsResources + '/kineticsresources/images/chatgpt-logo-blue.png';

    @api disableChatgpt;

    @api gptParameter = {};

    response = undefined;
    showSpinner = false;
    retryCount = 1;
    connectedCallback() {
        this.gptParameter = this.gptParameter || {};
        var localGPTParameters = JSON.parse(JSON.stringify(this.gptParameter));

        localGPTParameters['yourrole'] = this.gptParameter['yourrole'] || '';
        localGPTParameters['checklistneed'] = this.gptParameter['checklistneed'] || '';
        localGPTParameters['inspectionobjective'] = this.gptParameter['inspectionobjective'] || '';
        localGPTParameters['applicableStandards'] = this.gptParameter['applicableStandards'] || '';
        this.gptParameter = localGPTParameters;

        // this.disableChatgpt = false;
    }

    handleGPTParameterInputChange(event) {

        var gptPara = JSON.parse(JSON.stringify(this.gptParameter));
        gptPara[event.target.dataset.name] = event.target.value;
        this.gptParameter = gptPara;

        const valueChangeEvent = new CustomEvent('gptparametervalueupdate', {
            detail: { gptParameter: this.gptParameter }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    generateTemplate(event) {
        this.showSpinner = true;

        if (!this.isValidValue(this.gptParameter['yourrole'])
            || !this.isValidValue(this.gptParameter['checklistneed'])
            || !this.isValidValue(this.gptParameter['inspectionobjective'])) {
            this.showSpinner = false;
            this.showErrorMessage('Please provide required values for all the fields.');
            return 0;
        }

        this.response = '';
        invokeGeneratChecklistModel({ gptParameterString: JSON.stringify(this.gptParameter) }).then(success => {
            var localresponse = JSON.parse(success);
            //this.response = localresponse;
            if (this.isValidValue(localresponse)
                && this.isValidValue(localresponse.choices)
                && localresponse.choices.length > 0
                && this.isValidValue(localresponse.choices[0].message)
                && this.isValidValue(localresponse.choices[0].message.content))
                this.response = JSON.parse(localresponse.choices[0].message.content);

            this.initiatePageList(this.response);
            this.showSpinner = false;
            this.retryCount = 1;
        }).catch(error => {
            this.showSpinner = false;
            if (error.body.message == 'Read timed out' && this.retryCount <= 3) {
                this.generateTemplate();
                this.retryCount = this.retryCount + 1;
                this.showErrorMessage('Read Time out, Retrying again ');
            } else {
                this.showErrorMessage(error.body.message);
            }
        });
    }
    initiatePageList(rawRespomse) {
        console.log(rawRespomse);

        if (rawRespomse.sections == undefined
            && rawRespomse.checklist != undefined
            && rawRespomse.checklist.sections != undefined) {
            rawRespomse = rawRespomse.checklist;
        }

        var selectedFormValue = {
            'Name': rawRespomse.title || '',
            'Kinetics__Instructions__c': rawRespomse.instructions || '',
            'Kinetics__Status__c': 'Active',
            'Kinetics__Questions_By_Page_No__c': '{}',
            'Kinetics__Section_Metadata__c': '{}',
            'Kinetics__Chat_GPT_Parameters__c': this.gptParameter
        };

        var pagelist = [];
        pagelist.push(this.getDefaultPage());
        rawRespomse['sections'] = rawRespomse.sections || rawRespomse.checklist || [];
        for (var i = 0; i < rawRespomse.sections.length; i++) {
            var sec = rawRespomse.sections[i];
            sec.heading = sec.heading || sec.section_label || sec.title || '';
            pagelist[0].sectionlist.push(this.getDefaultSection(i, sec.heading));
            for (var j = 0; j < sec.questions.length; j++) {
                var que = sec.questions[j];
                var options = [];
                if (this.isValidValue(que.options)) {
                    for (var k = 0; k < que.options.length; k++) {
                        var opton = que.options[k];
                        opton.label = opton.label || opton.option_label || '';
                        options.push(
                            {
                                'value': opton.label,
                                'label': opton.label,
                                'color': opton.color || '#3273CB',
                                'optionno': (options.length + 1),
                                'score': opton.score
                            }
                        )
                    }
                }
                que.name = que.prompt || que.question_label || que.label || '';
                que.type = que.type || que.question_type || 'Text';
                pagelist[0].sectionlist[i].questionWrapperList.push(this.addQuestionToListHelper(0, i, que.name, que.type, options));
            }
        }
        const valueChangeEvent = new CustomEvent('templategenerated', {
            detail: { template: selectedFormValue, pagelist: pagelist }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    isValidValue(valObj) {
        if (valObj != undefined && valObj != '' && valObj.length != 0) {
            return true;
        }
        return false;
    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Template Builder',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    getPassFailOptions() {
        var optionsArr = [];
        optionsArr.push(
            {
                'value': 'Pass',
                'label': 'Pass',
                'color': '#379941',
                'optionno': (optionsArr.length + 1),
                'score': 1
            });
        optionsArr.push(
            {
                'value': 'Fail',
                'label': 'Fail',
                'color': '#EE0707',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        optionsArr.push(
            {
                'value': 'NA',
                'label': 'NA',
                'color': '#BAB0B0',
                'optionno': (optionsArr.length + 1),
                'score': 0
            });
        return optionsArr;
    }

    addQuestionToListHelper(pageno, sectionno, qtext, qtype, options) {

        if (qtype == 'picklist') {
            qtype = 'Radio Button';
        } else if (qtype == 'multiselect picklist' || qtype == 'multiselect_picklist') {
            qtype = 'Checkbox';
        } else if (qtype == 'pass/fail') {
            qtype = 'Pass Fail';
            if (options.length == 0) {
                options = this.getPassFailOptions();
            }
        } else if (qtype == 'datetime') {
            qtype = 'Date & Time';
        } else if (qtype == 'textarea') {
            qtype = 'Text Area';
        } else if (qtype == '1-10 star rating' || qtype == '1-10_star_rating') {
            qtype = 'Rating';
        } else if (qtype == 'photos' || qtype == 'photo') {
            qtype = 'File';
        } else if (qtype == 'geolocation') {
            qtype = 'Geo Location';
        } else if (qtype == 'net_promoter_score') {
            qtype = 'Net Promoter Score';
        }

        qtype = qtype.charAt(0).toUpperCase() + qtype.slice(1);

        var alreadyQuestions = 0;
        sectionno = parseInt(sectionno);// - 1;
        pageno = parseInt(pageno);// - 1;
        var newQuestion = {
            'uid': pageno + '.' + sectionno + '.' + alreadyQuestions,
            'Name': qtext || '',
            'Kinetics__Field_Type__c': qtype || 'Text',
            'Kinetics__Assign_Tasks__c': true,
            'Kinetics__Attach_Photos_or_Files__c': true,
            'Kinetics__Capture_Notes__c': true,
            'Kinetics__Required__c': true,
            'Kinetics__Values__c': options,
            'displayQuestionNo': pageno + '.' + alreadyQuestions,
            'pageno': pageno,
            'sectionno': sectionno,
            'isdragover': false
        };

        return newQuestion;
    }

    getDefaultPage() {
        var pageno = 0;
        var pageWrapper = {
            'pageno': pageno,
            'displayno': pageno + 1,
            'sectionlist': []
        };
        return pageWrapper;
    }

    getDefaultSection(sectionno, sectiontitle) {
        return {
            'sectionno': sectionno,
            'stitle': sectiontitle,
            'sinstructions': '',
            'displayno': sectionno,
            'questionWrapperList': []
        };
    }

}