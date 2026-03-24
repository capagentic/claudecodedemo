public class RecallRetrieveBotResponse {

	public class Meeting_participants {
		public Integer id;
		public String name;
		public List<Events> events;
		public Boolean is_host;
		public String platform;
		public Extra_data extra_data;
	}

	public String id;
	public String video_url;
	public String media_retention_end;
	public List<Status_changes> status_changes;
	public Meeting_metadata meeting_metadata;
	public List<Meeting_participants> meeting_participants;
	public Meeting_url meeting_url;
	public String join_at;
	public List<Calendar_meetings> calendar_meetings;
	public String recording;
	public List<Recordings> recordings;

	public class Meeting_metadata {
		public String title;
		public String zoom_meeting_uuid;
	}

	public class Extra_data {
		public Microsoft_teams microsoft_teams;
		public Zoom zoom;
	}

	public class Events {
		public String code;
		public String created_at;
	}

	public class Status_changes {
		public String code;
		public String message;
		public String created_at;
		public String sub_code;
	}

	public class Calendar_meetings {
		public String id;
		public String start_time;
		public String end_time;
		public Calendar_user calendar_user;
	}

	public class Recordings {
		public String id;
		public String started_at;
		public String completed_at;
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

	public class Calendar_user {
		public String id;
		public String external_id;
	}

	public class Microsoft_teams {
		public String role;
		public String user_id;
		public String tenant_id;
		public String meeting_role;
		public String client_version;
		public String participant_type;
	}

	public class Zoom {
		public Integer os;
		public Boolean guest;
		public String user_guid;
		public String conf_user_id;
	}

	
	public static RecallRetrieveBotResponse parse(String json) {
		return (RecallRetrieveBotResponse) System.JSON.deserialize(json, RecallRetrieveBotResponse.class);
	}
}