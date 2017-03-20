public with sharing class LatchConnection {
    final private static String LATCH_URL = 'https://latch.elevenpaths.com';
    final private String appId;
    final private String secret;
    
    public LatchConnection(String appId, String secret) {
        System.assert(appId != null && appId.trim() != '', 'Application Id cannot be null or empty');
        System.assert(secret != null && secret.trim() != '', 'Secret cannot be null or empty');
        
        this.appId = appId;
        this.secret = secret;
    }
    
    public String get(String url) {
        String nowUtc = DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        String signedAuthTokenPayload = createSignedAuthTokenPayload(url, nowUtc);
        
        System.HttpRequest request = new System.HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', '11PATHS ' + appId +
        	' ' + signedAuthTokenPayload);
        request.setHeader('X-11paths-Date', nowUtc);
        request.setEndpoint(LATCH_URL + url);
        
        System.HttpResponse res = new System.Http().send(request);
        
        return res.getBody();
    }
    
    private String createSignedAuthTokenPayload(String url, String utc) {
        String clearAuthTokenPayload = 'GET\n' + utc + '\n\n' + url;
        Blob blobSignedData = Crypto.generateMac('HMacSHA1', Blob.valueOf(clearAuthTokenPayload), Blob.valueOf(secret));
 
        return EncodingUtil.base64Encode(blobSignedData);
    }
}