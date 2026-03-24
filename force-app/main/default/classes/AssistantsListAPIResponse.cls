/**
 * Author: Shankar Dupade
 * Date: 13-2-2024
 * Purpose: response wrapper class
 */

public class AssistantsListAPIResponse {

	public class Tools {
		public String type {get;set;} 

		public Tools(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'type') {
							type = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Tools consuming unrecognized property: '+text);
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

	public AssistantsListAPIResponse(JSONParser parser) {
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
						System.debug(LoggingLevel.WARN, 'AssistantsListAPIResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Data {
		public String id {get;set;} 
		public String object_Z {get;set;} // in json: object
		public Integer created_at {get;set;} 
		public String name {get;set;} 
		public Object description {get;set;} 
		public String model {get;set;} 
		public String instructions {get;set;} 
		public List<Tools> tools {get;set;} 
		public List<String> file_ids {get;set;} 
		public File_ids metadata {get;set;} 

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
						} else if (text == 'name') {
							name = parser.getText();
						} else if (text == 'description') {
							description = parser.readValueAs(Object.class);
						} else if (text == 'model') {
							model = parser.getText();
						} else if (text == 'instructions') {
							instructions = parser.getText();
						} else if (text == 'tools') {
							tools = arrayOfTools(parser);
						} else if (text == 'file_ids') {
							file_ids = arrayOfString(parser);
						} else if (text == 'metadata') {
							metadata = new File_ids(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class File_ids {

		public File_ids(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						{
							System.debug(LoggingLevel.WARN, 'File_ids consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static AssistantsListAPIResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new AssistantsListAPIResponse(parser);
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
	

    private static List<Data> arrayOfData(System.JSONParser p) {
        List<Data> res = new List<Data>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Data(p));
        }
        return res;
    }



    private static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(p.getText());
        }
        return res;
    }





    private static List<File_ids> arrayOfFile_ids(System.JSONParser p) {
        List<File_ids> res = new List<File_ids>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new File_ids(p));
        }
        return res;
    }





    private static List<Tools> arrayOfTools(System.JSONParser p) {
        List<Tools> res = new List<Tools>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Tools(p));
        }
        return res;
    }




}