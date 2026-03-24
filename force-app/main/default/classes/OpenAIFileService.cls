public class OpenAIFileService {
    // Method to upload a file to OpenAI
    public static String uploadFile(String apiKey, String fileName, Blob fileData) {
        //String openAIEndpoint = 'https://api.openai.com/v1/files';
        String assistantAPIBaseEndpoint = GlobalUtility.getGPTAssistantAPIBaseEndPoint();
        String openAIEndpoint = assistantAPIBaseEndpoint+ '/files';

        // Set the request body as multipart/form-data
        String boundary = '----------------------------741e90d31eff';
        String requestBody = '--' + boundary + '\nContent-Disposition: form-data; name="purpose"\n\nassistants\n';
        requestBody += '--' + boundary + '\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"\nContent-Type: application/json\n\n';
        requestBody += EncodingUtil.base64Encode(fileData) + '\n';
        requestBody += '--' + boundary + '--';
        
        Map<String, String> requestHeaders = new Map<String, String>{
            'Content-Type' => 'multipart/form-data; boundary=' + boundary
        };
        
        String httpMethod = 'POST';
        HTTPResponse res = HttpRequestService.doRequest(requestBody, httpMethod, openAIEndpoint, requestHeaders);
        
        // Handle the response
        String result = '';
        if (res.getStatusCode() == 200) {
            // File uploaded successfully
            System.debug('********* File uploaded successfully. Response: ' + res.getBody());
            result = res.getBody();
        } else {
            // Error handling
            System.debug('********* Error uploading file. Status code: ' + res.getStatusCode());
            System.debug('********* Error message: ' + res.getBody());
            result = 'error';
        }

        return result;
    }


    // Method to delete a file from OpenAI
    public static Boolean deleteFile(String apiKey, String fileId) {
        
        String assistantAPIBaseEndpoint = GlobalUtility.getGPTAssistantAPIBaseEndPoint();
        String openAIEndpoint = assistantAPIBaseEndpoint+ '/files/'+fileId;
        String requestBody = '';
        
        Map<String, String> requestHeaders = new Map<String, String>{};
        
        String httpMethod = 'DELETE';
        HTTPResponse res = HttpRequestService.doRequest(requestBody, httpMethod, openAIEndpoint, requestHeaders);
        

        Boolean result = false;
        if (res.getStatusCode() == 200) {
            // File deleted successfully
            result = true;
        } else {
            // Error handling
            System.debug('Error deleting file. Status code: ' + res.getStatusCode());
            System.debug('Error message: ' + res.getBody());
        }

        return result;
    }
}