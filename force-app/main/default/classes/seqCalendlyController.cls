/**
 * Auther: Shankar Dupade(FieldKo)
 * Purpose: Controller for getting details for Calendly
 * Date: 4th Feb 2022
 */
public with sharing class seqCalendlyController {
    
    @AuraEnabled
    public static string getDetailsForCalendly(String seqGUID){
        return GuestUserHandlerHelper.getDetailsForCalendly(seqGUID);
    }

    public class calendlyWrapper {
        @AuraEnabled
        public Contact conRec;

        @AuraEnabled
        public Kinetics__Calendly_Settings__c calendlyConfig;
    }
}