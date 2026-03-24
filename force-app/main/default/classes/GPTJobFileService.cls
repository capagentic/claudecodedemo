public with sharing class GPTJobFileService {
    public static String createAndAttachFile(String jobId, String prompt) {
        // Create a new ContentVersion record (i.e., the file)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'ChatGPT_Prompt_' + jobID;
        cv.PathOnClient = 'Prompt_' + jobID +  '.txt'; // It includes the file extension. In this case '.txt' for a text file
        cv.VersionData = Blob.valueOf(prompt); // File content
        cv.IsMajorVersion = true;
        insert cv;
        
        // After inserting the ContentVersion, a ContentDocument record is automatically created.
        // To link the ContentDocument to an Account, create a ContentDocumentLink record.
        
        // Get the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create a ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = jobId; // ID of the GPT Job
        cdl.ShareType = 'V'; // 'V' means users can view but not edit the shared file.
        insert cdl;

        return cdl.Id;
    }

    public static String getFileContent(String jobId) {

        // Query the ContentDocumentLink
        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :jobId];
        System.debug('******** cdls=' + cdls);
        // Check if a file is found
        if (!cdls.isEmpty()) {
            // Get the ContentVersion
            ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :cdls[0].ContentDocumentId AND IsLatest = true LIMIT 1];
            System.debug('******** cv=' + cv);
            // Convert the Blob data to a String and return it
            return cv.VersionData.toString();
        } else {
            System.debug('******** No file found for this Account.');
            return null;
        }
    } 


}