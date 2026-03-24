/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public with sharing class CheckUserPermissionTest {

    static testMethod void myUnitTest() {
        Schema.DescribeSObjectResult drSObj = Schema.sObjectType.Account;
        
        Boolean objectDeleteResult = CheckUserPermission.checkObjectDeleteAccess(drSObj);
        System.assert(objectDeleteResult);
        
        Boolean objectCreateResult = CheckUserPermission.checkObjectCreateAccess(drSObj);
        System.assert(objectCreateResult);
        
        Boolean objectReadResult = CheckUserPermission.checkObjectReadAccess(drSObj);
        System.assert(objectReadResult);
        
        Boolean objectUpdateResult = CheckUserPermission.checkObjectUpdateAccess(drSObj);
          System.assert(objectUpdateResult);
        
        //Check Field Level access
        Schema.DescribeFieldResult drField = Account.Industry.getDescribe();
        List<Schema.DescribeFieldResult> fieldList = new List<Schema.DescribeFieldResult>{
                               Account.Name.getDescribe(),
                                Account.AccountNumber.getDescribe(),
                                Account.ParentId.getDescribe()};
        
        Boolean fieldsReadResult = CheckUserPermission.checkFieldsReadAccess(fieldList);
        ////system.debug('The result for Account fields read permission***********************'+fieldsReadResult);
        
        Boolean fieldsCreateResult = CheckUserPermission.checkFieldsCreateAccess(fieldList);
        ////system.debug('The result for Account fields read permission***********************'+fieldsReadResult);
        
        Boolean fieldsUpdateResult = CheckUserPermission.checkFieldsUpdateAccess(fieldList);
        ////system.debug('The result for Account fields read permission***********************'+fieldsReadResult);
        fieldList.clear();
        
        fieldsReadResult = CheckUserPermission.checkFieldsReadAccess(null);
        fieldsCreateResult = CheckUserPermission.checkFieldsCreateAccess(null);
        fieldsUpdateResult = CheckUserPermission.checkFieldsUpdateAccess(null);
        
        
        
        objectDeleteResult = CheckUserPermission.checkObjectDeleteAccess(null);
        objectCreateResult = CheckUserPermission.checkObjectCreateAccess(null);        
        objectReadResult = CheckUserPermission.checkObjectReadAccess(null);
        objectUpdateResult = CheckUserPermission.checkObjectUpdateAccess(null);
    }
}