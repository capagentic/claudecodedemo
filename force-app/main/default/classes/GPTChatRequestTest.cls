/**
 * Auther: Shankar Dupade
 * Purpose: test classes for GPTChatRequest
 * Date: 07-Mar-2024
 */
@isTest
public with sharing class GPTChatRequestTest {
   
    @isTest
    static void testParseMethod() {
        // Define a JSON string that matches the structure expected by GPTChatRequest
        String json = '{' +
            '"temperature": 0.7,' +
            '"messages": [' +
                '{' +
                    '"content": "Hello, world!",' +
                    '"role": "user"' +
                '},' +
                '{' +
                    '"content": "How can I assist you today?",' +
                    '"role": "assistant"' +
                '}' +
            '],' +
            '"model": "text-davinci-003"' +
        '}';

        // Call the parse method to deserialize the JSON string
        GPTChatRequest result = GPTChatRequest.parse(json);

        // Perform assertions to verify the JSON was correctly deserialized
        System.assertNotEquals(null, result, 'The result should not be null');
    }
}