/***
* Author: Shankar Dupade (FieldKo)
* Updated : 4th Apr 2024
* Purpose: Scheduler class Class for GPTProcessCallTranscStagesBatch
*/  
global with sharing class GPTProcessCallTranscStagesBatchScheduler implements Schedulable{
	private Integer batchSize = 1;
	private String str = '';

	global GPTProcessCallTranscStagesBatchScheduler() {
		if(Test.isRunningTest()) {
			str = 'Test ';
		}
	}

	global void setBatchSize(Integer batchSize) {
		this.batchSize = batchSize;
	}

	global void scheduleEvery5Mins() {
		String sch = '0 2 * * * ?';
        
		GPTProcessCallTranscStagesBatchScheduler mis = new GPTProcessCallTranscStagesBatchScheduler();
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 2th  min', sch, mis);

		sch = '0 7 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 7th  min', sch, mis);

		sch = '0 12 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 12th  min', sch, mis);

		sch = '0 17 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 17th  min', sch, mis);

		sch = '0 22 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 22th  min', sch, mis);

		sch = '0 27 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 27th  min', sch, mis);

		sch = '0 32 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 32th  min', sch, mis);

		sch = '0 37 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 37yh  min', sch, mis);

		sch = '0 42 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 42th  min', sch, mis);

		sch = '0 47 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 47th  min', sch, mis);

		sch = '0 52 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 52th  min', sch, mis);

		sch = '0 57 * * * ?';
		System.schedule(str + 'Run Queued Call Transcription Batch with stages Every 57th  min', sch, mis);
	}
	
	global void execute(SchedulableContext sc) {
		GPTProcessCallTranscriptionStagesBatch miBatch = new GPTProcessCallTranscriptionStagesBatch();
		database.executebatch(miBatch, batchSize);
	}
}