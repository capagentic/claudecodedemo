/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for GeoLocationService
 * Date: 10 Auth 2021
 */
@isTest
public with sharing class GeoLocationServiceTest {
    static String responseString = '{"results" : [{"formatted_address" : "Saishwar Apartment, Chhatrapati Shivaji Maharaj Rd, Bhavani Peth, Shobhapur, Kasba Peth, Pune, Maharashtra 411011, India","place_id" : "ChIJOcBsqGXAwjsRTA32Arz5g9g","types" : [ "premise" ]}],"status" : "OK"}';
    @IsTest
    static void test_getAddressByGeocode(){
        TestDataFactory.configureKineticSetting();
        Test.setMock(HttpCalloutMock.class, new GoogleResponseMock());
        Test.startTest();
            GeoLocationService.getAddressByGeocode('18.5204303','73.8567437');
            GoogleGeoCodingResponse resp = GoogleGeoCodingResponse.parse(GeoLocationServiceTest.responseString); 
            System.assertNotEquals(resp, null);
        Test.stopTest();
        
    }

    private class GoogleResponseMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = GeoLocationServiceTest.responseString; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}