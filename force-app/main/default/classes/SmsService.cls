public class SmsService {
    public SmsService() {
      
    }
  
  
    @Future(callout=true)
    public static void sendSMSAsync(String phonenumber, String message){
        System.debug('****** sendSMSAsync');
        handleSendSMS(phonenumber, message);
    }
    public static Boolean sendSMS(String phonenumber, String message){
        System.debug('****** sendSMS');
        return handleSendSMS(phonenumber, message);
    }
    private static Boolean handleSendSMS(String phonenumber, String message) {
        Boolean result;
       
        if(GlobalUtility.isWithinSMSAllowedLimit()){
            result = proceedToSendSMS(phonenumber, message);
            if(result){
                GlobalUtility.increaseSMSInvitationCountByOne();
            }
        } else {
            // need to show message to user on limit reached..
            GlobalUtility.informISVAboutSMSUsageLimit();
        }
        return result;
    }

    @InvocableMethod(label='Send SMS' description='Send SMS')
    public static void sendSMSInvocable(List<Requests> requestList) {
        Requests req = requestList.get(0);
        String phoneNumber = req.phonenumber;
        String message = req.message;

        if(String.isNotBlank(phoneNumber) && String.isNotBlank(message)){
            sendSMSAsync(phoneNumber, message);
        }
        
    }

    public class Requests {
        @InvocableVariable(label='Phone number' description='Phone number' required=true)
        public String phonenumber;

        @InvocableVariable(label='SMS message content' description='SMS message content' required=true)
        public String message;
      }
    


    private static Boolean proceedToSendSMS(String phonenumber, String message){
        Boolean result;
        try{
            APIGatewayUtil.AWSConfig config = new APIGatewayUtil.AWSConfig();
            List<Kinetics__AWS_Config__mdt> awsConfigList = GlobalUtility.getAWSConfigList();

            if(awsConfigList.size() <= 0) {
                result = false;
            } else {
                //we are assuming that only one record will be there with the config values... atleast at the time of development
                Kinetics__AWS_Config__mdt awsConfig = awsConfigList[0];

                // fieldko aws sns
                config.accessKey    = awsConfig.Kinetics__Access_Key__c;
                config.accessSecret = awsConfig.Kinetics__Access_Secret__c;
    
                config.awsHost = awsConfig.Kinetics__AWS_Host__c;
                config.awsRegion = awsConfig.Kinetics__AWS_Region__c;
                config.awsServiceName = awsConfig.Kinetics__AWS_Service_Name__c;
                config.functionName = awsConfig.Kinetics__Lambda_Function_Name__c;
                config.apiMethod = awsConfig.Kinetics__Method__c;
                config.stageName = awsConfig.Kinetics__Stage_Name__c;

                Map<String, String> bodyMap = new Map<String, String>();
                bodyMap.put('mobilenumber', phonenumber);
                bodyMap.put('message', message);
                String requestPayload = JSON.serialize(bodyMap);
                
                String baseURL = config.awsHost;
                APIGatewayUtil apiGateUtilObj = new APIGatewayUtil(baseURL, config);

                HttpResponse res = apiGateUtilObj.sendRequest(config.functionName, config.apiMethod, requestPayload, config.stageName);
                result = (res!=null && res.getStatusCode() == 200) ? true : false;
                //system.debug('**** res.body='+res.getBody());
            }
        } catch(Exception ex){
            system.debug('**** ex='+ex.getMessage());
            result = false;
        }
  
        return result;
    }
}