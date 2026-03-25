// ============================================================
// FILE:         APIGatewayUtil.cls
// ============================================================
// PURPOSE:
//   Utility class for sending signed HTTP requests to AWS API Gateway.
//   Implements AWS Signature Version 4 (SigV4) authentication, covering
//   canonical request construction, HMAC-SHA256 signing key derivation,
//   and Authorization header assembly. Currently used to deliver SMS
//   messages via an API Gateway-fronted Lambda function.
//
// BUSINESS REQUIREMENT:
//   To be confirmed
//
// CHANGE HISTORY:
//   Date          Author              Description
//   ----------    ----------------    ----------------------------
//   2021-12-23    Unknown             Initial creation
//
// CONSIDERATIONS:
//   - AWS credentials (access key and secret) must be supplied by the
//     caller; they should be stored in Named Credentials or Custom
//     Metadata, never hardcoded.
//   - Security/compliance: no PII is handled directly in this class,
//     but SMS payloads passed via `content` may contain PII — callers
//     are responsible for appropriate data handling.
//   - The canonical request hardcodes the HTTP verb as POST; callers
//     passing a different `method` value will produce a mismatched
//     signature. Extend if other verbs are required.
//   - Only HMAC-SHA256 is supported; algorithm is not configurable.
// ============================================================
public with sharing class APIGatewayUtil {

    // AWS credential pair — must be injected via AWSConfig; never hardcode.
    private String ACCESS_KEY;
    private String SECRET_KEY;

    private final String ALGORITHM    = 'AWS4-HMAC-SHA256';
    private final String SERVICE      = 'execute-api';
    private final String CONTENT_TYPE = 'application/x-www-form-urlencoded';

    private String baseUrl;
    private String region;
    private String host;

    // State computed fresh for every request in getRequest().
    private Datetime dt;
    private String   d;         // date component: YYYYMMDD
    private String   timestamp; // full ISO timestamp: YYYYMMDDTHHMMSSZ
    private String   scope;
    private String   canonicalRequest;

    private String requestPath;
    private String method;
    private String content;

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    /**
     * Initialise the utility with a base URL and AWS credentials.
     *
     * @param baseUrl   Full base URL of the API Gateway endpoint
     *                  (e.g. https://abc123.execute-api.us-east-1.amazonaws.com)
     * @param awsConfig Credential and configuration object
     */
    public APIGatewayUtil(String baseUrl, APIGatewayUtil.AWSConfig awsConfig) {
        this.baseUrl    = baseUrl;
        this.region     = awsConfig.awsRegion;
        // Strip the 'https://' scheme — the Host header must be the bare hostname.
        this.host       = baseUrl.substring(8);
        this.ACCESS_KEY = awsConfig.accessKey;
        this.SECRET_KEY = awsConfig.accessSecret;
    }

    // --------------------------------------------------------
    // Public API
    // --------------------------------------------------------
    /**
     * Sign and send an HTTP request to the specified API Gateway function.
     *
     * @param functionName  Lambda/API Gateway resource name
     * @param method        HTTP verb (GET, POST, PATCH, etc.)
     * @param content       URL-encoded request body
     * @param stage         API Gateway stage name (e.g. prod, beta)
     * @return              HttpResponse from the gateway
     */
    public HttpResponse sendRequest(String functionName, String method, String content, String stage) {
        this.requestPath = '/' + stage + '/' + functionName;
        this.method      = method;
        this.content     = content;

        Http http = new Http();
        return http.send(buildRequest());
    }

    // --------------------------------------------------------
    // Private — request assembly
    // --------------------------------------------------------
    /**
     * Build the HttpRequest with all required SigV4 headers.
     */
    private HttpRequest buildRequest() {
        // Capture a single point-in-time so date and timestamp are consistent.
        this.dt        = Datetime.now();
        this.d         = getDate();
        this.timestamp = getTimestamp();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(this.baseUrl + this.requestPath);
        req.setMethod(this.method);
        req.setHeader('Content-Type', this.CONTENT_TYPE);
        req.setHeader('Host',         this.host);
        req.setHeader('X-Amz-Date',   this.timestamp);
        req.setHeader('Authorization', buildAuthHeader());
        req.setBody(this.content);

        return req;
    }

    /**
     * Assemble the AWS Authorization header value.
     * Format: AWS4-HMAC-SHA256 Credential=.../scope, SignedHeaders=..., Signature=...
     */
    private String buildAuthHeader() {
        this.scope          = buildScope();
        this.canonicalRequest = buildCanonicalRequest();

        return this.ALGORITHM
            + ' Credential='    + this.ACCESS_KEY + '/' + this.scope
            + ', SignedHeaders=content-type;host;x-amz-date'
            + ', Signature='    + computeSignature();
    }

    // --------------------------------------------------------
    // Private — SigV4 components
    // --------------------------------------------------------
    /**
     * Credential scope: date/region/service/aws4_request
     */
    private String buildScope() {
        return this.d + '/' + this.region + '/' + this.SERVICE + '/aws4_request';
    }

    /**
     * Canonical request string as defined by the SigV4 specification.
     * Note: the HTTP verb in the canonical request is hardcoded to POST.
     * If other methods are needed this class must be extended.
     */
    private String buildCanonicalRequest() {
        return 'POST\n'
            + this.requestPath + '\n\n'
            + 'content-type:' + this.CONTENT_TYPE + '\n'
            + 'host:'         + this.host          + '\n'
            + 'x-amz-date:'  + this.timestamp      + '\n\n'
            + 'content-type;host;x-amz-date\n'
            + EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA-256', Blob.valueOf(this.content))
              );
    }

    /**
     * String-to-sign: algorithm + timestamp + scope + hashed canonical request.
     */
    private Blob buildStringToSign() {
        String stringToSign = this.ALGORITHM + '\n'
            + this.timestamp  + '\n'
            + this.scope      + '\n'
            + EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA-256', Blob.valueOf(this.canonicalRequest))
              );
        return Blob.valueOf(stringToSign);
    }

    /**
     * Derive the SigV4 signing key via four nested HMAC-SHA256 operations:
     *   kSigning = HMAC(HMAC(HMAC(HMAC("AWS4"+secret, date), region), service), "aws4_request")
     */
    private Blob deriveSigningKey() {
        Blob kDate    = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.d),          Blob.valueOf('AWS4' + this.SECRET_KEY));
        Blob kRegion  = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.region),     kDate);
        Blob kService = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.SERVICE),    kRegion);
        Blob kSigning = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'),  kService);
        return kSigning;
    }

    /**
     * Compute the hex-encoded request signature.
     */
    private String computeSignature() {
        return EncodingUtil.convertToHex(
            Crypto.generateMac('hmacSHA256', buildStringToSign(), deriveSigningKey())
        );
    }

    // --------------------------------------------------------
    // Private — date/time helpers
    // --------------------------------------------------------
    /**
     * Return the UTC date as YYYYMMDD.
     */
    private String getDate() {
        return pad(this.dt.yearGmt())
             + pad(this.dt.monthGmt())
             + pad(this.dt.dayGmt());
    }

    /**
     * Return the UTC timestamp as YYYYMMDDTHHMMSSZ.
     */
    private String getTimestamp() {
        return pad(this.dt.yearGmt())
             + pad(this.dt.monthGmt())
             + pad(this.dt.dayGmt())   + 'T'
             + pad(this.dt.hourGmt())
             + pad(this.dt.minuteGmt())
             + pad(this.dt.secondGmt()) + 'Z';
    }

    /**
     * Zero-pad a single-digit integer (e.g. 9 → '09').
     */
    private String pad(Integer n) {
        String s = String.valueOf(n);
        return s.length() == 1 ? '0' + s : s;
    }

    // --------------------------------------------------------
    // Inner class — configuration
    // --------------------------------------------------------
    public class AWSConfig {
        public String accessKey;
        public String accessSecret;
        public String awsHost;
        public String awsRegion;
        public String awsServiceName;
        public String functionName;
        public String stageName;
        public String apiMethod;
    }
}
