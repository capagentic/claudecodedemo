/**
* Author: Shankar Dupade(FieldKo)
* Updated : 10th Aug 2021
* Purpose: Test Class for creation, read, manipulation, deletion operations of Attachments and file wrapper
*/
@isTest
public with sharing class FileAttachmentWrapperTest {
    @testSetup static void testSetupData() {
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        Account acc1 = accList[0];

        List<Attachment> attachmentList = new List<Attachment>();
        Attachment attach1 = new Attachment();
        attach1.Name = 'Attachment 1';
        attach1.ParentId = acc1.Id;
        attach1.Body = Blob.valueOf('Attachment Image 1');
        attachmentList.add(attach1);

        Attachment attach2 = new Attachment();
        attach2.Name = 'Attachment 2';
        attach2.ParentId = acc1.Id;
        attach2.Body = Blob.valueOf('Attachment Image 2');
        attachmentList.add(attach2);

        insert attachmentList;

        List<ContentVersion> fileList = new List<ContentVersion>();
		ContentVersion fileRecord1 = new ContentVersion();
		fileRecord1.Title = 'Test File 1';
		fileRecord1.VersionData = Blob.valueOf('File Image 1');
		fileRecord1.ContentLocation = 'S';
		fileRecord1.PathOnClient = 'Test.jpg';
		fileRecord1.Origin = 'H';
		fileRecord1.IsMajorVersion = false;

		insert fileRecord1;
        ContentVersion version1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord1.Id];
		ContentDocumentLink documentLink1 = new ContentDocumentLink();
		documentLink1.ContentDocumentId = version1.ContentDocumentId;
		documentLink1.LinkedEntityId = acc1.Id;
		documentLink1.ShareType = 'V';
		documentLink1.Visibility = 'AllUsers';
		insert documentLink1;
    }

    @IsTest
    static void test_FileAttachmentWrapperContructor(){
        
        Test.startTest();
            FileAttachmentWrapper  fw = new FileAttachmentWrapper();
            Account acc = [select Id from Account limit 1];
            List<ContentVersion> contentVersionRecords = [select Id from ContentVersion];
            List<Attachment> attachmentRecords = [select Id from Attachment];
            FileAttachmentWrapper  fwparameter = new FileAttachmentWrapper(acc.Id, contentVersionRecords, attachmentRecords);
            System.assert(fwparameter != null);
        Test.stopTest();
        
    }
}