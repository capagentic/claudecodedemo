/**
 * Author: Shankar Dupade
 * Purpose: Controller class for inspection pdf report 
 * Date: 22-09-2022
 */
public with sharing class inspPDFReportController {
    transient private final Integer PDF_SIZE_LIMIT = 22 * 1024 * 1024;

    public Kinetics__Inspection__c inspectionRec{get;set;}
    public List<sectionDetailsWrapper> sectionDetailsWrapperList{get;set;}
    public Map<String, List<filesWrapper>> fileWrapperListByAnswerId{get;set;}
    public List<Task> relatedTaskList{get;set;}
    public List<ContentNote> contentNoteList{get;set;}
    public List<contentNoteWrapper> contentNoteWrapperList {get;set;}
    public List<Kinetics__Kinetic_Form_Answer__c> answerRecordList {get;set;}
    public String logoId {get;set;}

    public inspPDFReportController(ApexPages.StandardController controller)  {
        sectionDetailsWrapperList = new List<sectionDetailsWrapper> ();
        fileWrapperListByAnswerId = new Map<String, List<filesWrapper>>();
        relatedTaskList = new List<Task>();
        contentNoteList = new List<ContentNote>();
        contentNoteWrapperList = new List<contentNoteWrapper>();
        answerRecordList = new List<Kinetics__Kinetic_Form_Answer__c>();

        initialize();
    }
    private void initialize() {    
        Id inspectionRecId = apexpages.currentpage().getparameters().get('id');
        List<Kinetics__Inspection__c> inspectionList = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Account__r.Name, Kinetics__Contact__c, Kinetics__Contact__r.Name,
                        Kinetics__Inspection_Date__c, Kinetics__Status__c, Kinetics__Template__c, Kinetics__Template__r.Name, Kinetics__Template__r.Kinetics__Section_Metadata__c, 
                        Kinetics__Template__r.Kinetics__Questions_By_Page_No__c,
                        Kinetics__Score__c, Kinetics__Percentage_Score__c 
                        FROM Kinetics__Inspection__c 
                        WHERE Id = :inspectionRecId];

        if(inspectionList.size() == 0) {
            return ;
        }
        inspectionRec = inspectionList[0];

        Map<Integer, sectionMetadataWrapper> sectionMetadataByNumber = new Map<Integer, sectionMetadataWrapper>();
        if(String.isNotBlank(inspectionRec.Kinetics__Template__r.Kinetics__Section_Metadata__c)){
            sectionMetadataByNumber = (Map<Integer, sectionMetadataWrapper>) JSON.deserialize(inspectionRec.Kinetics__Template__r.Kinetics__Section_Metadata__c, Map<Integer, sectionMetadataWrapper>.class);
        }
        Map<Integer, Integer> sectionNumberByQuestionIndex = new Map<Integer, Integer>();
        for(Integer sectionNum: sectionMetadataByNumber.keySet()) {
            sectionMetadataWrapper secwrapperObj = sectionMetadataByNumber.get(sectionNum);
            for(Integer questIndex: secwrapperObj.questIndex) {
                sectionNumberByQuestionIndex.put(questIndex, sectionNum);
            }
        }
        Map<Integer, sectionDetailsWrapper> sectionWrapperBySectionNumber = new Map<Integer, sectionDetailsWrapper>();
        Map<Integer, Double> totalObtainedScoreBySectionNumber = new Map<Integer, Double>();
        Map<Integer, Double> totalScoreBySectionNumber = new Map<Integer, Double>();
        String query = 'SELECT ';
        
        query += ' Id, Kinetics__Answer__c, Kinetics__Answer_Index__c, Kinetics__Kinetic_Question__c,';
        query += ' Kinetics__Score_Attained__c, Kinetics__Out_of_Score__c, Kinetics__Type__c, Kinetics__Picture__c,';
        query += ' Kinetics__Score__c, Kinetics__Show_More_Information__c, ';
        query += ' Kinetics__Kinetic_Form_Question__r.Kinetics__Option_Score__c';
        
        for(Schema.FieldSetMember f : this.getAnswerExtraFields()) {
            if(!query.containsIgnoreCase((', '+f.getFieldPath()))) {
                query += ', ' + f.getFieldPath();
            }
        }

        query += ' FROM Kinetics__Kinetic_Form_Answer__c';
        query += ' WHERE Kinetics__Inspection__c = :inspectionRecId';
        query += ' order by Kinetics__Answer_Index__c asc';
    
        List<Kinetics__Kinetic_Form_Answer__c> kformAnswersRecList = Database.query(query);
        for(Kinetics__Kinetic_Form_Answer__c kformAnswersRec : kformAnswersRecList) {
            Integer sectionNumber = -1; 
            Integer questionIndex = (Integer) kformAnswersRec.Kinetics__Answer_Index__c;
            if(sectionNumberByQuestionIndex.containsKey(questionIndex)){
                sectionNumber = sectionNumberByQuestionIndex.get(questionIndex);
            }
            sectionDetailsWrapper sectionDetailsObj = new sectionDetailsWrapper();
            if(sectionWrapperBySectionNumber.containsKey(sectionNumber)) {
                sectionDetailsObj = sectionWrapperBySectionNumber.get(sectionNumber);
            }
            if(sectionMetadataByNumber.containskey(sectionNumber)){
                sectionDetailsObj.sectionName = sectionMetadataByNumber.get(sectionNumber).title;
            }
            sectionDetailsObj.kformAnswersList.add(kformAnswersRec);
            answerRecordList.add(kformAnswersRec);

            //calculate score:
            Double totalObtainedScoreForAnswer = kformAnswersRec.Kinetics__Score_Attained__c == null ? 0 : kformAnswersRec.Kinetics__Score_Attained__c;
            if(totalObtainedScoreBySectionNumber.containsKey(sectionNumber)) {
                totalObtainedScoreForAnswer = totalObtainedScoreForAnswer + totalObtainedScoreBySectionNumber.get(sectionNumber);
            }
            totalObtainedScoreBySectionNumber.put(sectionNumber, totalObtainedScoreForAnswer);
            Double maxScoreForQuestion = 0;
            Map<String, Integer> scoreByOption = new Map<String, Integer>();
            if(String.isNotBlank(kformAnswersRec.Kinetics__Kinetic_Form_Question__r.Kinetics__Option_Score__c)) {
                scoreByOption = (Map<String, Integer>) JSON.deserialize(kformAnswersRec.Kinetics__Kinetic_Form_Question__r.Kinetics__Option_Score__c, Map<String, Integer>.class);
            }
            for(String optionVal : scoreByOption.keySet()) {
                if(maxScoreForQuestion < scoreByOption.get(optionVal)) {
                    maxScoreForQuestion = scoreByOption.get(optionVal);
                }
            }
            if(totalScoreBySectionNumber.containsKey(sectionNumber)) {
                maxScoreForQuestion = maxScoreForQuestion + totalScoreBySectionNumber.get(sectionNumber);
            }
            totalScoreBySectionNumber.put(sectionNumber, maxScoreForQuestion);
            sectionDetailsObj.scoreDetails = '';
            if(totalScoreBySectionNumber.get(sectionNumber) != 0 && totalScoreBySectionNumber.get(sectionNumber) != 0) {
                sectionDetailsObj.scoreDetails = 'Score ' + Math.abs(totalObtainedScoreBySectionNumber.get(sectionNumber).intValue()) + '/' + Math.abs(totalScoreBySectionNumber.get(sectionNumber).intValue()) + ' (' + Math.abs((totalObtainedScoreBySectionNumber.get(sectionNumber)/totalScoreBySectionNumber.get(sectionNumber)) * 100).intValue() + '%)' ;
            }
            sectionWrapperBySectionNumber.put(sectionNumber, sectionDetailsObj);
        }
        sectionDetailsWrapperList = sectionWrapperBySectionNumber.values();
        
        
        String pdfFileName = inspectionRec.Kinetics__Template__r.Name;
        if(inspectionRec.Kinetics__Inspection_Date__c != null) {
            pdfFileName = pdfFileName + '_' + inspectionRec.Kinetics__Inspection_Date__c;
        }
        pdfFileName = pdfFileName + '_Inspection_Report'+'.pdf';
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + pdfFileName );

        populateFilesDetails(kformAnswersRecList);
        collectRelatedTasksAssigned(inspectionRec);
        collectRelatedNotes(inspectionRec);

        String logoDocumentId = GlobalUtility.getLogoDocumentId();
        if(logoDocumentId != null) {
            List<Document> docList = [SELECT Id FROM Document WHERE DeveloperName =: logoDocumentId];
            if(docList.size() > 0) {
                logoId = docList.get(0).Id;
            }
        }
    }

    public List<Schema.FieldSetMember> getAnswerExtraFields() {
        return SObjectType.Kinetics__Kinetic_Form_Answer__c.FieldSets.Kinetics__Extra_Fields_To_Show_In_PDF_Answer_Table.getFields();
    }

    private void collectRelatedNotes(Kinetics__Inspection__c inspectionRec) {
        List<String> contentDocumentIdList = new List<String>();
        contentNoteList = new List<ContentNote>();
        contentNoteWrapperList = new List<contentNoteWrapper>();

        for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                                        FROM ContentDocumentLink 
                                        WHERE LinkedEntityId = :inspectionRec.Id]){
            contentDocumentIdList.add(cdl.contentDocumentId);
        }
        
        contentNoteList = [SELECT Id, Title, TextPreview,CreatedById,CreatedBy.Name, Content FROM ContentNote WHERE Id IN :contentDocumentIdList];
        for(ContentNote cn: contentNoteList) {
            contentNoteWrapper cnwr = new contentNoteWrapper();
            cnwr.title = cn.Title;
            cnwr.createdByUser = cn.CreatedBy.Name;
            cnwr.contentToDisplay = EncodingUtil.base64Decode(EncodingUtil.base64Encode(cn.Content)).toString().replace('<br>', '\r\n');
            contentNoteWrapperList.add(cnwr);
        }
    }
    
    private void collectRelatedTasksAssigned(Kinetics__Inspection__c inspectionRec) {
        relatedTaskList = new List<Task>();
        relatedTaskList = [SELECT Id, OwnerId, Owner.Name, ActivityDate, WhoId, Who.Name, 
                            Priority, WhatId, What.Name, Status, Subject, 
                            Type, Description
                            FROM Task 
                            WHERE WhatId = :inspectionRec.Id 
                            ORDER BY ActivityDate ASC];
    }

    private void populateFilesDetails(List<Kinetics__Kinetic_Form_Answer__c> allAnswers) {
        fileWrapperListByAnswerId = new Map<String, List<filesWrapper>>();
         
        Set<Id> kiAnswerIds = new Set<Id>();
        for(Kinetics__Kinetic_Form_Answer__c isAnswer : allAnswers) {
            kiAnswerIds.add(isAnswer.Id);
        }
        Map<Id,Attachment> answerImagesMap = new Map<Id, Attachment>();
        Map<Id,ContentVersion> answerImageFilesMap = new Map<Id, ContentVersion>();
        Map<Id,FileAttachmentWrapper> fileAttachWrapperList = FileAttachmentService.getFileAttachmentRecords(kiAnswerIds);

        Set<String> extensions = new Set<String> {'PNG','JPEG','JPG'};
        for(Id answerId : fileAttachWrapperList.keySet()) {
            FileAttachmentWrapper fileAttachWrapper = fileAttachWrapperList.get(answerId);
            if(fileAttachWrapper != null) {
                if(fileAttachWrapper.contentVersionRecords != null) {
                    for(ContentVersion fileRecord : fileAttachWrapper.contentVersionRecords) {
                        if(extensions.contains(fileRecord.FileType)) {
                            answerImageFilesMap.put(answerId, fileRecord);
                            continue;
                        }
                    }
                }
                // if(fileAttachWrapper.attachmentRecords != null) {
                //     for(Attachment attach : fileAttachWrapper.attachmentRecords) {
                //         if(attach.ContentType.contains('image')) {
                //             answerImagesMap.put(answerId, attach);
                //             continue;
                //         }
                //     }
                // }
            }
        }
        fileAttachWrapperList = null;

        Integer assignedImageSize = 0;
        for(Kinetics__Kinetic_Form_Answer__c isAnswer : allAnswers) {
            List<filesWrapper> fswrapperList = new List<filesWrapper>();
            if(fileWrapperListByAnswerId.containsKey(isAnswer.Id)) {
                fswrapperList = fileWrapperListByAnswerId.get(isAnswer.Id);
            }
            if(assignedImageSize < PDF_SIZE_LIMIT) {
                filesWrapper fwrapperObj = new filesWrapper();
                if(answerImageFilesMap.containsKey(isAnswer.Id)) {
                    ContentVersion fileRec = answerImageFilesMap.get(isAnswer.Id);
                    fwrapperObj.fileId = fileRec.Id;
                    fwrapperObj.questionIndex = isAnswer.Kinetics__Answer_Index__c + '';
                    fwrapperObj.questionDetails = isAnswer.Kinetics__Kinetic_Question__c;
                    fwrapperObj.fileTitle = fileRec.Title;
                    fwrapperObj.displayURL = '/sfc/servlet.shepherd/version/download/'+fileRec.Id;
                    assignedImageSize += fileRec.ContentSize;
                    
                    fswrapperList.add(fwrapperObj);
                    fileWrapperListByAnswerId.put(isAnswer.Id, fswrapperList);
                }
            }
        }
    }

    public Double offset{ get {
        TimeZone tz = UserInfo.getTimeZone();
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}

    @AuraEnabled
    public static String savePDF(String inspecRecId){
        PageReference pdfPage = new PageReference('/apex/inspPDFReport');
		pdfPage.getParameters().put('id', inspecRecId);
        Blob pdfContent = null;
        if(Test.isRunningTest()) {
            pdfContent = Blob.valueOf('Test method running');
        } else {
            pdfContent = pdfPage.getContent();
        }
        Kinetics__Inspection__c inspectionRec = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Account__r.Name, Kinetics__Contact__c, Kinetics__Contact__r.Name,
                        Kinetics__Inspection_Date__c, Kinetics__Status__c, Kinetics__Template__c, Kinetics__Template__r.Name, Kinetics__Score__c, 
                        Kinetics__Percentage_Score__c 
                        FROM Kinetics__Inspection__c 
                        WHERE Id = :inspecRecId];
        String fileName = inspectionRec.Kinetics__Template__r.Name;
        if(inspectionRec.Kinetics__Inspection_Date__c != null) {
            fileName = fileName + '_' + inspectionRec.Kinetics__Inspection_Date__c;
        }
        fileName = fileName + '_Inspection_Report'+'.pdf';

        List<Schema.DescribeFieldResult> contentversionFieldList = new List<Schema.DescribeFieldResult>{
            ContentVersion.Title.getDescribe(),
            ContentVersion.VersionData.getDescribe(),
            ContentVersion.PathOnClient.getDescribe(),
            ContentVersion.IsMajorVersion.getDescribe(),
            ContentVersion.Description.getDescribe()
        };

        List<Schema.DescribeFieldResult> contentDocumentLinkFieldList = new List<Schema.DescribeFieldResult>{
            ContentDocumentLink.ContentDocumentId.getDescribe(),
            ContentDocumentLink.LinkedEntityId.getDescribe(),
            ContentDocumentLink.ShareType.getDescribe(),
            ContentDocumentLink.Visibility.getDescribe()
        };
        
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.ContentVersion)
            && CheckUserPermission.checkFieldsCreateAccess(contentversionFieldList)
            && CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.ContentDocumentLink)
            && CheckUserPermission.checkFieldsCreateAccess(contentDocumentLinkFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);  
        }

        List<ContentDocumentLink> existingContentList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :inspecRecId];
        List<String> contentDocumentIdList = new List<String>();
        for(ContentDocumentLink cdl: existingContentList){
            contentDocumentIdList.add(cdl.ContentDocumentId);
        }
        List<ContentVersion> contentVersionList = [SELECT Id, VersionData
                                                    FROM ContentVersion
                                                    WHERE ContentDocumentId = :contentDocumentIdList 
                                                    AND Title = :fileName];
        ContentVersion contentToInsert =new ContentVersion(); 
        if(contentVersionList.size() > 0) {
            contentToInsert.Id = contentVersionList[0].Id;
            contentToInsert.VersionData=pdfContent;
        } else {
            contentToInsert.Title = fileName; 
            contentToInsert.VersionData=pdfContent;
            contentToInsert.PathOnClient='/' + fileName ;
            contentToInsert.IsMajorVersion = false;
        }
        upsert contentToInsert;

        if(contentVersionList.size() == 0) {
            contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
            ContentDocumentLink cl = new ContentDocumentLink();
            cl.ContentDocumentId = contentToInsert.ContentDocumentId;
            cl.LinkedEntityId = inspecRecId;
            cl.ShareType = 'V';
            cl.Visibility = 'AllUsers';
            insert cl;
        }

        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        String URlDownload = baseURL+'/sfc/servlet.shepherd/version/download/'+contentToInsert.id;
        system.debug('Download URL:' +URlDownload);
        return URlDownload;
    }

    public class filesWrapper {
        @AuraEnabled
        public String fileId{get;set;}
        @AuraEnabled
        public String questionIndex{get;set;}
        @AuraEnabled
        public String questionDetails{get;set;}
        @AuraEnabled
        public String fileTitle{get;set;}
        @AuraEnabled
        public String displayURL {get;set;}
        
    }
    public class sectionDetailsWrapper {
        @AuraEnabled
        public String sectionName{get;set;}
        @AuraEnabled
        public List<Kinetics__Kinetic_Form_Answer__c> kformAnswersList {get;set;}
        @AuraEnabled
        public String scoreDetails{get;set;}
        sectionDetailsWrapper() {
            sectionName = 'Template Responses';
            kformAnswersList = new List<Kinetics__Kinetic_Form_Answer__c>();
            scoreDetails = '';
        }
    }

    public class sectionMetadataWrapper {
        public String title{get;set;}
        public List<Integer> questIndex {get;set;}
    }
    public class contentNoteWrapper {
        public String title{get;set;}
        public String createdByUser{get;set;}
        public String contentToDisplay{get;set;}
    }
}