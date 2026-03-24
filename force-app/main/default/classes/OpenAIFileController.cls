public with sharing class OpenAIFileController {
    
    
    @AuraEnabled
    public static String uploadFile(String fileName, String contentDocumentId) {
        List<ContentVersion> contentVersions = [SELECT Id, VersionData 
                                                    FROM ContentVersion 
                                                    WHERE ContentDocumentId =: contentDocumentId LIMIT 1];
                                                
        
        Blob fileContent;
        ContentVersion cv;
        if (!contentVersions.isEmpty() && contentVersions[0].VersionData != null) {
            fileContent = contentVersions[0].VersionData;
            cv = contentVersions[0];
        }
        
        
        String apiKey = '';
        // system.debug('***** fileContent=' + fileContent.tostring());
        String result = OpenAIFileService.uploadFile(apiKey, fileName, fileContent);

        if(result != 'error'){
            Map<String, String> resultMap = (Map<String, String>) JSON.deserialize(result, Map<String, String>.class);
            String fileID;
            if(resultMap.containsKey('id')){
                fileID = resultMap.get('id');

                ContentVersion cvUpdate = new ContentVersion();
                cvUpdate.Id = cv.Id;
                cvUpdate.Kinetics__External_ID__c = fileID;
                cvUpdate.Kinetics__External_System__c = 'ChatGPT';
                update cvUpdate;
            }
        }

        return result;
    }


    @AuraEnabled
    public static String deleteFile(String contentDocumentId) {
        List<ContentVersion> contentVersions = [SELECT Id, Kinetics__External_ID__c 
                                                    FROM ContentVersion 
                                                    WHERE ContentDocumentId =: contentDocumentId LIMIT 1];
                                                
        String result;
        String openaiFileID;
        String contentVersionId;
        if (!contentVersions.isEmpty() && contentVersions[0].Kinetics__External_ID__c != null) {
            openaiFileID = contentVersions[0].Kinetics__External_ID__c;
            contentVersionId = contentVersions[0].Id;
            // String apiKey = 'YOUR_OPENAI_API_KEY';
            String apiKey = '';
            Boolean deleteResult = OpenAIFileService.deleteFile(apiKey, openaiFileID);

            result = deleteResult ? 'success' : 'error';

            if(result == 'success'){
                ContentVersion cvUpdate = new ContentVersion();
                cvUpdate.Id = contentVersionId;
                cvUpdate.Kinetics__External_ID__c = 'deleted-' + openaiFileID;
                cvUpdate.Kinetics__External_System__c = 'ChatGPT';
                update cvUpdate;
            }
        }
        
        return result;
    }
}