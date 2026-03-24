import { LightningElement, track, api } from 'lwc';
import getAnswers from '@salesforce/apex/KineticAnswerController.getAnswers';

const actions = [
    { label: 'View Details', name: 'viewRecord' },
    { label: 'View Attachments', name: 'viewAttachments' },
];

const columns = [
    {
        label: 'Index', fieldName: 'qIndex', initialWidth: 90, cellAttributes: {
            class: 'slds-border_left',
            alignment: 'center',
        }
    },
    {
        label: 'Question', fieldName: 'qTitle', cellAttributes: {
            class: 'slds-border_left',
            alignment: 'left',
        }
    },
    {
        label: 'Answer', fieldName: 'recordUrl', type: 'url', cellAttributes: {
            class: 'slds-border_left',
            alignment: 'left',
        }, typeAttributes: { label: { fieldName: 'answer' }, target: 'blank' }
    },
    // {
    //     label: "Action",
    //     initialWidth: 90,
    //     type: 'action',
    //     typeAttributes: { rowActions: actions },
    // },
];

export default class KineticAnswers extends LightningElement {
    @api recordId;
    @track answers = [];
    @track answersLength = 0;
    columns = columns;

    connectedCallback() {
        let surveyInviteId = this.recordId;
        this.getAnswers(surveyInviteId);
    }

    getAnswers(surveyInviteId) {
        console.log('getAnswers...');
        getAnswers({
            surveyInviteId: surveyInviteId
        })
            .then(result => {
                console.log(result);
                var resObj = JSON.parse(result);
                if (resObj.statusCode == '2000') {
                    this.answers = resObj.responseDetails;
                    this.answersLength = this.answers.length;
                } else if (resObj.statusCode == '2100') {

                }

            })
            .catch(error => {
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {

            case 'viewRecord':
                this.viewRowDetails(row);
                break;
            case 'viewAttachments':
                this.viewAttachments(row);
                break;
            default:
        }
    }

    viewRowDetails(row) {
        console.log('viewRowDetails');
        this.record = row;
    }

    viewAttachments(row) {
        console.log('viewAttachments');
        this.record = row;
    }
}