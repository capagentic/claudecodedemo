import { LightningElement,api } from 'lwc';

let isMousePressed, isDotFlag = false, prevX = 0, currX = 0, prevY = 0, currY = 0;

let penColor = "#000000"; 
let lineWidth = 1.5;     


export default class InspQuestionSignature extends LightningElement {
    canvasElement;
    ctx; 
    convertedDataURI; //holds image data

    @api question = {};
    @api filesList = {};

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
    }

    updateAnswer(convertedDataURI){
        const valueChangeEvent = new CustomEvent('valuechanged', {
            detail: { index: this.question.index, answer: convertedDataURI, question: this.question }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleSaveClick(){
        //convert to png image as dataURL
        this.convertedDataURI = this.canvasElement.toDataURL("image/png");

        //console.log('signature handleChange..');
        this.updateAnswer(this.convertedDataURI);
    }

    //clear the signature from canvas
    handleClearClick(){
        this.ctx.clearRect(0, 0, this.canvasElement.width, this.canvasElement.height);
        this.updateAnswer('');
    }

    addEvents() {
        this.canvasElement.addEventListener('mousemove', this.handleMouseMove.bind(this));
        this.canvasElement.addEventListener('mousedown', this.handleMouseDown.bind(this));
        this.canvasElement.addEventListener('mouseup', this.handleMouseUp.bind(this));
        this.canvasElement.addEventListener('mouseout', this.handleMouseOut.bind(this));
        this.canvasElement.addEventListener("touchstart", this.handleTouchStart.bind(this));
        this.canvasElement.addEventListener("touchmove", this.handleTouchMove.bind(this));
        this.canvasElement.addEventListener("touchend", this.handleTouchEnd.bind(this));
    }
    
    handleMouseMove(event){
        if (isMousePressed) {
            this.setupCoordinate(event);
            this.redraw();
        }     
    }

    handleMouseDown(event){
        event.preventDefault();
        this.setupCoordinate(event);           
        isMousePressed = true;
        isDotFlag = true;
        if (isDotFlag) {
            this.drawDot();
            isDotFlag = false;
        }     
    }

    handleMouseUp(event){
        isMousePressed = false;
    }

    handleMouseOut(event){
        isMousePressed = false;
    }

    handleTouchStart(event) {
        if (event.targetTouches.length == 1) {
            this.setupCoordinate(event);
        }
    };

    handleTouchMove(event) {
        // Prevent scrolling.
        event.preventDefault();
        this.setupCoordinate(event);
        this.redraw();
    };

    handleTouchEnd(event) {
        var wasCanvasTouched = event.target === canvasElement;
        if (wasCanvasTouched) {
            event.preventDefault();
            this.setupCoordinate(event);
            this.redraw();
        }
    };

    renderedCallback() {
        canvasElement = this.template.querySelector('canvas.signature-pad');
        this.canvasElement.width = this.template.querySelector(".outerDiv").clientWidth;
        this.ctx = this.canvasElement.getContext("2d");
        this.ctx.lineCap = 'round';
        this.ctx.fillStyle = "#FFF"; //white
        this.ctx.fillRect(0,0,this.canvasElement.width, this.canvasElement.height);

        this.addEvents();
        if(this.filesList!= undefined && this.filesList != null 
            && this.filesList.hasOwnProperty(this.question.templateQuestionId)){
            var existingCtx = this.canvasElement.getContext("2d");
            var image = new Image();
            image.onload = function() {
                existingCtx.drawImage(image, 0, 0);
            };                    
            image.src = this.filesList[this.question.templateQuestionId];
        }
     }
    
    setupCoordinate(eventParam){
        try{
            const clientRect = this.canvasElement.getBoundingClientRect();
            prevX = currX;
            prevY = currY;
            var clientX = eventParam.clientX;
            var clientY = eventParam.clientY;
            if(eventParam.type =='touchmove' || eventParam.type == 'touchstart' || eventParam.type =='touchend') {
                clientX = eventParam.touches[0].clientX;
                clientY = eventParam.touches[0].clientY;
            }
            currX = clientX -  clientRect.left;
            currY = clientY - clientRect.top;
        } catch(e) {
          //  alert(e);
          //something is happening here on iphone device only,, so doing this...
            console.log(e);
        }
    }

    redraw() {
        this.ctx.beginPath();
        this.ctx.moveTo(prevX, prevY);
        this.ctx.lineTo(currX, currY);
        this.ctx.strokeStyle = penColor;
        this.ctx.lineWidth = lineWidth;        
        this.ctx.closePath(); 
        this.ctx.stroke(); 
        this.handleSaveClick();
    }
    drawDot(){
        this.ctx.beginPath();
        this.ctx.fillStyle = penColor;
        this.ctx.fillRect(currX, currY, lineWidth, lineWidth); 
        this.ctx.closePath();
        this.handleSaveClick();
    }

}