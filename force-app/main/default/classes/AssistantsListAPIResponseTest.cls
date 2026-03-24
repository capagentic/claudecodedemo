/**
* Author: Shankar Dupade(FieldKo)
* Updated : 07th March 2024
* Purpose: Test Class for creating parser AssistantsListAPIResponse
 */
@IsTest
public class AssistantsListAPIResponseTest {
	
	// This test method should give 100% coverage
	static testMethod void testParse() {
		String json = '{\"object\":\"list\",\"data\":[{\"id\":\"asst_ISPrGykh4i9vZjXGFcPCtyOB\",\"object\":\"assistant\",\"created_at\":1706672823,\"name\":\"Creating test assistant from SF\",\"description\":null,\"model\":\"gpt-4-turbo-preview\",\"instructions\":\"You are a helpful assistant that helps the new franchise management team assess individuals applying to operate new franchises. The objective of the call is to qualify the applicants ability to successfully operate the franchise store\",\"tools\":[{\"type\":\"code_interpreter\"}],\"file_ids\":[],\"metadata\":{}},{\"id\":\"asst_prpPYldClZZikQNXV0JC8dXK\",\"object\":\"assistant\",\"created_at\":1706415776,\"name\":\"Franchise Leads Assistant\",\"description\":null,\"model\":\"gpt-4-turbo-preview\",\"instructions\":\"You are a recruitment specialist conducting a reference check on a candidate\",\"tools\":[],\"file_ids\":[],\"metadata\":{}},{\"id\":\"asst_DotBWLmRMMJkOGNWsTItqrgg\",\"object\":\"assistant\",\"created_at\":1706227180,\"name\":\"Assistant API assistant\",\"description\":null,\"model\":\"gpt-4-turbo-preview\",\"instructions\":\"You are a helpful assistant to assist a developer working the Assistant API\",\"tools\":[],\"file_ids\":[],\"metadata\":{}},{\"id\":\"asst_YHEmOMJLNPlcVoFPIixcY9x0\",\"object\":\"assistant\",\"created_at\":1700728613,\"name\":\"Aged Care\",\"description\":null,\"model\":\"gpt-4-1106-preview\",\"instructions\":\"You are an expert in helping aged care workers in Australia deliver services that exceed the quality standards set out by regulatory polices\",\"tools\":[{\"type\":\"retrieval\"}],\"file_ids\":[\"file-Q7oVuVLvs0Nulx2seDOUJrFE\",\"file-j54gLLMxRZ7OJN6CEcnZDADR\",\"file-R0w5BrRdEWEeGOg0cH8rDjk5\"],\"metadata\":{}}],\"first_id\":\"asst_ISPrGykh4i9vZjXGFcPCtyOB\",\"last_id\":\"asst_YHEmOMJLNPlcVoFPIixcY9x0\",\"has_more\":false}';
		AssistantsListAPIResponse r = AssistantsListAPIResponse.parse(json);
		System.assert(r != null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		AssistantsListAPIResponse.Tools objTools = new AssistantsListAPIResponse.Tools(System.JSON.createParser(json));
		System.assert(objTools != null);
		System.assert(objTools.type == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		AssistantsListAPIResponse objAssistantsListAPIResponse = new AssistantsListAPIResponse(System.JSON.createParser(json));
		System.assert(objAssistantsListAPIResponse != null);
		System.assert(objAssistantsListAPIResponse.object_Z == null);
		System.assert(objAssistantsListAPIResponse.data == null);
		System.assert(objAssistantsListAPIResponse.first_id == null);
		System.assert(objAssistantsListAPIResponse.last_id == null);
		System.assert(objAssistantsListAPIResponse.has_more == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		AssistantsListAPIResponse.Data objData = new AssistantsListAPIResponse.Data(System.JSON.createParser(json));
		System.assert(objData != null);
		System.assert(objData.id == null);
		System.assert(objData.object_Z == null);
		System.assert(objData.created_at == null);
		System.assert(objData.name == null);
		System.assert(objData.description == null);
		System.assert(objData.model == null);
		System.assert(objData.instructions == null);
		System.assert(objData.tools == null);
		System.assert(objData.file_ids == null);
		System.assert(objData.metadata == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		AssistantsListAPIResponse.File_ids objFile_ids = new AssistantsListAPIResponse.File_ids(System.JSON.createParser(json));
		System.assert(objFile_ids != null);
	}
}