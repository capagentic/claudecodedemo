public class GPTResponse {

	public class Usage {
		public Integer prompt_tokens {get;set;} 
		public Integer completion_tokens {get;set;} 
		public Integer total_tokens {get;set;} 

		public Usage(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'prompt_tokens') {
							prompt_tokens = parser.getIntegerValue();
						} else if (text == 'completion_tokens') {
							completion_tokens = parser.getIntegerValue();
						} else if (text == 'total_tokens') {
							total_tokens = parser.getIntegerValue();
						} else {
							System.debug(LoggingLevel.WARN, 'Usage consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Message {
		public String role {get;set;} 
		public String content {get;set;} 

		public Message(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'role') {
							role = parser.getText();
						} else if (text == 'content') {
							content = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Message consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Choices {
		public Message message {get;set;} 
		public String finish_reason {get;set;} 
		public Integer index {get;set;} 

		public Choices(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'message') {
							message = new Message(parser);
						} else if (text == 'finish_reason') {
							finish_reason = parser.getText();
						} else if (text == 'index') {
							index = parser.getIntegerValue();
						} else {
							System.debug(LoggingLevel.WARN, 'Choices consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String id {get;set;} 
	public String object_Z {get;set;} // in json: object
	public Integer created {get;set;} 
	public String model {get;set;} 
	public Usage usage {get;set;} 
	public List<Choices> choices {get;set;} 

	public GPTResponse(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'id') {
						id = parser.getText();
					} else if (text == 'object') {
						object_Z = parser.getText();
					} else if (text == 'created') {
						created = parser.getIntegerValue();
					} else if (text == 'model') {
						model = parser.getText();
					} else if (text == 'usage') {
						usage = new Usage(parser);
					} else if (text == 'choices') {
						choices = arrayOfChoices(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'GPTResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	
	public static GPTResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new GPTResponse(parser);
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
	





    private static List<Choices> arrayOfChoices(System.JSONParser p) {
        List<Choices> res = new List<Choices>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Choices(p));
        }
        return res;
    }



}