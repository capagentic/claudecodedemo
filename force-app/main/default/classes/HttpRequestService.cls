/***
* Author: Shankar Dupade (FieldKo)
* Updated : 30th Aug 2021
* Purpose: Helpr class to do HTPP callouts
*/
public with sharing class HttpRequestService {
    
    public static HttpResponse doRequest(String requestPayload, String httpMethod, String endPoint, Map<String, String> requestHeaders){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endPoint);
        httpReq.setMethod(httpMethod);
        httpReq.setTimeout(120000);

        if(requestPayload!=null) {
            httpReq.setBody(requestPayload);    
        }
        for(String hederkey : requestHeaders.keySet()) {
            httpReq.setHeader(hederkey, requestHeaders.get(hederkey));
        }

        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        res = http.send(httpReq);

        return res;
  } 
}