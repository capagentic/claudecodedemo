/**
 * Auther: Shankar Dupade
 * Purpose: test classes for GPTRecommendationResponse
 * Date: 07-Mar-2024
 */
@isTest
public with sharing class GPTRecommendationResponseTest {
    @isTest
    static void testParse() {
        // Create a sample JSON string that matches the structure of GPTRecommendationResponse
        String json = '{' +
                      '"summary_title":"Sample Summary Title",' +
                      '"detailed_analysis":"Sample Detailed Analysis",' +
                      '"summary":"Sample Summary",' +
                      '"recommendations":[{"subject":"Sample Subject","priority":"High","description":"Sample Description"}],' +
                      '"additional_resources":[{"description":"Sample Resource Description","link_to_online_resource":"http://example.com"}],' +
                      '"interesting_summary":[{"description":"Sample Interesting Summary"}]' +
                      '}';
                      
        // Parse the JSON string into an instance of GPTRecommendationResponse
        GPTRecommendationResponse response = GPTRecommendationResponse.parse(json);
        
        // Assert that the parsed object matches the expected values
        System.assertEquals('Sample Summary Title', response.summary_title);
        System.assertEquals('Sample Detailed Analysis', response.detailed_analysis);
        System.assertEquals('Sample Summary', response.summary);
        
        // Assert on the size of the lists to ensure they were populated
        System.assertEquals(1, response.recommendations.size());
        System.assertEquals(1, response.additional_resources.size());
        System.assertEquals(1, response.interesting_summary.size());
        
        // Assert on a couple of detailed properties to ensure correct parsing
        System.assertEquals('Sample Subject', response.recommendations[0].subject);
        System.assertEquals('High', response.recommendations[0].priority);
        System.assertEquals('Sample Description', response.recommendations[0].description);
        
        System.assertEquals('Sample Resource Description', response.additional_resources[0].description);
        System.assertEquals('http://example.com', response.additional_resources[0].link_to_online_resource);
        
        System.assertEquals('Sample Interesting Summary', response.interesting_summary[0].description);
    }
}