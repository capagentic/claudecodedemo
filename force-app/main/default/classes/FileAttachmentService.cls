/***
* Author: Shankar Dupade (FieldKo)
* Purpose: Service Class for creation, read, manipulation, deletion operations of Files and Attachments
*
*/
global with sharing class FileAttachmentService {
	/* Purpose - Get all the files and attachments associated to records
       parentIdSet - Pass all the record Ids from which the files and attachments have to be fetched.
                     Returns the Files and Attachments associated to each record 
    */
	global static Map<Id,FileAttachmentWrapper> getFileAttachmentRecords(Set<Id> parentIdSet) {
        Map<Id,FileAttachmentWrapper> recordIdVsFileAttachmentWrapper = new Map<Id,FileAttachmentWrapper>();
        Map<Id,List<ContentVersion>> parentIdVsFileRecords = new Map<Id,List<ContentVersion>>();
        parentIdVsFileRecords = FileService.fetchAllFiles(parentIdSet);

        Map<Id,List<Attachment>> parentIdVsAttachmentRecords = AttachmentService.fetchAllAttachments(parentIdSet);
        for(Id parentId : parentIdSet) {
            if(parentIdVsFileRecords.containsKey(parentId) || parentIdVsAttachmentRecords.containsKey(parentId)) {
                FileAttachmentWrapper wrapper = new FileAttachmentWrapper();
                wrapper.linkedRecordId = parentId;

                if(parentIdVsFileRecords.containsKey(parentId)) {
                    wrapper.contentVersionRecords = parentIdVsFileRecords.get(parentId);
                }

                if(parentIdVsAttachmentRecords.containsKey(parentId)) {
                    wrapper.attachmentRecords = parentIdVsAttachmentRecords.get(parentId);
                }

                recordIdVsFileAttachmentWrapper.put(parentId, wrapper);
            }
        }

        return recordIdVsFileAttachmentWrapper;
    }
}