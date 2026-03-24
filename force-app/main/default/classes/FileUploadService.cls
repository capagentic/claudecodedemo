public with sharing class FileUploadService {
    
    @AuraEnabled                            
    public static Id saveTheChunkFile(Id parentId, String surveyAnswerId, String fileName, String base64Data, String contentType, String fileId){
        
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        if ( String.isBlank(fileId) ) {
            fileId = GuestUserHandlerHelper.saveFiles(parentId, surveyAnswerId, fileName, base64Data );
        } else {
            GuestUserHandlerHelper.appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }
}