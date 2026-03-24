@isTest
private class GPTResponseTest {

    @isTest
    static void testGPTResponseParsing() {
        // Sample JSON for testing
        String sampleJson = '{"id": "123", "object": "Test", "created": 123456, "model": "SampleModel", "usage": {"prompt_tokens": 5, "completion_tokens": 10, "total_tokens": 15}, "choices": [{"message": {"role": "User", "content": "Hello"}, "finish_reason": "Completed", "index": 1}]}';

        // Perform parsing
        GPTResponse response = GPTResponse.parse(sampleJson);

        // Validate the parsed values
        System.assertEquals('123', response.id);
        System.assertEquals('Test', response.object_Z);
        System.assertEquals(123456, response.created);
        System.assertEquals('SampleModel', response.model);

        // Validate Usage
        System.assertEquals(5, response.usage.prompt_tokens);
        System.assertEquals(10, response.usage.completion_tokens);
        System.assertEquals(15, response.usage.total_tokens);

        // Validate Choices
        System.assertEquals(1, response.choices.size());
        GPTResponse.Choices choice = response.choices[0];
        System.assertEquals('User', choice.message.role);
        System.assertEquals('Hello', choice.message.content);
        System.assertEquals('Completed', choice.finish_reason);
        System.assertEquals(1, choice.index);
    }
}