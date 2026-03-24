/**
* Author: Shankar Dupade(FieldKo)
* Updated : 07th March 2024
* Purpose: Test Class for creating parser AssistantAPIResponse
 */

@isTest
public with sharing class AssistantAPIResponseTest {

    // Utility method to generate test JSON
    private static String generateTestJson() {
        return '{' +
            '"object": "exampleObject",'+
            '"data": [' +
                '{' +
                    '"id": "1",' +
                    '"object": "exampleDataObject",' +
                    '"created_at": 123,' +
                    '"thread_id": "thread1",' +
                    '"role": "admin",' +
                    '"content": [ { "type":"text", "text" : {"value": "text value", "annotations": []}}],' +
                    '"file_ids": [],' +
                    '"assistant_id": "assistant1",' +
                    '"run_id": "run1",' +
                    '"metadata": {}' +
                '}' +
            '],'+
            '"first_id": "first1",'+
            '"last_id": "last1",'+
            '"has_more": true' +
        '}';
    }
    
    @isTest
    static void testParse() {
        // Generate test JSON
        String json = generateTestJson();
        
        // Parse the JSON
        AssistantAPIResponse parsedResponse = AssistantAPIResponse.parse(json);
        
        // Assertions to verify parsing results
        System.assertEquals('exampleObject', parsedResponse.object_Z);
        System.assertEquals(1, parsedResponse.data.size());
        System.assertEquals('first1', parsedResponse.first_id);
        System.assertEquals('last1', parsedResponse.last_id);
        System.assertEquals(true, parsedResponse.has_more);

        // Test the contents of the 'data' array
        AssistantAPIResponse.Data firstDataItem = parsedResponse.data[0];
        System.assertEquals('1', firstDataItem.id);
        System.assertEquals('exampleDataObject', firstDataItem.object_Z);
        System.assertEquals(123, firstDataItem.created_at);
    }
}