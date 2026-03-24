/**
 * Author: Shankar Dupade
 * Date: 29-02-2024
 * Purpose: controller class to invoke chat gpt assistant api call
 */
public with sharing class AssistantAPIController {

    static String assistantAPIBaseEndpoint = GlobalUtility.getGPTAssistantAPIBaseEndPoint();

    private static Map<String, String> getHeaderForAssistantAPI() {
        Map<String, String> requestHeaders = new Map<String, String>();
        return requestHeaders;
    }

    public static String create_update_Assistance(Map<String, String> assistantDetailsMap){

        String endPoint = assistantAPIBaseEndpoint+ '/assistants';
        
        if(assistantDetailsMap.containsKey('assistantID') 
            && String.isNotBlank(assistantDetailsMap.get('assistantID'))) {
            endPoint = endPoint + '/'+assistantDetailsMap.get('assistantID');
        }

        String httpMethod = 'POST';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('instructions', assistantDetailsMap.get('instructions'));
        requestBodyMap.put('name', assistantDetailsMap.get('name'));
        requestBodyMap.put('model', assistantDetailsMap.get('model'));

        List<Map<String, String>> toolsMapList = new List<Map<String,String>>();
        if(assistantDetailsMap.containsKey('code_interpreter') 
            && Boolean.valueOf(assistantDetailsMap.get('code_interpreter'))==true){
            toolsMapList.add(new Map<String, String>{'type' => 'code_interpreter'});
        }
        if(assistantDetailsMap.containsKey('retrieval')
            && Boolean.valueOf(assistantDetailsMap.get('retrieval'))==true){
            toolsMapList.add(new Map<String, String>{'type' => 'retrieval'});
        }

        requestBodyMap.put('tools', toolsMapList);

        String requestPayload = JSON.serialize(requestBodyMap);

        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
    
        system.debug('res:' + res.getBody());
     
        
        return res.getBody();
    }

    public static String delete_Assistance(Map<String, String> assistantDetailsMap){

        String endPoint = assistantAPIBaseEndpoint+ '/assistants';
        
        if(assistantDetailsMap.containsKey('assistantID') 
            && String.isNotBlank(assistantDetailsMap.get('assistantID'))) {
            endPoint = endPoint + '/'+assistantDetailsMap.get('assistantID');
        }

        String httpMethod = 'DELETE';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        Map<String, Object> requestBodyMap = new Map<String, Object>();
      
        String requestPayload = JSON.serialize(requestBodyMap);

        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
    
        system.debug('res:' + res.getBody());
        return res.getBody();
    }

    public static String create_update_Thread(Map<String, String> inputMap) {
       
        String threadId = '';
        String transcriptText = '';
        String sfRecordId = '';
        String sfRecordName = '';
        String promptTemplateName = '';
        String assistantName = '';
        if(inputMap.containsKey('threadId')) {
            threadId = inputMap.get('threadId');
        } 
        // if(inputMap.containsKey('callTranscript') ) {
        //     transcriptText = inputMap.get('callTranscript');
        // }
        if(inputMap.containsKey('sfRecordId')) {
            sfRecordId = inputMap.get('sfRecordId');
        }
        if(inputMap.containsKey('sfRecordName')) {
            sfRecordName = inputMap.get('sfRecordName');
        }
        if(inputMap.containsKey('promptTemplateName')) {
            promptTemplateName = inputMap.get('promptTemplateName');
        }
        if(inputMap.containsKey('assistantName')) {
            assistantName = inputMap.get('assistantName');
        }
        
        String endPoint = assistantAPIBaseEndpoint+ '/threads';
        if(String.isNotBlank(threadId)) {
            endPoint = endPoint + '/' + threadId;
        }

        String httpMethod = 'POST';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        List<Map<String, String>> messageMapList = new List<Map<String, String>>();
        // String contentString = 'Here is the call transcript: ' + transcriptText;
        // messageMapList.add(new Map<String, String>{'role'=>'user', 'content' => contentString});
        // requestBodyMap.put('messages', messageMapList);
        Map<String, String> metadataMap = new Map<String, String>();
        metadataMap.put('Salesforce URL', Url.getOrgDomainUrl().toExternalForm() + '/' + sfRecordId);
        metadataMap.put('Salesforce Record Name', sfRecordName);
        metadataMap.put('Salesforce Record ID', sfRecordId);
        metadataMap.put('Created By', UserInfo.getName() + ' (' + UserInfo.getUserName() + ')');
        metadataMap.put('Assistant', assistantName);
        metadataMap.put('Prompt Template', promptTemplateName);
        
        requestBodyMap.put('metadata', metadataMap);

        String requestPayload = JSON.serialize(requestBodyMap);

        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);

        String calloutResponse = res.getBody();

        system.debug('res:' + calloutResponse);
        return calloutResponse;
    }

    // public static String pushCallTranscription(Map<String, String> inputMap) {
    //     String threadId = '';
    //     String transcriptText = '';
    //     List<String> fileIdsList = new List<String>();
        
    //     if(inputMap.containsKey('threadId')) {
    //         threadId = inputMap.get('threadId');
    //     } 
    //     if(inputMap.containsKey('callTranscript') ) {
    //         transcriptText = inputMap.get('callTranscript');
    //     }
      
    //     if(inputMap.containsKey('sfFileIds')
    //         && String.isNotBlank(inputMap.get('sfFileIds'))) {
    //         fileIdsList = inputMap.get('sfFileIds').split(',');
    //     }
        
    //     if(String.isBlank(threadId)) {
    //         return 'error: thread ID is required';
    //     }

    //     String endPoint = assistantAPIBaseEndpoint+ '/threads';
    //     if(String.isNotBlank(threadId)) {
    //         endPoint = endPoint + '/' + threadId;
    //     }
    //     endPoint = endPoint + '/messages';


    //     String httpMethod = 'POST';
    //     Map<String, String> requestHeaders = getHeaderForAssistantAPI();
        
    //     Map<String, Object> requestBodyMap = new Map<String, Object>();
    //     List<Map<String, String>> messageMapList = new List<Map<String, String>>();
    //     String contentString = '';
    //     if(String.isNotBlank(transcriptText) 
    //         && transcriptText != null
    //         && transcriptText.length() < 25000) {
    //         contentString = contentString + 'Here is the call transcript: ' + transcriptText;
    //     }
    //     if (fileIdsList.size() > 0) {
    //         contentString = contentString + 'Please read the file attached to get the call transcription for analysis,';
    //     }
       
    //     requestBodyMap.put('role', 'user');
    //     requestBodyMap.put('content',contentString);
    //     requestBodyMap.put('file_ids', fileIdsList);
    //     String requestPayload = JSON.serialize(requestBodyMap);

    //     HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);

    //     String calloutResponse = res.getBody();

    //     system.debug('res:' + calloutResponse);
    //     return calloutResponse;
    // }

    public static String pushCallTranscription(Map<String, String> inputMap) {
        String threadId = '';
        String transcriptText = '';
        List<String> fileIdsList = new List<String>();
        
        if(inputMap.containsKey('threadId')) {
            threadId = inputMap.get('threadId');
        } 
        if(inputMap.containsKey('callTranscript') ) {
            transcriptText = inputMap.get('callTranscript');
        }
      
        if(inputMap.containsKey('sfFileIds')
            && String.isNotBlank(inputMap.get('sfFileIds'))) {
            fileIdsList = inputMap.get('sfFileIds').split(',');
        }
        
        if(String.isBlank(threadId)) {
            return 'error: thread ID is required';
        }

        String endPoint = assistantAPIBaseEndpoint+ '/threads';
        if(String.isNotBlank(threadId)) {
            endPoint = endPoint + '/' + threadId;
        }
        endPoint = endPoint + '/messages';


        String httpMethod = 'POST';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();
        
        
        List<Map<String, String>> messageMapList = new List<Map<String, String>>();
        String contentString = '';
        Integer startIndex = 0;
        Integer lastIndex = 25000;
        if(String.isNotBlank(transcriptText) 
            && transcriptText != null
            && transcriptText.length() <= lastIndex) {
            contentString = contentString + 'Here is the call transcript: ' + transcriptText;
            transcriptText = transcriptText.replace(contentString, '');
        } else {
            System.debug(transcriptText);
            contentString = contentString + 'I am sending call transcript in multiple parts, please read all the call transcription parts for analysis,';
            String firstSubstring = transcriptText.substring(startIndex, lastIndex);
            contentString = contentString + firstSubstring;
            transcriptText = transcriptText.replace(firstSubstring, '');
        }
        // if (fileIdsList.size() > 0) {
        //     contentString = contentString + 'Please read the file attached to get the call transcription for analysis,';
        // }
        
        return sendRemainingCallTranscription(contentString, fileIdsList, httpMethod, endPoint, requestHeaders, startIndex, lastIndex, transcriptText);
    }

    private static String sendRemainingCallTranscription(String contentString, List<String> fileIdsList, String httpMethod,
                            String endPoint, Map<String, String> requestHeaders, Integer startIndex, Integer lastIndex,
                            String transcriptText) {
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('role', 'user');
        requestBodyMap.put('content',contentString);
        if(fileIdsList.size() > 0){
            requestBodyMap.put('file_ids', fileIdsList);
        }
        String requestPayload = JSON.serialize(requestBodyMap);

        if(transcriptText.length() == 0) {
            HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
            String calloutResponse = res.getBody();
            system.debug('res:' + calloutResponse);
            return calloutResponse;
        } else {
            HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
           // startIndex = 0;
            if(transcriptText.length() < lastIndex) {
                lastIndex = transcriptText.length();
            }
            String substring = transcriptText.substring(startIndex, lastIndex);
            contentString =  substring;
            transcriptText = transcriptText.replace(substring, '');
            return sendRemainingCallTranscription(contentString, fileIdsList, httpMethod, endPoint, requestHeaders, startIndex, lastIndex, transcriptText);
        }
    }

    public static String create_update_Message(String requestPayload, String threadId) {
       
        if(String.isBlank(threadId)) {
            return 'error: thread ID is required';
        }

        String endPoint = assistantAPIBaseEndpoint+ '/threads/' + threadId + '/messages';
        
        String httpMethod = 'POST';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
        system.debug('res:' + res.getBody());

        return res.getBody();
    }

    public static String create_Run(String assistantID, String threadId) {
        
        if(String.isBlank(assistantID)) {
            return 'error: assistantID is required';
        }
        if(String.isBlank(threadId)) {
            return 'error: thread ID is required';
        }
        String endPoint = assistantAPIBaseEndpoint +'/threads/'+threadId + '/runs';
        String httpMethod = 'POST';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('assistant_id', assistantID);
        List<Map<String, String>> toolsMapList = new List<Map<String,String>>();

        // toolsMapList.add(new Map<String, String>{'type' => 'retrieval'});
        // toolsMapList.add(new Map<String, String>{'type' => 'code_interpreter'});
        // requestBodyMap.put('tools', toolsMapList);  
        // requestBodyMap.put('instructions', 'You are an expert is assessing how to provide feedback and coaching for sales calls using call transcription stored in file'); 
    
        String requestPayload = JSON.serialize(requestBodyMap);
        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);

        system.debug('res:' + res.getBody());
        return res.getBody();
    }

    public static String retriveAllMessagesForThread(String threadId){

        String endPoint = assistantAPIBaseEndpoint + '/threads';
        if(String.isNotBlank(threadId)) {
            endPoint = endPoint + '/' + threadId;
        }
        endPoint = endPoint + '/messages?limit=5';
        String httpMethod = 'GET';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();
        
        String requestPayload = null;
        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
        String calloutResponse = res.getBody();

        system.debug('res:' + calloutResponse);
        return calloutResponse;
    }

    public static String getAllAvailableAssistants() {
        String endPoint = assistantAPIBaseEndpoint + '/assistants';
        String httpMethod = 'GET';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        String requestPayload = null;
        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
        String calloutResponse = res.getBody();
        return calloutResponse;
    }

    public static String getRetrieveRun(String threadId, String runId) {
        String endPoint = assistantAPIBaseEndpoint + '/threads/'+threadId+'/runs/'+runId;
        String httpMethod = 'GET';
        Map<String, String> requestHeaders = getHeaderForAssistantAPI();

        String requestPayload = null;
        HTTPResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeaders);
        String calloutResponse = res.getBody();
        return calloutResponse;
    }
}