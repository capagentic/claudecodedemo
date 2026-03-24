@isTest
private class CustomLookupLwcControllerTest {

    @isTest
    static void testFetchLookupData() {

        Test.startTest();
        List<sObject> result = CustomLookupLwcController.fetchLookupData('DummyAccount', 'Account');
        Test.stopTest();
    }

    @isTest
    static void testFetchDefaultRecord() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'DummyAccount'];
        Test.startTest();
        sObject result = CustomLookupLwcController.fetchDefaultRecord(acct.Id, 'Account');
        Test.stopTest();
    }
    
    @isTest
    static void testFetchLookupDataForFlowObj() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'DummyAccount'];
        Test.startTest();
        CustomLookupLwcController.fetchLookupDataForFlowObj(acct.Id, 'Account');
        Test.stopTest();
    }

    @testSetup static void createTestData() {
        Account account = new Account();
        account.Name = 'DummyAccount';
        insert account;
    }
}