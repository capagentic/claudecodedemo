/*
    Auther: 
    Date: 5th Aug 2021
    Purpose:

    UDATE:
    this class is deprecated on 27th Dec 2021, but since this was added earlier, we can not remove i from
*/

public class AWSUtil {
  /**
    p`ublic String accessKey;
      public String accessSecret;
      public String awsHost;
      public String awsRegion;
      public String awsServiceName;
      public String canonicalUri;
      public Date   dateStamp;
      public String httpVerb;
  
      public String action;
      public String message;
      public String phonenumber;
      public String bucketName;        //S3 bucket name
      public Map<string, string> canonicalHeaders;
      public Map<String, String> canonicalQueryMap;
      public List<string>        signedHeaders;
      public Map<String, String> paramMap;
      
      public static final String AWS_HEADER_ENCRYPTION_SCHEME = 'AWS4-HMAC-SHA256';
      public static final String AWS_ENCRYPTION_SCHEME = 'SHA-256';
      public  static final String S3_TIMEOUT = '86400';
  
      
      public AWSUtil(AWSConfig awsConfig){
        // AWS Configuration
          this.accessKey     = awsConfig.accessKey;
          this.accessSecret   = awsConfig.accessSecret;
          this.awsHost     = awsConfig.awsHost ;
          this.awsRegion     = awsConfig.awsRegion;
          this.awsServiceName = awsConfig.awsServiceName;
      }
  
      public AWSUtil(AWSConfig awsConfig, Map<String, String> paramMap){
          // AWS Configuration
          this.accessKey     = awsConfig.accessKey;
          this.accessSecret   = awsConfig.accessSecret;
          this.awsHost     = awsConfig.awsHost ;
          this.awsRegion     = awsConfig.awsRegion;
          this.awsServiceName = awsConfig.awsServiceName;
          this.paramMap = paramMap;
      }
  
  
      public void initSNS(){
          this.httpVerb       = 'GET';
          this.canonicalUri   = '';
  
          // Map out the canonical header elements
          this.canonicalHeaders = new Map<string,string>();
          this.canonicalHeaders.put('host', this.awsHost);
  
          // List out the signed headers
          this.signedHeaders = new List<string>();
          this.signedHeaders.add('host');
  
          canonicalQueryMap = new Map<string, string>();
          canonicalQueryMap.put('AWSAccessKeyId', this.accessKey);
          canonicalQueryMap.put('Action',  this.action);
          canonicalQueryMap.put('Message', this.message);
          canonicalQueryMap.put('PhoneNumber', this.phonenumber); 
          canonicalQueryMap.put('SignatureMethod', 'HmacSHA256');
          canonicalQueryMap.put('SignatureVersion', '4');
          canonicalQueryMap.put('Timestamp', this.dateStampISO);
  
          canonicalQueryMap.put('X-Amz-Algorithm', AWSUtil.AWS_HEADER_ENCRYPTION_SCHEME);                          
          canonicalQueryMap.put('X-Amz-Credential', this.accessKey + '/' + this.dateStampYYYYMMDD + '/' + this.awsRegion + '/sns/aws4_request');
          canonicalQueryMap.put('X-Amz-Date', this.dateStampISO); // convert to ISO 8601 format
          canonicalQueryMap.put('X-Amz-SignedHeaders', 'host');
      }
  
      public void initS3() {
          this.httpVerb       = this.paramMap.get('httpMethod');
          this.canonicalUri   = this.paramMap.get('canonicalUri');
          this.bucketName     = this.paramMap.get('S3_BUCKET_NAME');
          String expiresSeconds = this.paramMap.containsKey('S3_TIMEOUT') ? this.paramMap.get('S3_TIMEOUT') : S3_TIMEOUT;
  
          // Map out the canonical header elements
          this.canonicalHeaders = new Map<string,string>();
          this.canonicalHeaders.put('host', this.awsHost);
          // List out the signed headers
          this.signedHeaders = new List<string>();
          this.signedHeaders.add('host');
  
          // Add other headers
          String headersNeedToSign = this.paramMap.get('X-Amz-SignedHeaders');
          List<String> headers = headersNeedToSign.split(';');
          headers.sort();
          for (String header : headers) {
              if (header != 'host') {
                  signedHeaders.add(header);
                  canonicalHeaders.put(header, this.paramMap.get(header));
              }
          }
  
          // Map out canonical query
          this.canonicalQueryMap = new Map<string, string>();
          this.canonicalQueryMap.put('X-Amz-Algorithm', AWSUtil.AWS_HEADER_ENCRYPTION_SCHEME);
          this.canonicalQueryMap.put('X-Amz-Credential', this.accessKey + '/' + this.dateStampYYYYMMDD + '/' + this.awsRegion + '/s3/aws4_request');
          this.canonicalQueryMap.put('X-Amz-Date', this.dateStampISO); // convert to ISO 8601 format
          this.canonicalQueryMap.put('X-Amz-Expires', expiresSeconds);
          this.canonicalQueryMap.put('X-Amz-SignedHeaders', this.paramMap.get('X-Amz-SignedHeaders'));
      }
  
      
      public String getSignedUrl() {
          if(this.accessKey == null || 
              this.accessSecret == null || 
              this.awsHost == null || 
              this.awsRegion == null || 
              this.awsServiceName == null){
              return null;
          }
  
          String url = '';
          if (this.awsServiceName == 'sns') {
              initSNS();
              url = 'https://' + this.awsHost + '/' + canonicalUri + '?';
          } else if (this.awsServiceName == 's3') {
              initS3();
              url = 'https://' + this.awsHost + '/' + bucketName + '/' + canonicalUri + '?';
          }
  
          for (String key: this.canonicalQueryMap.keySet()) {
              url += key + '=' + awsUriEncode(this.canonicalQueryMap.get(key)) + '&';
          }
  
          url += 'X-Amz-Signature=' + this.getSignature();
          return url;
      }
  
      ]
      public String getSignature() {
          return this.generateSignature(this.getStringToSign(), this.getSigningKey());
      }
  
     
      public String generateSignature(String stringToSign, blob signingKey) {
          blob signatureBlob = Crypto.generateMac('hmacSHA256', blob.valueOf(stringToSign), signingKey);
          return EncodingUtil.convertToHex(signatureBlob);
      }
  
  ]
      public String getStringToSign() {
          String stringToSign = AWSUtil.AWS_HEADER_ENCRYPTION_SCHEME + '\n'
                        + this.dateStampISO + '\n'
                        + this.dateStampYYYYMMDD + '/' + this.awsRegion + '/' + this.awsServiceName + '/aws4_request' + '\n'
                        + EncodingUtil.convertToHex(Crypto.generateDigest(AWSUtil.AWS_ENCRYPTION_SCHEME, blob.valueOf(this.getRequestString())));
          return stringToSign;
      }
  
      
      public blob getSigningKey() {
          // ==== GENERATE THE SIGNING KEY ====
          Blob dateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.dateStampYYYYMMDD), Blob.valueOf('AWS4' + this.accessSecret));
          Blob dateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.awsRegion), dateKey);
          Blob dateRegionServiceKey = Crypto.generateMac('hmacSHA256', blob.valueOf(this.awsServiceName), dateRegionKey);
          Blob signingKey = Crypto.generateMac('hmacSHA256', blob.valueOf('aws4_request'), dateRegionServiceKey);
          return signingKey;
      }
  
  
      public String getRequestString() {
  
          // ==== CONSTRUCT THE REQUEST STRING FROM THE DATA ====
          // Now construct the canonical request string from these elements.
          String canonicalRequestString = this.httpVerb + '\n'
              + '/' + this.canonicalUri + '\n';
          if (this.awsServiceName == 's3') {
              canonicalRequestString = this.httpVerb + '\n'
                      + '/' + bucketName + '/' + this.canonicalUri + '\n';
          }
  
          // Add the query string
          // we assume the elements remain in alphabetical order. TODO: sort just to be sure.
          for (String key : this.canonicalQueryMap.keySet()) {
              canonicalRequestString += awsUriEncode(key) + '=' + awsUriEncode(this.canonicalQueryMap.get(key)) + '&';
          }
  
          // replace the last & with a \n
          canonicalRequestString = canonicalRequestString.left(canonicalRequestString.length() - 1) + '\n';
  
          // Add the canonical headers with a linefeed at the end of each
          for (String key : this.canonicalHeaders.keySet()) {
              if(this.canonicalHeaders.get(key) != null) {                
                  canonicalRequestString += key.toLowerCase() + ':' + this.canonicalHeaders.get(key).trim() + '\n';
              }
          }
  
          // add an additional linefeed
          canonicalRequestString += '\n';
  
  
          // Add signed headers
          // we assume the elements remain in alphabetical order.
          // TODO: sort just to be sure and check that the map isn't empty.
          Integer keyNum = 0;
          for (String key : this.signedHeaders) {
              keyNum ++;
              if(keyNum > 1) {
                  canonicalRequestString += ';';
              }
              canonicalRequestString += key.toLowerCase();
          }
  
          // add an additional linefeed
          canonicalRequestString += '\n';
  
          // add the hashed payload (empty string)
          if (this.awsServiceName == 'sns') {
              canonicalRequestString += 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
          } else if(this.awsServiceName == 's3') {
              canonicalRequestString += 'UNSIGNED-PAYLOAD';
          }
          return canonicalRequestString;
      }
  
  
    
      public String dateStampYYYYMMDD {
          get {
              Date dateToday;
              if (this.dateStamp == null) {
                  // Current date (GMT)
                  Datetime datetimeToday = System.now();
                  dateToday = date.newinstance(datetimeToday.yearGmt(), datetimeToday.monthGmt(), datetimeToday.dayGmt());
              } else {
                  //dateToday = this.dateStamp;
              }
  
              // Calculate today as yyyymmdd
              String sMonth = String.valueof(dateToday.month());
              String sDay = String.valueof(dateToday.day());
              if(sMonth.length()==1){ sMonth = '0' + sMonth; }
              if(sDay.length()==1){ sDay = '0' + sDay;}
              String sToday = String.valueof(dateToday.year()) + sMonth + sDay ;
  
              return sToday;
          }
      }
  
    
      private String dateStampISO {
          get {
              if (this.dateStamp == null) {
                  String gmtHour = String.valueOf(System.now().hourGmt());
                  String gmtMinute = String.valueOf(System.now().minuteGmt());
                  String gmtSecond = String.valueOf(System.now().secondGmt());
                  
                  if(gmtHour.length()==1){ gmtHour = '0' + gmtHour; }
                  if(gmtMinute.length()==1){ gmtMinute = '0' + gmtMinute; }
                  if(gmtSecond.length()==1){ gmtSecond = '0' + gmtSecond; }
                  
                  // add GMT ThhmmssZ
                  return dateStampYYYYMMDD + 'T' + gmtHour + gmtMinute + gmtSecond + 'Z';
              }else{
                  return dateStampYYYYMMDD + 'T000000Z';
              } 
          }
      }
  
     
      private static String awsUriEncode (String str) {
          return str==null? null: EncodingUtil.urlEncode(str, 'utf-8').replaceAll('%7E','~').replaceAll('\\+','%20');
      }
  
  
      public class AWSConfig{
        public String accessKey;
        public String accessSecret;
        public String awsHost;
        public String awsRegion; 
        public String awsServiceName; 
      }*/
}