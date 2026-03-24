/**
* Author: Shankar Dupade (FieldKo)
* Date: 5th Aug 2021
* Purpose: Utility Class for creation, read, manipulation, deletion operations of Files
*
*/
global with sharing class FileService {
    
    /* Purpose - Delete all the files associated to records
       contentVersionRecords - Pass all the files which have to deleted 
    */
    global static void deleteAllFiles(List<ContentVersion> contentVersionRecords) {
        Set<Id> contentDocumentIds = new Set<Id>();
        if(contentVersionRecords == null || contentVersionRecords.isEmpty()) {
            return;
        }

        for(ContentVersion version : contentVersionRecords) {
            contentDocumentIds.add(version.ContentDocumentId);
        }

        deleteContentDocuments(contentDocumentIds);
    }

    /* Purpose - Delete all the ContentDocuments
       contentDocumentIds - Content Document IDs which have to deleted 
    */
    global static void deleteContentDocuments(Set<Id> contentDocumentIds) {
        List<ContentDocument> filesToDelete = new List<ContentDocument>();

        if(contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return;
        }
        for(Id documentId : contentDocumentIds) {
            ContentDocument documentObj = new ContentDocument(Id = documentId);
            filesToDelete.add(documentObj);
        }

        System.debug('Files to delete:'+filesToDelete);
        delete filesToDelete;
    }

    /* Purpose - Get all the files associated to records
       parentIds - Record Ids from which the files have to be fetched.
                   Returns the files associated to each record 
    */
    global static Map<Id,List<ContentVersion>> fetchAllFiles(Set<Id> parentIds) {
        Map<Id,List<ContentVersion>> linkedIdVsFiles = new Map<Id,List<ContentVersion>>();
        Map<Id,Set<Id>> linkedIdVsContentDocumentIds = new Map<Id,Set<Id>>();
        Map<Id,ContentVersion> contentDocumentIdVsContentVersion = new Map<Id,ContentVersion>();
        Set<Id> contentDocumentIdSet = new Set<Id>();

        if(parentIds == null || parentIds.isEmpty()) {
            return linkedIdVsFiles;
        }
        
        linkedIdVsContentDocumentIds = getAllContentDocumentIds(parentIds);

        for(Id linkedId : linkedIdVsContentDocumentIds.keySet()) {
            contentDocumentIdSet.addAll(linkedIdVsContentDocumentIds.get(linkedId));
        }

        for(ContentVersion contVersion : [SELECT Id, Title, FileType, ContentLocation, ContentSize, FileExtension, ContentDocumentId,
                                            PathOnClient, Origin, LastModifiedDate FROM ContentVersion 
                                            WHERE ContentDocumentId IN :contentDocumentIdSet AND IsLatest = true]) {
            contentDocumentIdVsContentVersion.put(contVersion.ContentDocumentId,contVersion);               
        }

        for(Id parentId : linkedIdVsContentDocumentIds.keySet()) {
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            for(Id contentDocId : linkedIdVsContentDocumentIds.get(parentId)) {
                contentVersionList.add(contentDocumentIdVsContentVersion.get(contentDocId));
            }
            linkedIdVsFiles.put(parentId,contentVersionList);
        }

        return linkedIdVsFiles;
    }

    /* Purpose - Get all the Content Document Ids associated to records
       linkedEntityIds - Record Ids from which the Content Document IDs have to be fetched.
       Returns - All the content Document IDs associated to each record 
    */
    global static Map<Id,Set<Id>> getAllContentDocumentIds(Set<Id> linkedEntityIds) {
        Map<Id,Set<Id>> linkedIdVsContentDocumentIds = new Map<Id,Set<Id>>();

        if(linkedEntityIds == null || linkedEntityIds.isEmpty()) {
            return linkedIdVsContentDocumentIds;
        }

        for(ContentDocumentLink docLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds]) {
            if(linkedIdVsContentDocumentIds.containsKey(docLink.LinkedEntityId)) {
                linkedIdVsContentDocumentIds.get(docLink.LinkedEntityId).add(docLink.ContentDocumentId);
            } else {
                linkedIdVsContentDocumentIds.put(docLink.LinkedEntityId, new Set<Id> { docLink.ContentDocumentId });
            }
        }

        return linkedIdVsContentDocumentIds;
    }


    /* Purpose - Links all the files to records
       linkedIdVsContentDocumentIds - Pass the map of content Document IDs associated to each record ID.
    */
    global static void createLinksToFile(Map<Id,Set<Id>> linkedIdVsContentDocumentIds) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Map<Id,Set<Id>> recordIdVsExistingContentDocumentIds = new Map<Id,Set<Id>>();

        if(linkedIdVsContentDocumentIds == null || linkedIdVsContentDocumentIds.isEmpty()) {
            return;
        }
        
        List<Id> linkedEntityIds = new List<Id>(linkedIdVsContentDocumentIds.keySet());
        //Get all ContentDocumentLinks for Record. This check is necessary as duplicate link creation is not allowed for file else gives exception.
        for(ContentDocumentLink link : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds]) {
            if(recordIdVsExistingContentDocumentIds.containsKey(link.LinkedEntityId)) {
                recordIdVsExistingContentDocumentIds.get(link.LinkedEntityId).add(link.ContentDocumentId);
            } else {
                recordIdVsExistingContentDocumentIds.put(link.LinkedEntityId,new Set<Id> { link.ContentDocumentId});
            }
        }
        System.debug('Existing Content Document Ids:'+recordIdVsExistingContentDocumentIds);
        for(Id linkedRecordId : linkedEntityIds) {
            Set<Id> existingContentDocumentIds = new Set<Id>();
            if(recordIdVsExistingContentDocumentIds.containsKey(linkedRecordId)) {
                existingContentDocumentIds = recordIdVsExistingContentDocumentIds.get(linkedRecordId);
            }
            Set<Id> contentDocumentIds = linkedIdVsContentDocumentIds.get(linkedRecordId);
            for(Id documentId : contentDocumentIds) {
                if(!existingContentDocumentIds.contains(documentId)) {
                    ContentDocumentLink contentVersionLinkObj = new ContentDocumentLink();
                    contentVersionLinkObj.ContentDocumentId = documentId;
                    contentVersionLinkObj.LinkedEntityId = linkedRecordId;
                    contentVersionLinkObj.ShareType = 'V';
                    contentVersionLinkObj.Visibility = 'AllUsers';
                    contentDocumentLinks.add(contentVersionLinkObj);
                }
            }            
        }

        if(!contentDocumentLinks.isEmpty()) {
            System.debug('Linked to be Created:'+contentDocumentLinks);
            insert contentDocumentLinks;
        }
    }

    /* Purpose - Links all the files to records
       Parameters - title - Name of File.
                    fileExtension - File Extension used by file to determine the type of file if file is Enabled. eg. PDF,JPG,etc.
                    name - Name for the File used by PathOnClient if file is enabled.
                    body - File Body.
                    linkedRecordId - Record Id with which file has to be linked.
       Return - File Object containing file Id
    */
    global static ContentVersion upsertNewFile(String title, String fileExtension, String name, Blob body, Id documentId, Id linkedRecordId) {
        ContentVersion fileRecord = new ContentVersion();

        //If File record does not exist for the record, create  a new file
        if(documentId == null) {
            fileRecord.Title = title;
            fileRecord.VersionData = body;
            fileRecord.ContentLocation = 'S';
            fileRecord.PathOnClient = name;
            fileRecord.Origin = 'H';

            insert fileRecord;

            ContentVersion versionObj = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord.Id];
            Map<Id,Set<Id>> linkedIdVsContentDocumentIds = new Map<Id,Set<Id>>();
            linkedIdVsContentDocumentIds.put(linkedRecordId, new Set<Id> { versionObj.ContentDocumentId });
            createLinksToFile(linkedIdVsContentDocumentIds);
        } else {
            //If File record already exists for the record, create  a new version of file
            fileRecord.Title = title;
            fileRecord.VersionData = body;
            fileRecord.ContentLocation = 'S';
            fileRecord.PathOnClient = name;
            fileRecord.Origin = 'H';
            fileRecord.ContentDocumentId = documentId;

            insert fileRecord;
        }

        return new ContentVersion(Id = fileRecord.Id);
    }
}