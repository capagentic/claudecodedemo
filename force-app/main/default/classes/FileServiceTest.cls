/**
* Author: Shankar Dupade (Fieldko)
* Updated : 10th Aug 2021
* Purpose: Test Class for creation, read, manipulation, deletion operations of Files
*
*/
@isTest
public with sharing class FileServiceTest {
    
    @testSetup
    static void testSetupData() {
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        Account acc1 = accList[0];
    }
    
    testMethod static void test_deleteAllFiles() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];
        
        List<ContentVersion> fileRecords = new List<ContentVersion>();
        
        ContentVersion fileRecord1 = new ContentVersion();
        fileRecord1.Title = 'Test File 1';
        fileRecord1.VersionData = Blob.valueOf('File Image 1');
        fileRecord1.ContentLocation = 'S';
        fileRecord1.PathOnClient = 'Test.jpg';
        fileRecord1.Origin = 'H';
        fileRecord1.IsMajorVersion = false;

        insert fileRecord1;
		
        fileRecord1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord1.Id];
        fileRecords.add(fileRecord1);
        
        ContentVersion version1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord1.Id];
        ContentDocumentLink documentLink1 = new ContentDocumentLink();
        documentLink1.ContentDocumentId = version1.ContentDocumentId;
        documentLink1.LinkedEntityId = acc.Id;
        documentLink1.ShareType = 'V';
        documentLink1.Visibility = 'AllUsers';
        insert documentLink1;

        ContentVersion fileRecord2 = new ContentVersion();
        fileRecord2.Title = 'Test File 1';
        fileRecord2.VersionData = Blob.valueOf('File Image 1');
        fileRecord2.ContentLocation = 'S';
        fileRecord2.PathOnClient = 'Test.jpg';
        fileRecord2.Origin = 'H';
        fileRecord2.IsMajorVersion = false;

        insert fileRecord2;
		fileRecord2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord2.Id];
        fileRecords.add(fileRecord2);
        
        ContentVersion version2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord2.Id];
        ContentDocumentLink documentLink2 = new ContentDocumentLink();
        documentLink2.ContentDocumentId = version2.ContentDocumentId;
        documentLink2.LinkedEntityId = acc.Id;
        documentLink2.ShareType = 'V';
        documentLink2.Visibility = 'AllUsers';
        insert documentLink2;

        Test.startTest();
            FileService.deleteAllFiles(fileRecords);
        Test.stopTest();
        
        Integer filesCount = [SELECT Count() FROM ContentVersion];
        System.assertEquals(0, filesCount);
    }
    
    testMethod static void test_fetchAllFiles() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];
        
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
            Map<Id,List<ContentVersion>> parentIdVsFileRecords = FileService.fetchAllFiles(new Set<Id> {acc.Id});
        Test.stopTest();
        
        System.assertEquals(2,parentIdVsFileRecords.get(acc.Id).size());
    }
    
    
    testMethod static void test_getAllContentDocumentIds() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];
        
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
            Map<Id,Set<Id>> parentIdVsContentDocumentIds = FileService.getAllContentDocumentIds(new Set<Id> {acc.Id});
        Test.stopTest();
        
        System.assertEquals(2,parentIdVsContentDocumentIds.get(acc.Id).size());
    }

    
    testMethod static void test_upsertNewFile_NewFile() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];

        Test.startTest();
            ContentVersion fileRecord = FileService.upsertNewFile('Test File 1','.pdf','Test File 1',Blob.valueOf('Test File 1'),null,acc.Id);
        Test.stopTest();

        System.assertNotEquals(null,fileRecord);
    }
    
    testMethod static void test_upsertNewFile_ExistingFile() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Account 1'];

        ContentVersion fileRecord = FileService.upsertNewFile('Test File 1','.pdf','Test File 1',Blob.valueOf('Test File 1'),null,acc.Id);
        Id contDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord.Id][0].ContentDocumentId;
                
        Test.startTest();
            ContentVersion newFileRecord = FileService.upsertNewFile('Test File 1','.jpg','Test File 1',Blob.valueOf('Test File 2'),contDocumentId,acc.Id);
        Test.stopTest();
        
        ContentVersion versionRecord = [SELECT Title FROM ContentVersion WHERE IsLatest = true];
        System.assertEquals('Test File 1',versionRecord.Title);
    }

    testMethod static void test_emptyParameters() {
        FileService.deleteAllFiles(new List<ContentVersion>());
        FileService.deleteContentDocuments(new Set<Id>());
        Map<Id,List<ContentVersion>> empty = FileService.fetchAllFiles(new Set<Id>());

        Map<Id,Set<Id>> emptyMap = FileService.getAllContentDocumentIds(new Set<Id>());
        FileService.createLinksToFile(new Map<Id,Set<Id>>());
        System.assertEquals(empty.size(), 0);
        System.assertEquals(emptyMap.size(), 0);
    }
}