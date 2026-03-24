/**
* Author: Shankar Dupade(FieldKo)
* Date: 5th Aug 2021
* Purpose: Utility Class for creation, read, manipulation, deletion operations of Attachments
*
*/
global with sharing class AttachmentService {
	static List<Schema.DescribeFieldResult> attachmentFieldList = new List<Schema.DescribeFieldResult> {
        Attachment.Description.getDescribe(),
        Attachment.ParentId.getDescribe(),
        Attachment.Body.getDescribe(),
        Attachment.ContentType.getDescribe()                                                                                    
    };
    
    global static Map<Id,List<Attachment>> fetchAllAttachments(Set<Id> parentIds) {
        Map<Id,List<Attachment>> parentIdVsAttachments = new Map<Id,List<Attachment>>();

        if(parentIds == null || parentIds.isEmpty()) {
            return parentIdVsAttachments;
        }
        
        if(isAttachmentReadAllowed()) {
            for(Attachment attach : [SELECT Id, ParentId, Name, IsPrivate, BodyLength, LastModifiedDate, ContentType, Description FROM Attachment 
                                        WHERE ParentId IN :parentIds]) {
                if(parentIdVsAttachments.containsKey(attach.ParentId)) {
                    parentIdVsAttachments.get(attach.ParentId).add(attach);
                } else {
                    parentIdVsAttachments.put(attach.ParentId, new List<Attachment> { attach });
                }
            }
        }
        
        return parentIdVsAttachments;
    }
     /* Purpose - Check if attachment Fetch is allowed to a user */
     global static Boolean isAttachmentReadAllowed() {
        Boolean isAllowed = false;
        if(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Attachment) && CheckUserPermission.checkFieldsReadAccess(attachmentFieldList)) {
            isAllowed = true;
        }
        return isAllowed;
    }
}