/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable{

    Private static final Integer MAX_JOBS = 10;
    // Define the number of accounts to process at a time
    Private static final Integer BATCH_SIZE = 10;

    // This is a list that will hold the accounts we want to update
    private List<Account> accounts;

    // This is the constructor. It sets up the list of accounts when a new instance of the class is created.
    public NextStepQueueable(List<Account> accounts) {
		this.accounts = accounts;
    }

    // This method is used to start the job. It gets the accounts and then adds the job to the queue.
    public static void enqueueJob() {

        // Get all accounts where the Next Step field is not empty
        List<Account> accounts = [SELECT Id, Next_Step__c FROM Account WHERE Next_Step__c != null];
        
        // If there are accounts, add a new job to the queue
        if (!accounts.isEmpty()) {
            System.enqueueJob(new NextStepQueueable(accounts));
        }
    }

    // This method is called when the job starts. It processes the accounts in batches.
    public void execute(QueueableContext context) {
        
        // Keep processing accounts until there are none left
        while (!accounts.isEmpty()) {
            // Get a batch of accounts to update
            List<Account> accountsToUpdate = getBatch(accounts, BATCH_SIZE);
            // Remove the accounts we're updating from the main list
            accounts = removeBatch(accounts, BATCH_SIZE);

            // Update each account in the batch
            for (Account acc : accountsToUpdate) {
                removeNextStep(acc);
            }
            update accountsToUpdate;

            // Get and update the opportunities related to the accounts
            List<Opportunity> opps = [SELECT Id, Name, NextStep FROM Opportunity WHERE AccountId IN :accountsToUpdate];
            for (Opportunity opp : opps) {
                removeNextStep(opp);
            }
            update opps;
        }

        // If there are still accounts left to process, add another job to the queue
        if (!accounts.isEmpty() && AsyncInfo.getCurrentQueueableStackDepth() < MAX_JOBS) {
            NextStepQueueable.enqueueJob();
        }
    }

    // This method gets a batch of accounts to update
    private static List<Account> getBatch(List<Account> accounts, Integer batchSize) {

        List<Account> batch = new List<Account>();
        for (Integer i = 0; i < batchSize && i < accounts.size(); i++) {
            batch.add(accounts[i]);
        }
        return batch;
    }

    // This method removes a batch of accounts from the main list
    private static List<Account> removeBatch(List<Account> accounts, Integer batchSize) {

        List<Account> remaining = new List<Account>();
        for (Integer i = batchSize; i < accounts.size(); i++) {
            remaining.add(accounts[i]);
        }
        return remaining;
    }

    // These methods remove the Next Step field from an account or opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}