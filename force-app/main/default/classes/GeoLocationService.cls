public with sharing class GeoLocationService {
    final static String PREMISE = 'premise';

    @AuraEnabled
    public static String getAddressByGeocode(String latitude, String longitude){
        GoogleGeoCodingResponse geocodingRes = reverseGeocoding(longitude,latitude);
        List<String> addrList = new List<String>();

        System.debug('####geocodingRes size : '+geocodingRes.results.size());
        if(geocodingRes.results != null &&  geocodingRes.results.size() > 0){
            for(GoogleGeoCodingResponse.Results r: geocodingRes.results){
                String types = r.types.toString();
                system.debug('******* = ' +r.formatted_address + ', type=' + types);
                if(types.contains(PREMISE)){
                    addrList.add(r.formatted_address);
                }
            }
        }
        
        GeoLocationServiceResponse res = new GeoLocationServiceResponse();
        res.statusCode = '2000';
        res.responseMessage = 'success';
        res.responseDetails = addrList;

        return JSON.serialize(res);
    }

    // @future(callout=true)
    public static GoogleGeoCodingResponse reverseGeocoding(String latitude, String longitude) {     
        String address=longitude + '+' + latitude;
        String key = GlobalUtility.getGoogleAPIKey();
        Http httpProtocol = new Http();
        // Create HTTP request to send.
        HttpRequest request = new HttpRequest();
        // Set the endpoint URL.
        String endpoint = GlobalConstants.geocodeAPIURL + '?address='+address+'&key='+key;
        request.setEndPoint(endpoint);
        // Set the HTTP verb to GET.
        request.setMethod('GET');
        // Send the HTTP request and get the response.
        // The response is in JSON format.
        HttpResponse response = httpProtocol.send(request);
        System.debug('####Body : '+response.getBody());


        GoogleGeoCodingResponse geocodingRes = (GoogleGeoCodingResponse) JSON.deserialize(response.getBody(), GoogleGeoCodingResponse.class);

        return geocodingRes;
    }  
    
    public class GeoLocationServiceResponse{
        String statusCode;
        String responseMessage;
        Object responseDetails;
    }
}