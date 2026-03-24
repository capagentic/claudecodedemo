public class RecallGetMeetingRes {

	public class Attendees {
		public Object name;
		public String email;
		public Boolean is_organizer;
		public String status;
	}

	public String id;
	public Object override_should_record;
	public String title;
	public Boolean will_record;
	public String will_record_reason;
	public String start_time;
	public String end_time;
	public String platform;
	public String meeting_platform;
	public String calendar_platform;
	public Object zoom_invite;
	public Object teams_invite;
	public Meet_invite meet_invite;
	public Object webex_invite;
	public String bot_id;
	public Boolean is_external;
	public Boolean is_hosted_by_me;
	public Boolean is_recurring;
	public String organizer_email;
	public List<String> attendee_emails;
	public List<Attendees> attendees;
	public String ical_uid;
	public Object visibility;

	public class Meet_invite {
		public String meeting_id;
	}

	
	public static RecallGetMeetingRes parse(String json) {
		return (RecallGetMeetingRes) System.JSON.deserialize(json, RecallGetMeetingRes.class);
	}
}