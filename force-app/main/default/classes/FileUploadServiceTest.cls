/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for FileUploadService
*/
@isTest
public with sharing class FileUploadServiceTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();

    }
    @isTest
    static void test_saveTheChunkFile() {
        List<Account> accList = [select ID from Account];
        Test.startTest();
            Id parentId = accList[0].Id;
            String surveyAnswerId = null;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            String contentType = 'image/png';
            String fileId = null;
            fileId = FileUploadService.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }

    @isTest
    static void test_saveTheChunkFile_withAppend() {
        List<Account> accList = [select ID from Account];
        Test.startTest();
            Id parentId = accList[0].Id;
            String surveyAnswerId = null;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            String contentType = 'image/png';
            String fileId = null;
            fileId = FileUploadService.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            base64Data = ' some more additions to the data';
            fileId = FileUploadService.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }
}