global with sharing class FileAttachmentWrapper {
	global Id linkedRecordId {get; set;}
	global List<ContentVersion> contentVersionRecords {get; set;}
	global List<Attachment> attachmentRecords {get; set;}

	global FileAttachmentWrapper() {}
	
	global FileAttachmentWrapper(Id linkedRecordId,List<ContentVersion> contentVersionRecords,List<Attachment> attachmentRecords) {
		this.linkedRecordId = linkedRecordId;
		this.contentVersionRecords = new List<ContentVersion>(contentVersionRecords);
		this.attachmentRecords = new List<Attachment>(attachmentRecords);
	}
	
}