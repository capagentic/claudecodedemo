/**
 * Author: Shankar Dupade (FieldKo)
 * Date: 6-08-2021
 * Purpose: Helper class for collecting selected contacts from list view
 */
public with sharing class getSelectedRecipientController {
    public String conIdsString{get;set;}

    public getSelectedRecipientController(ApexPages.StandardSetController standardController) {
        List<String> conIds = new List<String>();
        //get selected contact records ids
        for (Contact con : (List<Contact>)standardController.getSelected()){ 
            conIds.add(con.Id);
        }
        conIdsString = JSON.serialize(conIds);
    }
}