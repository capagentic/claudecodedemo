/**
* Author: Shankar Dupade(FieldKo.com)
* Updated : 9th Aug 2021
* Purpose: Test Class for creation, read, manipulation, deletion operations of Files and Attachments
*/

@isTest
public with sharing class FileAttachmentServiceTest {

    @testSetup
	static void testSetupData() {
        TestDataFactory.configureKineticSetting();
		TestDataFactory.createAccount();
	}

	testMethod static void test_getFileAttachmentRecords() {
		Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];
		
		List<Attachment> attachmentList = new List<Attachment>();
		Attachment attach1 = new Attachment();
		attach1.Name = 'Attachment 1';
		attach1.ParentId = acc.Id;
		attach1.Body = Blob.valueOf('Attachment Image 1');
		attachmentList.add(attach1);

		Attachment attach2 = new Attachment();
		attach2.Name = 'Attachment 2';
		attach2.ParentId = acc.Id;
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
		documentLink1.LinkedEntityId = acc.Id;
		documentLink1.ShareType = 'V';
		documentLink1.Visibility = 'AllUsers';
		insert documentLink1;

		ContentVersion fileRecord2 = new ContentVersion();
		fileRecord2.Title = 'Test File 2';
		fileRecord2.VersionData = Blob.valueOf('File Image 2');
		fileRecord2.ContentLocation = 'S';
		fileRecord2.PathOnClient = 'Test.jpg';
		fileRecord2.Origin = 'H';
		fileRecord2.IsMajorVersion = false;

		insert fileRecord2;

		ContentVersion version2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord2.Id];
		ContentDocumentLink documentLink2 = new ContentDocumentLink();
		documentLink2.ContentDocumentId = version2.ContentDocumentId;
		documentLink2.LinkedEntityId = acc.Id;
		documentLink2.ShareType = 'V';
		documentLink2.Visibility = 'AllUsers';
		insert documentLink2;

		Test.startTest();
        	Map<Id,FileAttachmentWrapper> fileAttachWrapper = FileAttachmentService.getFileAttachmentRecords(new Set<Id> {acc.Id});
        Test.stopTest();

        System.assertEquals(2,fileAttachWrapper.get(acc.Id).attachmentRecords.size());
        System.assertEquals(2,fileAttachWrapper.get(acc.Id).contentVersionRecords.size());
	}
}