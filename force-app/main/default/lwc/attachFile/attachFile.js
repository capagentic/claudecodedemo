import { LightningElement, api } from 'lwc';
import uploadFile from '@salesforce/apex/createEditKineticQuestionLWCHelper.uploadFile'
import deleteExistingFiles from '@salesforce/apex/createEditKineticQuestionLWCHelper.deleteExistingFiles';
import Add_Attachment from '@salesforce/label/c.Add_Attachment';
import Close from '@salesforce/label/c.Close';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';

export default class AttachFile extends LightningElement {
    @api recordId;
    @api values;
    @api allowedTypeOfAttachment;
    @api label = {Add_Attachment, Close, Cancel, Save};
    @api isLoading=false;

    attachmentMapByValue = {};
    existingAttIdsToBeDeleted = [];
    openfileUpload(event) {
        this.isLoading = true;
        const file = event.target.files[0]
        const title = event.target.name;
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            var fileData = {
                'filename': file.name,
                'title': title,
                'recordId': this.recordId
            }
            let tempObj = this.cloneObject(this.values);
            for(var i = 0;i<tempObj.length;i++) {
                if(tempObj[i].key === title) {
                    tempObj[i]['filename'] = fileData.filename;
                    this.template.querySelector("img[data-my-id='"+title+"']").src = reader.result;
                    break;
                }
            }            
            this.values = tempObj;

            fileData['base64'] = base64;
            this.attachmentMapByValue[title] = fileData;
            fileData = {};
            base64 = {};
            this.isLoading = false;
        }  
        reader.readAsDataURL(file)
    }
    //Get Javascript object equivalent to Proxy
    cloneObject(obj){
        return JSON.parse(JSON.stringify(obj));
    }
    
    handleClick(){
        this.isLoading = true;
        this.uploadFileToServer(JSON.parse(JSON.stringify(this.values)));
    }

    uploadFileToServer(values) {
        if(values.length > 0) {
            var option = values.pop();
            if(this.attachmentMapByValue.hasOwnProperty(option.key)){
                var {base64, filename, recordId, title} = this.attachmentMapByValue[option.key];
                if(title !== 'QuestionAttachment') {
                    title = title + this.recordId;
                }
                uploadFile({ base64, filename, recordId, title }).then(result=>{
                    if(option.existingAttId != undefined) {
                        this.existingAttIdsToBeDeleted.push(option.existingAttId);
                    }
                    this.uploadFileToServer(values);
                }).catch(error => {
                    alert(error.body.message);
                });
            } else {
                this.uploadFileToServer(values);
            }
        } else {
            if(this.existingAttIdsToBeDeleted.length > 0) {
                deleteExistingFiles({'questionId': this.recordId, 'contentVersionIds': this.existingAttIdsToBeDeleted}).then(data => {
                    this.isLoading = false;
                    this.closeModal();
                }).catch(error => {
                    alert(error.body.message);
                });
            } else {
                this.isLoading = false;
                this.closeModal();
            }
        }
    }
    closeModal() {
        this.isModalOpen = false;
        const customevent = new CustomEvent('popupclose', {
            detail: {isModalOpen:this.isModalOpen}
        });
        this.dispatchEvent(customevent);
    }   
}