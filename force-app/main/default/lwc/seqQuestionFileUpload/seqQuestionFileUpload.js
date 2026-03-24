import { LightningElement, api } from 'lwc';
const MAX_SUPPORTED_FILE_SIZE = 1000000;
const imageFilterType = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i;

export default class SeqQuestionFileUpload extends LightningElement {

    @api question = {};
    options = [];

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        this.initQuestion();
    }

    fileName = '';
    filesUploaded = [];
    @api isLoading = false;
    fileSize;

    initQuestion() {
        this.fileName = this.question.answer;
    }

    handleChange(event) {
        this.isLoading = true;
        var fileReader = new FileReader();
        var self = this;
        this.filesUploaded = event.target.files;
        this.fileName = event.target.files[0].name;
        var fileCon = this.filesUploaded[0];
        fileReader.onload = function (event) {
            var image = new Image();
            image.onload=function(){
                var canvas = document.createElement("canvas");
                var context = canvas.getContext("2d");
                canvas.width = image.width;
                canvas.height = image.height;
                //context.drawImage(image, 0, 0, image.width, image.height, 0, 0, canvas.width, canvas.height);
                context.drawImage(image, 0, 0);
                
                var quality = 0.90;
                var fileContents = canvas.toDataURL('image/jpeg', quality);
                while(fileContents.length > MAX_SUPPORTED_FILE_SIZE && quality >= 0.20) {
                    quality = quality - 0.10;
                    fileContents = null;
                    fileContents = canvas.toDataURL('image/jpeg', quality);
                }

                self.fileSize = self.formatBytes(fileContents.length, 2);
                console.log('file handleChange..');
                const valueChangeEvent = new CustomEvent('valuechanged', {
                    detail: { index: self.question.index, answer: fileCon, question: self.question }
                });
                self.dispatchEvent(valueChangeEvent);
                self.isLoading = false;
            }
            image.src=event.target.result;
        };
        if (event.target.files.length > 0) {
            if (imageFilterType.test(fileCon.type)) {
                fileReader.readAsDataURL(fileCon);
            } else {
                this.fileSize = this.formatBytes(fileCon.size, 2);
                console.log('file handleChange..');
                const valueChangeEvent = new CustomEvent('valuechanged', {
                    detail: { index: this.question.index, answer: fileCon, question: this.question }
                });
                this.dispatchEvent(valueChangeEvent);
                this.isLoading = false;
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