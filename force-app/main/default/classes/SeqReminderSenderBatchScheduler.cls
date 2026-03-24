/***
* Author: Shankar Dupade (FieldKo)
* Updated : 4th Aug 2021
* Purpose: Scheduler class Class for sending auto reminders of Survey Invitation
*/  
global with sharing class SeqReminderSenderBatchScheduler implements Schedulable{
	private Integer batchSize = 100;
	private String str = '';

	global SeqReminderSenderBatchScheduler() {
		if(Test.isRunningTest()) {
			str = 'Test ';
		}
	}

	global void setBatchSize(Integer batchSize) {
		this.batchSize = batchSize;
	}

	// global void scheduleEvery5Mins() {
	// 	String sch = '0 0 * * * ?';
        
	// 	VisitSummaryPdfSchedular mis = new VisitSummaryPdfSchedular();
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 0th  min', sch, mis);

	// 	sch = '0 5 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 5th  min', sch, mis);

	// 	sch = '0 10 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 10th  min', sch, mis);

	// 	sch = '0 15 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 15th  min', sch, mis);

	// 	sch = '0 20 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 20th  min', sch, mis);

	// 	sch = '0 25 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 25th  min', sch, mis);

	// 	sch = '0 30 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 30th  min', sch, mis);

	// 	sch = '0 35 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 35th  min', sch, mis);

	// 	sch = '0 40 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 40th  min', sch, mis);

	// 	sch = '0 45 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 45th  min', sch, mis);

	// 	sch = '0 50 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 50th  min', sch, mis);

	// 	sch = '0 55 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 55th  min', sch, mis);
	// }
	
	// global void scheduleEvery15Mins() {
	// 	String sch = '0 0 * * * ?';
        
    //     if(Test.isRunningTest()) {
	// 		str = '15 ';
	// 	}

	// 	VisitSummaryPdfSchedular mis = new VisitSummaryPdfSchedular();
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 0th Mins', sch, mis);

	// 	sch = '0 15 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Batch Every 15th Mins', sch, mis);

	// 	sch = '0 30 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Batch Every 30th Mins', sch, mis);

	// 	sch = '0 45 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Batch Every 45th Mins', sch, mis);
	// }

	// global void scheduleEvery30Mins() {
	// 	String sch = '0 0 * * * ?';
        
    //     if(Test.isRunningTest()) {
	// 		str = '30 ';
	// 	}

	// 	VisitSummaryPdfSchedular mis = new VisitSummaryPdfSchedular();
	// 	System.schedule(str + 'Run Visit Summary Pdf Every 0th Mins', sch, mis);

	// 	sch = '0 30 * * * ?';
	// 	System.schedule(str + 'Run Visit Summary Pdf Batch Every 30th Mins', sch, mis);
		
	// }

	// global void scheduleEveryHr() {
	// 	String sch = '0 0 * * * ?';

	// 	VisitSummaryPdfSchedular mis = new VisitSummaryPdfSchedular();
	// 	System.schedule(str + 'Run Visit Summary Pdf Batch Every hr', sch, mis);
	// }

	global void execute(SchedulableContext sc) {
		SeqReminderSenderBatch miBatch = new SeqReminderSenderBatch();
		database.executebatch(miBatch, batchSize);
	}
}