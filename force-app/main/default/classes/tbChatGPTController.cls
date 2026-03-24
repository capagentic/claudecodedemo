/**
 * Author: Shankar Dupade
 * Purpose: Controller class to help get ChatGPT related functionalities
 * Date: 21-March-2023
 */

 public with sharing class tbChatGPTController {
    private static String endpoint = GlobalUtility.getGPTEndPoint(); //'https://api.openai.com/v1/chat/completions';
    private static String httpMethod = 'POST';
    // private static String model = 'gpt-3.5-turbo';
    private static String model = GlobalUtility.getGPTModel(); //'gpt-4';
    private static String openAI_Organization = GlobalUtility.getOpenAI_Organization();
    private static Decimal temperature = GlobalUtility.getTemperature();

    @AuraEnabled
    public static String invokeGeneratChecklistModel(String gptParameterString) {
        
        Map<String, String> gptParameter = (Map<String, String>) JSON.deserialize(gptParameterString, Map<String, String>.class);
        if(!gptParameter.containsKey('yourrole')) {
            gptParameter.put('yourrole', 'Manager');
        }

        String contentString = 'I am a '+ gptParameter.get('yourrole');
        contentString = contentString + '. I require an inspection checklist template in JSON format to '; 
        if(gptParameter.containsKey('checklistneed')){
            contentString = contentString + gptParameter.get('checklistneed');
        }
        contentString = contentString + '. The objective of each inspection is to ';
        if(gptParameter.containsKey('inspectionobjective')){
            contentString = contentString + gptParameter.get('inspectionobjective');
        }
        if(gptParameter.containsKey('applicableStandards')) { 
            contentString = contentString + '. The inspection checklist should comply with and make references to within the question text to guidelines as set out by the ' + gptParameter.get('applicableStandards'); 
        } 
        contentString = contentString + ' The response should be in JSON format labeled as \'checklist\' and include checklist title labeled as \'title\' and instruction to complete the checklist labeled as \'instructions\'. ';
        contentString = contentString + ' Question types should include text, date, picklist, multiselect picklist, geolocation, pass/fail, number, currency, percentage, email, signature, 1-10 star rating, net promoter score and photos.';
        contentString = contentString + ' Each picklist or multiselect picklist question type should have a score and logical color associated with the answer choices with a score between 1 to 10 where 10 is the best and the logical colors of each picklist value should indicate that green, orange and red represent good, average and poor respectively. ';
        contentString = contentString + ' The 1-10 star rating question type should be used to capture qualitative feedback from the inspector and each checklist should include at least one 1-10 star rating question type';
        contentString = contentString + ' Question types should include photos to allow the inspector to capture photos of important aspects of the inspection to help the inspector meet the inspection objective and each checklist should include at least one photo question type';
        contentString = contentString + ' Divide the checklist into logical sections with section labeled as \'section_label\'. ';
        contentString = contentString + ' Each question label should be labeled as \'question_label\' and question type as \'question_type\'. ';
        contentString = contentString + ' Each option label should be labeled as \'option_label\', score should be labeled as \'score\' and color should be labeled as \'color\'.';
    
        Map<String, Object> requestPayload = new Map<String, Object>();
        requestPayload.put('model', tbChatGPTController.model);
        List<Map<String, String>> messageMapList = new List<Map<String, String>>();
        
        Map<String, String> messageMap = new Map<String, String>();
        messageMap.put('role', 'user');
        messageMap.put('content', contentString);
        messageMapList.add(messageMap);

        Map<String, String> messageMap1 = new Map<String, String>();
        messageMap1.put('role', 'system');
        messageMap1.put('content', 'You are a inspection checklist author');
        messageMapList.add(messageMap1);

        requestPayload.put('messages', messageMapList);
        requestPayload.put('temperature', tbChatGPTController.temperature);
        
        HTTPResponse res = doCallout(JSON.serialize(requestPayload), new Map<String, String>());
        if(res == null) {
            throw new AuraHandledException('GPT configuration not found');
        }
        System.debug(res);
        System.debug(res.getBody());
       
        return String.valueOf(res.getBody());
    }

    
    public static HTTPResponse doCallout(String requestPayloadString, Map<String, String> extraRequestHeaders) {
        
        if(String.isBlank(tbChatGPTController.httpMethod) 
            || String.isBlank(tbChatGPTController.endPoint) ) {
            //GPT configuration not defined
            return null;
        }

        Map<String, String> requestHeaders = new Map<String, String>();
        requestHeaders.putAll(extraRequestHeaders); 
       // requestHeaders.put('Content-Type', 'application/json');
        
        return HttpRequestService.doRequest(requestPayloadString, tbChatGPTController.httpMethod, tbChatGPTController.endPoint, requestHeaders);
    }

    @AuraEnabled
    public static string getRelatedAnswersForInspection(String inspRecordId){
        try {
            
            List<Kinetics__Kinetic_Form_Answer__c> answerList = [SELECT Id, Kinetics__Answer__c, Kinetics__Answer_Index__c, 
                                                                    Kinetics__Kinetic_Question_Values__c, Kinetics__Kinetic_Question__c,
                                                                    Kinetics__Type__c, Kinetics__AI_Guidance__c 
                                                                    FROM Kinetics__Kinetic_Form_Answer__c
                                                                    WHERE Kinetics__Inspection__c = :inspRecordId];

            return JSON.serialize(answerList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getGPTParameters(String inspRecordId){
        try {
            Map<String, String> gptParameters = new Map<String, String>();
            List<Kinetics__Inspection__c> inspectionList = [SELECT Id, Name, Kinetics__Template__c, Kinetics__Template__r.Kinetics__Chat_GPT_Parameters__c 
                                                        FROM Kinetics__Inspection__c 
                                                        WHERE Id =: inspRecordId 
                                                        LIMIT 1];
            
          
            if(inspectionList.size() > 0 && String.isNotBlank(inspectionList[0].Kinetics__Template__r.Kinetics__Chat_GPT_Parameters__c)){
                gptParameters = (Map<String, String>) JSON.deserialize(inspectionList[0].Kinetics__Template__r.Kinetics__Chat_GPT_Parameters__c, Map<String, String>.class);
            }
            return JSON.serialize(gptParameters);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // @AuraEnabled
    // public static string createRecords(String noteRecordJSON, String taskRecordJSON, String inspRecordId){
    //     try {
    //         List<Kinetics__Inspection__c> inspList = [SELECT Id, Account__c, Contact__c from Kinetics__Inspection__c WHERE ID = :inspRecordId LIMIT 1];
    //         if(inspList.size() == 0) {
    //             return '';
    //         }
    //         if(String.isEmpty(noteRecordJSON) && String.isEmpty(taskRecordJSON)) {
    //             return '';
    //         }
    //         if(!String.isEmpty(taskRecordJSON)) {
    //             List<Task> tlist = (List<Task>) JSON.deserialize(taskRecordJSON, List<Task>.class);

    //             for(Task t: tlist) {
    //                 t.WhoId = (inspList[0].Contact__c != null ? inspList[0].Contact__c: null);
    //             }
    //             upsert tlist;
    //         }

    //         if(!String.isEmpty(noteRecordJSON)){
    //             Map<String, String> noteDetails = (Map<String, String>) JSON.deserialize(noteRecordJSON, Map<String, String>.class);
    //             ContentNote objCntNote = new ContentNote();
    //             objCntNote.Title = noteDetails.get('title');
    //             objCntNote.Content = Blob.valueOf(noteDetails.get('content'));
    //             insert objCntNote; //Insert Content Note   
                
    //             List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
    //             //create ContentDocumentLink  record to link with parentId 
    //             ContentDocumentLink objCntDocLink = new ContentDocumentLink();
    //             objCntDocLink.LinkedEntityId = inspRecordId;
    //             objCntDocLink.ContentDocumentId = objCntNote.Id;  //Content Note Id
    //             objCntDocLink.shareType = 'V'; // Specify your sharing type 
    //             cdLinkList.add(objCntDocLink);

    //             if(inspList[0].Contact__c != null) {
    //                 ContentDocumentLink objCntDocLink1 = new ContentDocumentLink();
    //                 objCntDocLink1.LinkedEntityId = inspList[0].Contact__c;
    //                 objCntDocLink1.ContentDocumentId = objCntNote.Id;  //Content Note Id
    //                 objCntDocLink1.shareType = 'V'; // Specify your sharing type 
    //                 cdLinkList.add(objCntDocLink1);
    //             }
    //             if(inspList[0].Account__c != null) {
    //                 ContentDocumentLink objCntDocLink2 = new ContentDocumentLink();
    //                 objCntDocLink2.LinkedEntityId = inspList[0].Account__c;
    //                 objCntDocLink2.ContentDocumentId = objCntNote.Id;  //Content Note Id
    //                 objCntDocLink2.shareType = 'V'; // Specify your sharing type 
    //                 cdLinkList.add(objCntDocLink2);
    //             }
    //             insert cdLinkList;
    //         }
    //         return 'Success';
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @InvocableMethod(label='Populate Notes and Tasks' description='Populate Notes and Tasks based on an inspection' category='Inspection')
    public static void createNotesTasks(List<ID> jobID) {
        String jID = jobID.get(0);
        GPTRecommendationService.createNotesTasks(jID);
    }


    @AuraEnabled
    public static string createAudioFile(String audioRecordingBase64String, String fileName, String inspectionId) {
        try {

        //     audioRecordingBase64String = EncodingUtil.urlDecode(audioRecordingBase64String, 'UTF-8');

        //     ContentVersion contentToInsert = new ContentVersion(); 
        //     contentToInsert.Title = fileName; 
        //     contentToInsert.VersionData = EncodingUtil.base64Decode(audioRecordingBase64String);
        //     //contentToInsert.VersionData = Blob.valueOf(audioRecordingBase64String);
        //     contentToInsert.PathOnClient = '/' + fileName ;
        //     contentToInsert.IsMajorVersion = false;
        //     //do not remove/change the description value because there is chcekc on that in the craveable org, atleast keep 'kinetic' in the description field
        //     contentToInsert.Description = 'Kinetic: Created for Kinetic Form Link answers';
        //     insert contentToInsert;
            
        //     contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
        //     ContentDocumentLink cl = new ContentDocumentLink();
        //     cl.ContentDocumentId = contentToInsert.ContentDocumentId;
        //     cl.LinkedEntityId = inspectionId;
        //     cl.ShareType = 'V';
        //     cl.Visibility = 'AllUsers';
        //     insert cl;
           
        //    return contentToInsert.Id;
            return 'Development in progress';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // create a GPT Job to initiate an async callout to GPT
    @AuraEnabled
    public static String createGPTJob(String inspRecordId, String gptParameterString){
        system.debug('tbChatGPTController>createGPTJob>inspRecordId=' + inspRecordId);
        system.debug('tbChatGPTController>createGPTJob>gptParameterString=' + gptParameterString);
        LwcResponse lwcRes = new LwcResponse();
        try{
            GPT_Job__c exJob = checkExistingJob(inspRecordId);
            if(exJob != null){
                lwcRes.statusCode = 2100;
                lwcRes.responseMessage = 'duplicate jobs';
                lwcRes.responseDetails = exJob;
                return JSON.serialize(lwcRes); 
            }

            String prompt = constructGenerateSummaryRequestPayload(inspRecordId, gptParameterString);
            GPT_Job__c job = GPTJobService.createJob(inspRecordId, 'Inspection', 'Create a summary', prompt);

            lwcRes.statusCode = 2000;
            lwcRes.responseMessage = 'success';
            lwcRes.responseDetails = job;
            
        }catch(Exception ex){
            lwcRes.statusCode = 2200;
            lwcRes.responseMessage = 'error';
            lwcRes.responseDetails = ex.getMessage();
        }

        return JSON.serialize(lwcRes); 
        
    }

    // check if there are any existing jobs that have been created
    private static GPT_Job__c checkExistingJob(String inspID){
        GPT_Job__c exJob;
        List<GPT_Job__c> jobs = [SELECT ID, Name 
                                    FROM GPT_Job__c 
                                    WHERE Original_Request_Record_ID__c =: inspID 
                                        AND Inspection__c =: inspID
                                        AND (Status__c != 'Parsing Error'
                                        OR Status__c != 'Not Required')];
        if(!jobs.isEmpty()){
            exJob = jobs.get(0);
        }

        return exJob;
    }
  
    public static String constructGenerateSummaryRequestPayload(String inspRecordId, String gptParameterString){
        try {
            Map<String, String> gptParameter = (Map<String, String>) JSON.deserialize(gptParameterString, Map<String, String>.class);
            if(!gptParameter.containsKey('yourrole')) {
               gptParameter.put('yourrole', 'Manager');
            }
            String contentString = 'I am a '+ gptParameter.get('yourrole');
            // contentString = contentString + '. I require a summary, detailed analysis and recommendations along with title for the summary to be generated from inspection checklist questions and answers provided in JSON format noting that \'guidanceText\' must be used to provide additional context for the summary and recommendations. ';
            // if(gptParameter.containsKey('description')) {
            //    contentString = contentString + gptParameter.get('description');
            // }
            // contentString = contentString + '. The objective of we are seeking to achieve with this inspection checklist is to ';
        // if(gptParameter.containsKey('inspectionobjective')) 
            //    contentString = contentString + gptParameter.get('inspectionobjective');
            // }
            // contentString = contentString + ' The response should include a detailed analysis, summary and list of recommendations all of which must help meet the objective based on the questions and answers, the detailed analysis and summary should be plain text. The detailed analysis should be plain text labeld as \'detailed_analysis\'';
            // contentString = contentString + ' Recommendations should be a list of JSON objects having \'subject\', \'priority\', \'description\' as keys in JSON format labeled as \'recommendations\', the \'description\' should be provided as clear instruction text in two to three paragraphs. The summary should be labeled as \'summary\'';
            // contentString = contentString + ' Also provide list of up to 5 additional online resources as a JSON objects that can assist meeting the recommendations and labeled as \'additional_resources\', each object has \'description\' and \'link_to_online_resource\' as keys';
            // contentString = contentString + ' Also provide list of up to 3 summary points as a JSON object on what is most interesting about the summary and label it as \'interesting_summary\', each object has \'description\' as a key.';
            // contentString = contentString + ' Also is should provide a summary title for the whole response and label it as \'summary_title\'';

            contentString = 'Write me a summary, detailed analysis and recommendations along with title for the summary to be generated from inspection checklist questions and answers provided in JSON format. The response should include a detailed analysis, summary and list of recommendations. The result should follow the example here:{"summary_title":"xxx","detailed_analysis":"xxx","summary":"xxx","recommendations":[{"subject":"xxx","priority":"xxx","description":"xxx"},{"subject":"xxx","priority":"xxx","description":"xxx"}],"interesting_summary":[{"description":"xxx"},{"description":"xxx"}]}';
          
            String questionanswerJSON = '';
            List<Map<String, String>> answerJSON = new List<Map<String, String>>();
            List<Kinetics__Kinetic_Form_Answer__c> answerList = (List<Kinetics__Kinetic_Form_Answer__c>) JSON.deserialize(tbChatGPTController.getRelatedAnswersForInspection(inspRecordId), List<Kinetics__Kinetic_Form_Answer__c>.class);
            for(Kinetics__Kinetic_Form_Answer__c fa: answerList) {
                Map<String, String> answerObj = new Map<String, String>();
                answerObj.put('Question_label', fa.Kinetics__Kinetic_Question__c);
                answerObj.put('answer_value', fa.Kinetics__Answer__c);
               // answerObj.put('answer_index', String.valueOf(fa.Kinetics__Answer_Index__c));
                if(String.isNotBlank(fa.Kinetics__AI_Guidance__c)){
                    answerObj.put('guidance_text', String.valueOf(fa.Kinetics__AI_Guidance__c));
                }
               // answerObj.put('Question_possible_options', fa.Kinetics__Kinetic_Question_Values__c);
               // answerObj.put('question_type', fa.Kinetics__Type__c);
                answerJSON.add(answerObj);
            }
            questionanswerJSON = JSON.serialize(answerJSON);
        
            Map<String, Object> requestPayload = new Map<String, Object>();
            requestPayload.put('model', tbChatGPTController.model);
            List<Map<String, String>> messageMapList = new List<Map<String, String>>();
            Map<String, String> messageMap = new Map<String, String>();
            messageMap.put('role', 'user');
            messageMap.put('content', contentString);
            messageMapList.add(messageMap);

            Map<String, String> messageMap2 = new Map<String, String>();
            messageMap2.put('role', 'assistant');
            messageMap2.put('content', questionanswerJSON);
            messageMapList.add(messageMap2);
            
            requestPayload.put('messages', messageMapList);
            requestPayload.put('temperature', temperature);
            requestPayload.put('max_tokens', 4096);
            return JSON.serialize(requestPayload);

        } catch (Exception e) {
            return 'error';
        }
    }

    @AuraEnabled
    public static String transcribeAudio(String contentVersionId, String inspectionId) {
        String endpoint = 'https://api.openai.com/v1/audio/transcriptions';

        // ContentVersion cv = [SELECT Id, Title, FileType, VersionData, ContentDocumentId, ContentDocument.LatestPublishedVersionId,FileExtension FROM ContentVersion WHERE Id = :contentVersionId];
        // ContentDocument cd = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        // ContentVersion latestVersion = [SELECT Id, Title, FileType, VersionData,FileExtension FROM ContentVersion WHERE ContentDocumentId = :cd.Id AND IsLatest = true];
        // sendAudioFile( contentVersionId,latestVersion.versionData, latestVersion.FileExtension.toLowerCase(),  'whisper-1');
        return 'Development in progress';
    }
    // private static Blob constructRequestBody(Blob start, Blob data, Blob endBlob) {
    //     String encodedStart = EncodingUtil.base64Encode(start);
    //     String encodedData = EncodingUtil.base64Encode(data);
    //     String encodedEnd = EncodingUtil.base64Encode(endBlob);

    //     String requestBody = encodedStart + encodedData + encodedEnd;
    //     Blob requestBodyBlob = EncodingUtil.base64Decode(requestBody);

    //     return requestBodyBlob;
    // }

    // public static void sendAudioFile(String contentVersionId, Blob audioFile, String fileExtension, String modelName) {
    //     // Set the correct content type based on the file extension
    //      // Query ContentVersion
    //      ContentVersion contentVersion = [
    //         SELECT Title, VersionData, FileType, FileExtension
    //         FROM ContentVersion
    //         WHERE Id = :contentVersionId
    //     ];
    //     String filename;
    // }

    // private static String getContentTypeByFileExtension(String fileExtension) {
    //     Map<String, String> contentTypeMap = new Map<String, String>{
    //         'm4a' => 'audio/mp4',
    //         'mp3' => 'audio/mpeg',
    //         'webm' => 'audio/webm',
    //         'mp4' => 'audio/mp4',
    //         'mpga' => 'audio/mpeg',
    //         'wav' => 'audio/wav','mpeg' => 'audio/mpeg'
    //     };

    //     return contentTypeMap.get(fileExtension.toLowerCase());
    // }


}