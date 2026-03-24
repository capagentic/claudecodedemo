// The supplied json has fields with names that are not valid in apex
// and so can only be parsed with explicitly generated code, this option
// was auto selected for you.
/**
 * 
 * 
 */
public class AssistantAPIResponse {

	public class Annotations {

		public Annotations(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						{
							System.debug(LoggingLevel.WARN, 'Annotations consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String object_Z {get;set;} // in json: object
	public List<Data> data {get;set;} 
	public String first_id {get;set;} 
	public String last_id {get;set;} 
	public Boolean has_more {get;set;} 

	public AssistantAPIResponse(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'object') {
						object_Z = parser.getText();
					} else if (text == 'data') {
						data = arrayOfData(parser);
					} else if (text == 'first_id') {
						first_id = parser.getText();
					} else if (text == 'last_id') {
						last_id = parser.getText();
					} else if (text == 'has_more') {
						has_more = parser.getBooleanValue();
					} else {
						System.debug(LoggingLevel.WARN, 'AssistantAPIResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Content {
		public String type {get;set;} 
		public Text text {get;set;} 

		public Content(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String textvalue = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (textvalue == 'type') {
							type = parser.getText();
						} else if (textvalue == 'text') {
							text = new Text(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Content consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Text {
		public String value {get;set;} 
		public List<Annotations> annotations {get;set;} 

		public Text(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'value') {
							value = parser.getText();
						} else if (text == 'annotations') {
							annotations = arrayOfAnnotations(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Text consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Data {
		public String id {get;set;} 
		public String object_Z {get;set;} // in json: object
		public Integer created_at {get;set;} 
		public String thread_id {get;set;} 
		public String role {get;set;} 
		public List<Content> content {get;set;} 
		public List<Annotations> file_ids {get;set;} 
		public String assistant_id {get;set;} 
		public String run_id {get;set;} 
		public Annotations metadata {get;set;} 

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'id') {
							id = parser.getText();
						} else if (text == 'object') {
							object_Z = parser.getText();
						} else if (text == 'created_at') {
							created_at = parser.getIntegerValue();
						} else if (text == 'thread_id') {
							thread_id = parser.getText();
						} else if (text == 'role') {
							role = parser.getText();
						} else if (text == 'content') {
							content = arrayOfContent(parser);
						} else if (text == 'file_ids') {
							file_ids = arrayOfAnnotations(parser);
						} else if (text == 'assistant_id') {
							assistant_id = parser.getText();
						} else if (text == 'run_id') {
							run_id = parser.getText();
						} else if (text == 'metadata') {
							metadata = new Annotations(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static AssistantAPIResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new AssistantAPIResponse(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

    private static List<Annotations> arrayOfAnnotations(System.JSONParser p) {
        List<Annotations> res = new List<Annotations>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Annotations(p));
        }
        return res;
    }


    private static List<Content> arrayOfContent(System.JSONParser p) {
        List<Content> res = new List<Content>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Content(p));
        }
        return res;
    }

    private static List<Data> arrayOfData(System.JSONParser p) {
        List<Data> res = new List<Data>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Data(p));
        }
        return res;
    }
}