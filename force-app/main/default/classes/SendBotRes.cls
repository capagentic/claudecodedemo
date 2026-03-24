public class SendBotRes {

	public class Meeting_participants {
	}

	public String id;
	public String video_url;
	public List<Status_changes> status_changes;
	public String meeting_metadata;
	public List<Meeting_participants> meeting_participants;
	public Meeting_url meeting_url;
	public String join_at;
	public List<Meeting_participants> calendar_meetings;
	public String recording;
	public List<Meeting_participants> recordings;

	public class Status_changes {
		public String code;
		public String message;
		public String created_at;
		public String sub_code;
	}

	public class Meeting_url {
		public String meeting_id;
		public String platform;
		public String meeting_password;
		public String message_id;
		public String organizer_id;
		public String tenant_id;
		public String thread_id;
		public String tk;
	}

	
	public static SendBotRes parse(String json) {
		return (SendBotRes) System.JSON.deserialize(json, SendBotRes.class);
	}
}