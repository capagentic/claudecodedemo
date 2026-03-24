public class GPTRecommendationResponse {

	public class Recommendation {
		public String subject;
		public String priority;
		public String description;
	}

	public String summary_title;
	public String detailed_analysis;
	public String summary;
	public List<Recommendation> recommendations;
	public List<Additional_resources> additional_resources;
	public List<Interesting_summary> interesting_summary;

	public class Additional_resources {
		public String description;
		public String link_to_online_resource;
	}

	public class Interesting_summary {
		public String description;
	}

	
	public static GPTRecommendationResponse parse(String json) {
		return (GPTRecommendationResponse) System.JSON.deserialize(json, GPTRecommendationResponse.class);
	}
}