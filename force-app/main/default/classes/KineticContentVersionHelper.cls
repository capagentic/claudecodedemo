/**
* Author: Shankar Dupade
* Purpose: Helper class for Content Version trigger to update the File URL on the record when a new version
*          is created eg. 
* Date: 2nd Sept 2021
*/
public with sharing class KineticContentVersionHelper {
    public static void handleAfterInsert(List<ContentVersion> fileRecords) {
        Set<String> fileTypeSet = new Set<String>{'JPEG', 'PNG', 'JPG','GIF','Bitmap'};
        Set<String> fileExtensionsSet = new Set<String>{'jpg', 'png', 'jpg','gif','bmp'};
        Map<Id,Id> contentVersionIdByAnswerRecId = new Map<Id,Id>();
        for(ContentVersion fileRecord : fileRecords) {
            if(String.isNotBlank(fileRecord.Kinetics__Kinetic_Form_Answer__c)
                && (fileTypeSet.contains(fileRecord.FileType)
                || fileExtensionsSet.contains(fileRecord.FileExtension))) {
                contentVersionIdByAnswerRecId.put(fileRecord.Kinetics__Kinetic_Form_Answer__c, fileRecord.Id);
            }
        }

        if(contentVersionIdByAnswerRecId.isEmpty() ) {
            return;
        }else{
            GuestUserHandlerHelper.updateKineticFormAnswers(contentVersionIdByAnswerRecId);
        }
        
        
    }
}