public with sharing class GPTRecommendationService {
    public GPTRecommendationService() {

    }

    public static void createNotesTasks(String jobID) {
        List<GPT_Job__c> jobs = [SELECT Id, Error_Details__c, New_Records_Owner_ID__c, Original_Request_Record_ID__c, Response_Payload__c FROM GPT_Job__c WHERE Id =: jobID];
        GPT_Job__c job = jobs.get(0);
        try{
            List<Kinetics__Inspection__c> inspList = [SELECT Id, Account__c, Contact__c from Kinetics__Inspection__c WHERE ID = :job.Original_Request_Record_ID__c LIMIT 1];
            Kinetics__Inspection__c insp;
            if(inspList.size() > 0) {
                insp = inspList.get(0);
            }

            GPTResponse gptRes = (GPTResponse) JSON.deserialize(job.Response_Payload__c, GPTResponse.class);
            List<GPTResponse.Choices> choices = gptRes.choices;
            GPTResponse.Choices choice = choices.get(0);
            GPTResponse.Message message = choice.message;
            String content = message.content;

            GPTRecommendationResponse recommendationObj = (GPTRecommendationResponse) JSON.deserialize(content, GPTRecommendationResponse.class);
            

            String summaryContent = '';

            summaryContent = '<h2>Executive Summary</h2>';
            if (recommendationObj.summary != null) {
                summaryContent += recommendationObj.summary;
            }
            summaryContent += '<br/><br/>';
            summaryContent += '<h2>Key Highlights</h2>';

            String interestingSummary = '<ul>';
            for (Integer i = 0; i < recommendationObj.interesting_summary.size(); i++) {
                interestingSummary = interestingSummary + '<li>' + recommendationObj.interesting_summary.get(i).description + '</li>';
            }
            interestingSummary = interestingSummary + '</ul>';
            summaryContent += interestingSummary;
            summaryContent += '<br/>';
            summaryContent += '<h2>Recommendations</h2>';
                // var dueDate = new Date();
                // dueDate = new Date(dueDate.setDate(dueDate.getDate() + 7));
                // dueDate = dueDate.toISOString().slice(0, 10);
            List<Task> taskList = new List<Task>();
            String recommendationDescriptions = '<ul>';
                
            for (Integer i = 0; i < recommendationObj.recommendations.size(); i++) {
                GPTRecommendationResponse.Recommendation recomObj = recommendationObj.recommendations.get(i);

                Task task = new Task();
                task.Subject = '\uD83D\uDE80 ' + recomObj.subject;
                task.ActivityDate   = System.Today() + 7;
                task.Status         = 'Not Started';
                task.Priority       = recomObj.priority;
                task.WhatId         = job.Original_Request_Record_ID__c;
                task.Description    = recomObj.description;
                task.OwnerId        = job.New_Records_Owner_ID__c;
                task.WhoId          = insp.Contact__c;
                taskList.add(task);

                recommendationDescriptions += '<li>' + recomObj.description + '</li>';
            }
            recommendationDescriptions += '</ul>';
            summaryContent = summaryContent + recommendationDescriptions;

            summaryContent += '<br/>';
            summaryContent += '<h2>Further Analysis</h2>';
            if (recommendationObj.detailed_analysis != null) {
                summaryContent += recommendationObj.detailed_analysis;
            }

            summaryContent += '<br/><br/>';

            String summaryTitle = (recommendationObj.summary_title != null ) ? recommendationObj.summary_title : 'Summary by GPT';

            
            if(!taskList.isEmpty()){
                insert taskList;
            }

            ContentNote objCntNote = new ContentNote();
            objCntNote.Title = summaryTitle;
            objCntNote.Content = Blob.valueOf(summaryContent);
            insert objCntNote; //Insert Content Note   
            
            List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
            //create ContentDocumentLink  record to link with parentId 
            ContentDocumentLink objCntDocLink = new ContentDocumentLink();
            objCntDocLink.LinkedEntityId = insp.Id;
            objCntDocLink.ContentDocumentId = objCntNote.Id;  //Content Note Id
            objCntDocLink.shareType = 'V'; // Specify your sharing type 
            cdLinkList.add(objCntDocLink);

            if(inspList[0].Contact__c != null) {
                ContentDocumentLink objCntDocLink1 = new ContentDocumentLink();
                objCntDocLink1.LinkedEntityId = insp.Contact__c;
                objCntDocLink1.ContentDocumentId = objCntNote.Id;  //Content Note Id
                objCntDocLink1.shareType = 'V'; // Specify your sharing type 
                cdLinkList.add(objCntDocLink1);
            }
            if(inspList[0].Account__c != null) {
                ContentDocumentLink objCntDocLink2 = new ContentDocumentLink();
                objCntDocLink2.LinkedEntityId = insp.Account__c;
                objCntDocLink2.ContentDocumentId = objCntNote.Id;  //Content Note Id
                objCntDocLink2.shareType = 'V'; // Specify your sharing type 
                cdLinkList.add(objCntDocLink2);
            }
            insert cdLinkList;

            job.Status__c = 'Response Parsed';
            update job;
        }catch(Exception ex){
            job.Status__c = 'Parsing Error';
            String errorDetails = System.Now() + ':\n' +  ex.getMessage() + '\n\n';
            job.Error_Details__c = (job.Error_Details__c != null) ? (job.Error_Details__c + '\n\n' + errorDetails): errorDetails;
            update job;
        }
        
    }
}