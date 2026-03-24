public class RecallBotChangeResponse {

	public class Status {
		public String code;
		public String created_at;
		public String message;
		public String sub_code;
	}

	public class Data {
		public String bot_id;
		public Status status;
	}

	public Data data;
	public String event;

	
	public static RecallBotChangeResponse parse(String json) {
		return (RecallBotChangeResponse) System.JSON.deserialize(json, RecallBotChangeResponse.class);
	}
}