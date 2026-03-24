// Audio Recording LWC
import { LightningElement, api } from 'lwc';
import createAudioFile from '@salesforce/apex/tbChatGPTController.createAudioFile';
import transcribeAudio from '@salesforce/apex/tbChatGPTController.transcribeAudio';
export default class TbInspQuestionAudioCaptureNG extends LightningElement {

    @api readOnly = false;
    mediaRecorder;
    recordedChunks = [];
    audioElement;
    mediaStream;
    mmtype = '';
    startRecording() {

        navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
            alert('recording started... speak something and press stop recording');

            this.mediaStream = stream;
            this.mediaRecorder = new MediaRecorder(stream);
            this.mmtype = 'audio/mpeg';
            this.mediaRecorder.start();
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    this.recordedChunks.push(event.data);
                }
            };
            this.mediaRecorder.onstop = () => {
                this.loadAudio(this.recordedChunks);
            };
        }).catch(err => {
            alert(err);
        });
    }
    stopRecording() {
        this.mediaRecorder.stop();
        // this.mediaStream.getTracks().forEach((track) => {
        //     track.stop();
        // });
    }

    loadAudio(recordedChunks) {
        alert('got recordedChunks....' + recordedChunks.length);
        this.mmtype = 'audio/wav'; //"audio/mpeg"
        const audioBlob = new Blob(recordedChunks, { 'type': this.mmtype });

        const audioName = this.question.index + ' - ' + this.inspectionRec.Name + '.wav'; //.mp3
        console.log(audioName);
        const audioFile = new File([audioBlob], audioName, {
            type: this.mmtype,
        });
        //const audioUrl = URL.createObjectURL(audioFile);
        const audioUrl = URL.createObjectURL(audioBlob);
        alert('got url after converting....' + audioUrl);
        console.log(audioUrl);
        this.audioElement = this.template.querySelector('audio');
        var sourceElement = document.createElement('source')
        this.audioElement.appendChild(sourceElement)

        const reader = new FileReader();
        reader.readAsDataURL(audioBlob);
        reader.onloadend = () => {

            console.log(audioName);

            var fileContents = reader.result;
            console.log('before substring');
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
            console.log('fileContents');
            var base64data = encodeURIComponent(fileContents);

            sourceElement.src = fileContents;
            sourceElement.type = this.mmtype;
            this.audioElement.load();

            createAudioFile({
                audioRecordingBase64String: base64data, fileName: audioName, inspectionId: this.inspectionRec.Id
            }).then(contentVersionId => {
                transcribeAudio({ contentVersionId: contentVersionId, inspectionId: this.inspectionRec.Id }).then(transcriptionString => {
                    // createRecords({noteRecordJSON: transcriptionString, taskRecordJSON: '', inspRecordId: this.inspectionRec.Id}).then(success => {
                    //     alert('Audio stored at Salesforce backend successfully');
                    // }).catch(error => {
                    //     alert(JSON.stringify(error));
                    //     console.log(error);
                    // });
                }).catch(error => {
                    alert(JSON.stringify(error));
                    console.log(error);
                })
            }).catch(error => {
                alert(JSON.stringify(error));
                console.log(error);
            });
        }
        // console.log(fileContents);
        // sourceElement.src = audioUrl;
        // sourceElement.type = 'audio/mpeg';
        // this.audioElement.load();

        // const audio = new Audio(audioUrl);
        // audio.play();


        // reader.readAsArrayBuffer(audioBlob);
        // reader.onloadend = () => {
        //     const audioArrayBuffer = reader.result;
        //     const audioBlob = new Blob([audioArrayBuffer], { type: 'audio/mpeg' });
        //     const audioUrl = URL.createObjectURL(audioBlob);
        //     const link = document.createElement('a');
        //     link.href = audioUrl;
        //     link.download = 'recorded-audio.mp3';
        //     link.click();
        // }
    }

    @api question = {};
    @api inspectionRec;

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }
    // @api get isValidValue() {
    //     var inputField = this.template.querySelector('lightning-input');
    //     inputField.reportValidity();
    //     var isValidValue = inputField.checkValidity();
    //     return isValidValue;
    // }
    broadcastUpdate(selectedValue) {
        console.log('Date handleChange..');
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: selectedValue, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }
}