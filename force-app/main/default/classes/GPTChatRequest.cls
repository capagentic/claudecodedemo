public class GPTChatRequest {

	public Double temperature;
	public List<Messages> messages;
	public String model;

	public class Messages {
		public String content;
		public String role;
	}

	
	public static GPTChatRequest parse(String json) {
		return (GPTChatRequest) System.JSON.deserialize(json, GPTChatRequest.class);
	}
}