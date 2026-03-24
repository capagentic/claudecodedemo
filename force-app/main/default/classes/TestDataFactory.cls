/**
* Author: Shankar Dupade(FieldKo)
* Updated : 10th Aug 2021
* Purpose: Data Factory Class for creating records as required by other test classes
*/
@isTest
public with sharing class TestDataFactory {
    
    public static void configureKineticSetting() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        Boolean doUpsert = false;
        if(String.isEmpty(setting.Kinetics__Google_API_Key__c)){
            setting.Kinetics__Google_API_Key__c = 'AIzaSyCbnOizzEzsLdOnmMoMjZmu-rTBkeYyNDE';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__SMS_Template__c)){
            setting.Kinetics__SMS_Template__c = 'Please click the following link to start your survey: {{pageUrl}}';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__Form_Renderer_Page_URL__c)){
            setting.Kinetics__Form_Renderer_Page_URL__c = 'https://kinetics-dev-developer-edition.ap24.force.com/s/sq';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__Logo_Document_API_Name__c)){
            setting.Kinetics__Logo_Document_API_Name__c = 'testlogo';
            doUpsert = true;
        }
        if(doUpsert){
            upsert setting;
        }
    }

    public static List<Account> createAccount() {
        List<Account> accList = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'Account 1';
        acc1.ShippingLatitude = 11.111111;
        acc1.ShippingLongitude = 11.111111;
        acc1.ShippingCountry ='XYZ';
        accList.add(acc1);
        insert accList;
        return accList;
    }

    public static List<Contact> createContact(List<Account> accList) {

        List<Contact> conList = new List<Contact>();
        for(Account a: accList) {
            Contact c = new Contact();
            c.FirstName = 'test firstName'; 
            c.LastName = 'test lastName' + a.Name;
            c.Email = 'abs@fieldko.com';
            c.MobilePhone = '999999999';
            c.AccountId = a.Id;
            conList.add(c);
        }
        insert conList;
        return conList;
    }

    public static List<Kinetics__Kinetic_Question__c> createQuestion(){
        List<Kinetics__Kinetic_Question__c> qestList = new List<Kinetics__Kinetic_Question__c>();
        Kinetics__Kinetic_Question__c kq= new Kinetics__Kinetic_Question__c();
        kq.Kinetics__Default_Value__c = 'testv1';
        kq.Kinetics__Field_Type__c = 'Radio Button';
        kq.Kinetics__Has_Followup_Questions__c = false;
        kq.Kinetics__Is_Photo_Mandatory__c = false;
        kq.Kinetics__Parent_Option_Value__c = '';
        kq.Kinetics__Parent_Question__c = null;
        kq.Kinetics__Custom_Question_Number__c = null;
        kq.Kinetics__Question__c = 'Test Question Radio button';
        kq.Kinetics__Status__c = 'Active';
        kq.Kinetics__Take_Photo__c = false;
        kq.Kinetics__Values__c = 'testv1, testv2, testv3';
        qestList.add(kq);
        
        insert qestList;
        return qestList;
    }
    public static List<Kinetics__Kinetic_Question__c> createQuestionForRelatedObject(){
        List<Kinetics__Kinetic_Question__c> qestList = new List<Kinetics__Kinetic_Question__c>();
        Kinetics__Kinetic_Question__c kq= new Kinetics__Kinetic_Question__c();
        kq.Kinetics__Default_Value__c = 'testv1';
        kq.Kinetics__Field_Type__c = 'Text';
        kq.Kinetics__Has_Followup_Questions__c = false;
        kq.Kinetics__Is_Photo_Mandatory__c = false;
        kq.Kinetics__Parent_Option_Value__c = '';
        kq.Kinetics__Parent_Question__c = null;
        kq.Kinetics__Custom_Question_Number__c = null;
        kq.Kinetics__Question__c = 'Test Question related object question';
        kq.Kinetics__Status__c = 'Active';
        kq.Kinetics__Take_Photo__c = false;
        kq.Kinetics__Values__c = '';
        kq.Kinetics__Related_To_Object__c = 'Contact';
        kq.Kinetics__Related_Field_API_Name__c = 'FirstName';
        qestList.add(kq);
        
        insert qestList;
        return qestList;
    }

    public static List<Kinetics__Kinetic_Form__c> createKineticForm() {
        List<Kinetics__Kinetic_Form__c> kfList = new List<Kinetics__Kinetic_Form__c>();
        Kinetics__Kinetic_Form__c kf = new Kinetics__Kinetic_Form__c();

        kf.Kinetics__Instructions__c = 'Test Kinetic Form to be completed';
        kf.Kinetics__Status__c = 'Active';
        kf.Name = 'Test Kinetic Form';
        kfList.add(kf);

        insert kfList;
        return kfList;
    }

    public static List<Kinetics__Kinetic_Form_Question__c> createKineticFormQuestion(List<Kinetics__Kinetic_Question__c> qestList, List<Kinetics__Kinetic_Form__c> kfList) {
        List<Kinetics__Kinetic_Form_Question__c> kfqList = new List<Kinetics__Kinetic_Form_Question__c>();
        for(Kinetics__Kinetic_Form__c kf: kfList) {
            Integer counter = 1;
            for(Kinetics__Kinetic_Question__c kq: qestList) {
                Kinetics__Kinetic_Form_Question__c kfq = new Kinetics__Kinetic_Form_Question__c();
                kfq.Kinetics__Kinetic_Question__c = kq.Id;
                kfq.Kinetics__Kinetic_Form__c = kf.Id;
                kfq.Kinetics__Index__c = counter;
                kfqList.add(kfq);
                counter = counter + 1;
            }
        }
        insert kfqList;
        return kfqList;
    }

    public static List<Kinetics__Kinetic_Job__c> createKineticJob(List<Kinetics__Kinetic_Form__c> kfList) {
        List<Kinetics__Kinetic_Job__c> kjList = new List<Kinetics__Kinetic_Job__c>();
        for(Kinetics__Kinetic_Form__c kf: kfList){
            Kinetics__Kinetic_Job__c kj = new Kinetics__Kinetic_Job__c();
            kj.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
            kj.Kinetics__Kinetic_Form__c = kf.Id;
            kj.Kinetics__SMS_Template__c = '';
            kj.Kinetics__Status__c = 'New';
            kjList.add(kj);
        }
        insert kjList;
        return kjList;
    }

    public static List<Kinetics__Survey_Invitation__c> createSurveyInvitation(List<Contact> conList, List<Kinetics__Kinetic_Job__c> kjList) {
        List<Kinetics__Survey_Invitation__c> siList = new List<Kinetics__Survey_Invitation__c>();
        
        for(Contact c: conList){
            for(Kinetics__Kinetic_Job__c kj: kjList){
                Kinetics__Survey_Invitation__c si = new Kinetics__Survey_Invitation__c();
                si.Kinetics__TTL_Day__c = 7;
                si.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
                si.Kinetics__Send_Auto_Reminders__c = false;
                si.Kinetics__Reminder_Sent_count__c = 0;
                si.Kinetics__Last_Reminder_Sent_Date__c = null;
                si.Kinetics__Kinetic_Job__c = kj.Id;
                si.Kinetics__Kinetic_Form__c = kj.Kinetics__Kinetic_Form__c;
                si.Kinetics__GUID__c = GlobalUtility.generateGuid();
                si.Kinetics__Days_between_two_reminders__c = 0;
                si.Kinetics__Days_before_First_Reminder__c = 0;
                si.Kinetics__Contact__c = c.Id;
                si.Kinetics__Channel__c = GlobalConstants.channelSMS;
                siList.add(si);
            }
        } 
        insert siList;
        return siList;
    }

    public static List<Kinetics__Kinetic_Form_Answer__c> createAnswers(List<Kinetics__Survey_Invitation__c> siList, List<Kinetics__Kinetic_Form_Question__c> kfqList, List<Kinetics__Kinetic_Question__c> questList) {
        List<Kinetics__Kinetic_Form_Answer__c> ansList = new List<Kinetics__Kinetic_Form_Answer__c>();
        
        for(Kinetics__Survey_Invitation__c si: siList) {
            Kinetics__Kinetic_Form_Answer__c kfa = new Kinetics__Kinetic_Form_Answer__c();
            kfa.Kinetics__Answer__c = 'b';
            kfa.Kinetics__Answer_Index__c = 1;
            kfa.Kinetics__Attachment__c = false;
            kfa.Kinetics__has_Multiple_Attachments__c = false;
            kfa.Kinetics__Is_Uploaded_Image__c = false;
            kfa.Kinetics__Kinetic_Form_Question__c = kfqList[0].Id;
            kfa.Kinetics__Kinetic_Question__c = questList[0].Kinetics__Question__c;
            kfa.Kinetics__Kinetic_Question_Values__c = 'a,b,c';
            kfa.Kinetics__Survey_Invitation__c = si.Id;
            kfa.Kinetics__Type__c = 'Radio Button';
            ansList.add(kfa);
        }
        insert ansList;
        return ansList;
    }

    public static Kinetics__Calendly_Settings__c configureCalendlySettings () {
        
        Kinetics__Calendly_Settings__c setting = Kinetics__Calendly_Settings__c.getInstance();
        
        if(String.isEmpty(setting.Kinetics__Base_Booking_URL__c)){
            setting.Kinetics__Base_Booking_URL__c = 'testbookingURL';
        }
        if(String.isEmpty(setting.Kinetics__Calendly_Script_URL__c)){
            setting.Kinetics__Calendly_Script_URL__c = 'testScriptingURL';
        }
        setting.Kinetics__Hide_Event_Type_Details__c = false;
        
        upsert setting;
        return setting;
    }

    public static void createFileAttached(String parentId, String fileContent) {
        ContentVersion contentToInsert =new ContentVersion();
        contentToInsert.Title = 'testFile.png';
        contentToInsert.VersionData=Blob.valueOf(fileContent);
        contentToInsert.PathOnClient='/' + 'testFile.png' ;
        contentToInsert.IsMajorVersion = false;
        upsert contentToInsert;

        contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentToInsert.ContentDocumentId;
        cl.LinkedEntityId = parentId;
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
    }
    public static void configureGPTSetting() {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        Boolean doUpsert = false;
        if(String.isEmpty(setting.Kinetics__GPT_API_Key__c)){
            setting.Kinetics__GPT_API_Key__c = 'sk-xjJkVGdRLu6izbZdk7FJqRQKpIg2EZv1Gljva4su';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__Chat_Completions_End_Point__c)){
            setting.Kinetics__Chat_Completions_End_Point__c = 'https://api.openai.com/v1/chat/completions';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__GPT_Model__c)){
            setting.Kinetics__GPT_Model__c = 'gpt-4';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__OpenAI_Organization__c)){
            setting.Kinetics__OpenAI_Organization__c = 'xjJkVGdRLu6izbZdk7FJqRQKpIg2EZv1Gljva4su';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__Temperature__c)){
            setting.Kinetics__Temperature__c = '0.5';
            doUpsert = true;
        }
        if(String.isEmpty(setting.Kinetics__Assistant_AI_Base_End_Point__c)){
            setting.Kinetics__Assistant_AI_Base_End_Point__c = 'https://asd.com/';
            doUpsert = true;
        }
        
        if(doUpsert){
            upsert setting;
        }
    }
}