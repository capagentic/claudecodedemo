import { LightningElement, track, api } from 'lwc';
import getAddressByGeocode from '@salesforce/apex/GeoLocationService.getAddressByGeocode';

export default class SeqGeoLocation extends LightningElement {
    @api question = {};
    @track longitude;
    @track latitude;
    @track addresses = [];
    @track address;
    @track options;

    @api
    get questionId() {
        return this.questionId;
    }
    set questionId(value) {
        this.setAttribute('questionId', value);
        //this.initQuestion();
    }
    //stores current latitude and longitude for map component
    mapMarkers = [];
    //flag restricts accessing geolocation api multiple times
    isRendered = false;

    //callback after the component renders
    renderedCallback() {
        if (!this.isRendered) {
            this.getCurrentBrowserLocation();
            const style = document.createElement('style');
            style.innerText = `c-seq-geo-location .slds-map {
                                min-width: 0 !important;
                                }`;
            this.template.querySelector('lightning-map').appendChild(style);

        }
        //sets true once the location is fetched
        this.isRendered = true;
    }

    getCurrentBrowserLocation() {
        var options = {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 0
        };
        var mapOptions = {
            'disableDefaultUI': true
        };
        this.mapOptions = mapOptions;

        if (navigator.geolocation) {
            //accessing getCurrentPosition method
            navigator.geolocation.getCurrentPosition((position) => {
                //success callback
                let currentLocation = {
                    location: {
                        Latitude: position.coords.latitude,
                        Longitude: position.coords.longitude
                    },
                    title: 'My location'
                };
                this.mapMarkers = [currentLocation];
                this.longitude = position.coords.longitude;
                this.latitude = position.coords.latitude;

                if (this.longitude && this.latitude) {
                    this.getAddresses(this.latitude, this.longitude);
                }
            }, (error) => {
                //error callback
            }, options);
        }
    }

    getAddresses(latitude, longitude) {
        getAddressByGeocode({
            latitude: latitude,
            longitude: longitude
        })
            .then(result => {
                var resObj = JSON.parse(result);

                if (resObj.statusCode == '2000') {
                    this.addresses = resObj.responseDetails;

                    if (this.addresses.length > 0) {
                        console.log('showing address....');
                        this.address = this.addresses[0];
                        const valueChangeEvent = new CustomEvent('valuechanged', {
                            detail: { index: this.question.index, answer: this.address, question: this.question }
                        });
                        this.dispatchEvent(valueChangeEvent);
                    } else {
                        var latitudeLongitude = latitude + ',' + longitude;
                        const valueChangeEvent = new CustomEvent('valuechanged', {
                            detail: { index: this.question.index, answer: latitudeLongitude, question: this.question }
                        });
                        this.dispatchEvent(valueChangeEvent);
                    }
                } else if (resObj.statusCode == '2100') {
                    var latitudeLongitude = latitude + ',' + longitude;
                    const valueChangeEvent = new CustomEvent('valuechanged', {
                        detail: { index: this.question.index, answer: latitudeLongitude, question: this.question }
                    });
                    this.dispatchEvent(valueChangeEvent);
                }



            })
            .catch(error => {
            });
    }

}