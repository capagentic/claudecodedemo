import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
const MAX_SUPPORTED_FILE_SIZE = 1000000;
const imageFilterType = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i;


export default class InspQuestionFooterActions extends NavigationMixin(LightningElement) {
    @api question;
    @api inspectionRec;
    @api templateName;
    @track showTaskCreationPopup = false;
    @track showNoteCreationPopup = false;

    filesUploaded = [];
    fileSize;

    screenLoaded = false;
    get dynamicactionclass() {
        var actionclass = 'lds-p-around_x-small lgc-bg slds-col ';
        var enabledQuestionAttributes = 0;
        if (this.question.captureNotesEnabled) {
            enabledQuestionAttributes = enabledQuestionAttributes + 1;
        }
        if (this.question.attachPhotoEnabled && this.isFileTypeQuestion == false) {
            enabledQuestionAttributes = enabledQuestionAttributes + 1;
        }
        if (this.question.assignTaskEnabled) {
            enabledQuestionAttributes = enabledQuestionAttributes + 1;
        }

        if (enabledQuestionAttributes == 1) {
            actionclass = actionclass + "slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12";
        }
        if (enabledQuestionAttributes == 2) {
            actionclass = actionclass + "slds-size_6-of-12 slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_6-of-12";
        }
        if (enabledQuestionAttributes == 3) {
            actionclass = actionclass + "slds-size_4-of-12 slds-large-size_4-of-12 slds-medium-size_4-of-12 slds-small-size_4-of-12";
        }
        return actionclass;
    }

    @api
    get isFileTypeQuestion() {
        return this.question.fieldType == 'File';
    }

    handleAddNote(event) {
        this.showNoteCreationPopup = true;
    }

    handleAddAttachment(event) {
        this.template.querySelector('input[data-name="fileuploader"]').click();
    }

    handleAddTask(event) {
        this.showTaskCreationPopup = true;
    }

    closeTaskPopupModel(event) {
        this.showTaskCreationPopup = event.detail.closeTaskCreationPopup;
    }

    closeNotePopupModel(event) {
        this.showNoteCreationPopup = event.detail.closeTaskCreationPopup;
    }

    maintainVisitNotesRecords(event) {
        var question = event.detail.question;
        var noteId = event.detail.noteId;
        var noteRec = event.detail.noteRec;
        const valueChangeEvent = new CustomEvent('noterecordcreate', {
            detail: { question: question, noteId: noteId, noteRec: noteRec }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    maintainTaskRecords(event) {
        var question = event.detail.question;
        var taskId = event.detail.taskId;
        var taskRec = event.detail.taskRec;
        const valueChangeEvent = new CustomEvent('taskrecordcreate', {
            detail: { question: question, taskId: taskId, taskRec: taskRec }
        });
        this.dispatchEvent(valueChangeEvent);
    }


    handlefilechange(event) {
        var fileReader = new FileReader();
        var self = this;
        this.filesUploaded = event.target.files;
        var fileCon = this.filesUploaded[0];
        //const filename = fileCon.name.split('.').slice(0, -1).join('.');
        const ext = fileCon.name.substr(fileCon.name.lastIndexOf('.') + 1);
        const fileType = fileCon['type'];
        const validImageTypes = ['image/gif', 'image/jpeg', 'image/png'];
        const dateValue = new Date().toLocaleString();
        if (validImageTypes.includes(fileType)) {
            fileCon['updatedname'] = this.inspectionRec.Name + ' (Q' + this.question.index + ') ' + dateValue + '.' + ext;
        } else {
            fileCon['updatedname'] = this.inspectionRec.Name + ' (Q' + this.question.index + ') ' + dateValue + ' ' + fileCon['name'];
        }

        fileReader.onload = function (event) {
            var image = new Image();
            image.onload = function () {
                var canvas = document.createElement("canvas");
                var context = canvas.getContext("2d");
                canvas.width = image.width;
                canvas.height = image.height;
                context.drawImage(image, 0, 0);

                var quality = 0.90;
                var fileContents = canvas.toDataURL('image/jpeg', quality);
                while (fileContents.length > MAX_SUPPORTED_FILE_SIZE && quality >= 0.20) {
                    quality = quality - 0.10;
                    fileContents = null;
                    fileContents = canvas.toDataURL('image/jpeg', quality);
                }

                self.fileSize = self.formatBytes(fileContents.length, 2);
                console.log('file handleChange..');
                const valueChangeEvent = new CustomEvent('fileupload', {
                    detail: { file: fileCon, question: self.question }
                });
                self.dispatchEvent(valueChangeEvent);
            }
            image.src = event.target.result;
        };
        if (event.target.files.length > 0) {
            if (imageFilterType.test(fileCon.type)) {
                fileReader.readAsDataURL(fileCon);
            } else {
                this.fileSize = this.formatBytes(fileCon.size, 2);
                console.log('file handleChange..');
                const valueChangeEvent = new CustomEvent('fileupload', {
                    detail: { file: fileCon, question: this.question }
                });
                this.dispatchEvent(valueChangeEvent);
            }
        }
    }

    formatBytes(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
}