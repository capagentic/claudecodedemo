/***
* Author: Shankar Dupade (FieldKo)
* Updated : 7th Feb 2024
* Purpose: Scheduler class Class for ProcessQueuedCallTranscriptionBatch
*/  
global with sharing class ProcessQdCallTranscriptionBatchScheduler implements Schedulable{
	private Integer batchSize = 1;
	private String str = '';

	global ProcessQdCallTranscriptionBatchScheduler() {
		if(Test.isRunningTest()) {
			str = 'Test ';
		}
	}

	global void setBatchSize(Integer batchSize) {
		this.batchSize = batchSize;
	}

	global void scheduleEvery5Mins() {
		String sch = '0 0 * * * ?';
        
		ProcessQdCallTranscriptionBatchScheduler mis = new ProcessQdCallTranscriptionBatchScheduler();
		System.schedule(str + 'Run Queued Call Transcription Batch Every 0th  min', sch, mis);

		sch = '0 5 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 5th  min', sch, mis);

		sch = '0 10 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 10th  min', sch, mis);

		sch = '0 15 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 15th  min', sch, mis);

		sch = '0 20 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 20th  min', sch, mis);

		sch = '0 25 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 25th  min', sch, mis);

		sch = '0 30 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 30th  min', sch, mis);

		sch = '0 35 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 35th  min', sch, mis);

		sch = '0 40 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 40th  min', sch, mis);

		sch = '0 45 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 45th  min', sch, mis);

		sch = '0 50 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 50th  min', sch, mis);

		sch = '0 55 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch Every 55th  min', sch, mis);
	}
	
	// global void scheduleEvery15Mins() {
	// 	String sch = '0 0 * * * ?';
        
    //     if(Test.isRunningTest()) {
	// 		str = '15 ';
	// 	}

	// 	ProcessQdCallTranscriptionBatchScheduler mis = new ProcessQdCallTranscriptionBatchScheduler();
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Every 0th Mins', sch, mis);

	// 	sch = '0 15 * * * ?';
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Batch Every 15th Mins', sch, mis);

	// 	sch = '0 30 * * * ?';
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Batch Every 30th Mins', sch, mis);

	// 	sch = '0 45 * * * ?';
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Batch Every 45th Mins', sch, mis);
	// }

	// global void scheduleEvery30Mins() {
	// 	String sch = '0 0 * * * ?';
        
    //     if(Test.isRunningTest()) {
	// 		str = '30 ';
	// 	}

	// 	ProcessQdCallTranscriptionBatchScheduler mis = new ProcessQdCallTranscriptionBatchScheduler();
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Every 0th Mins', sch, mis);

	// 	sch = '0 30 * * * ?';
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Batch Every 30th Mins', sch, mis);
		
	// }

	// global void scheduleEveryHr() {
	// 	String sch = '0 0 * * * ?';

	// 	ProcessQdCallTranscriptionBatchScheduler mis = new ProcessQdCallTranscriptionBatchScheduler();
	// 	System.schedule(str + 'Run Queued Call Transcription Batch Batch Every hr', sch, mis);
	// }

	global void execute(SchedulableContext sc) {
		ProcessQueuedCallTranscriptionBatch miBatch = new ProcessQueuedCallTranscriptionBatch();
		database.executebatch(miBatch, batchSize);
	}
}