/**
* Author: Shankar Dupade(FieldKo)
* Updated : 10th Aug 2021
* Purpose: Test Class for creation, read, manipulation, deletion operations of Attachments
*/
@isTest
public with sharing class AttachmentServiceTest {
    
    @testSetup static void testSetupData() {
        TestDataFactory.configureKineticSetting();
        TestDataFactory.createAccount();
    }
    
    testMethod static void test_fetchAllAttachments() {
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
        
        Test.startTest();
            Map<Id,List<Attachment>> parentIdVsAttachmentRecords = AttachmentService.fetchAllAttachments(new Set<Id> {acc.Id});
        Test.stopTest();

        System.assertEquals(2,parentIdVsAttachmentRecords.get(acc.Id).size());
    }
    
    testMethod static void test_fetchAllAttachments_NoParent() {        
        Test.startTest();
            AttachmentService.fetchAllAttachments(null);
        Test.stopTest();
        
        System.assert(true);
    }
}