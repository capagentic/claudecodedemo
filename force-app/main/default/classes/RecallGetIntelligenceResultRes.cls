public class RecallGetIntelligenceResultRes {

	public class Content_safety_labels {
		public String status;
		public List<Results> results;
		public Results summary;
	}

	public class Results {
	}

	public Content_safety_labels content_safety_labels;
	public Content_safety_labels iab_categories_result;
	public String summary;
	public String language_code;
	public String id;

	
	public static RecallGetIntelligenceResultRes parse(String json) {
		return (RecallGetIntelligenceResultRes) System.JSON.deserialize(json, RecallGetIntelligenceResultRes.class);
	}
}