/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    @future
    public static void updateAccountAndOpportunityNextStep() {

        final String FUTURE_NEXT_STEP = 'Meeting in the future';

        List<Account> accounts = [SELECT Id, Next_Step__c FROM Account];

        // Update the Next_Step__c field on each record in the batch scope.
        updateAccountNextStep(accounts, FUTURE_NEXT_STEP);

        List<Opportunity> relatedOpportunities = [SELECT Id, Name, NextStep FROM Opportunity WHERE AccountId IN :accounts];

        // Query for all opportunities related to the accounts in this batch scope
        // Update the NextStep field on each record in the batch scope.
        updateOpportunityNextStep(relatedOpportunities, FUTURE_NEXT_STEP);

    }  

    // Helper method to update Account Next_Step__c
    private static void updateAccountNextStep(List<Account> accts, String nextStep) {

        // Update the Next_Step__c field on each record in the batch scope.
        for(Account acc : accts){
            acc.Next_Step__c = nextStep;
            //relatedOpportunities.addAll([SELECT Id, Name, NextStep FROM Opportunity WHERE AccountId = :acc.Id]);
        }

        // Update the account records in this batch scope
        update accts;
    }

    // Helper method to update Opportunity Next_Step__c
    private static void updateOpportunityNextStep(List<Opportunity> opps, String nextStep) {

        // Update the NextStep field on each record in the batch scope.
        for(Opportunity opp : opps){
            opp.NextStep = nextStep;
        }

        // Update the opportunity records in this batch scope
        update opps;
    }

    /*
    * Question 2
    * Update/Uncomment the template code to create a method
    * Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
    * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testCreateDealAndUpdateRole to cover test this method
    */
    //Mix DML Error happens when you try to perform DML operations on setup and non-setup objects in a single transaction.
    @future
    public static void createDealAndUpdateRole() {
        Opportunity bigDeal = new Opportunity();
        insertBigDeal(bigDeal);

        UserRole[] roles = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            updateUserRoleName(roles);
        }
    }

    // Helper method to insert big deal
    private static void insertBigDeal(Opportunity opp) {
        opp.Amount = 1000000;
        opp.Name = 'Big Deal';
        opp.StageName = 'Closed Won'; 
        opp.CloseDate = Date.today();
        
        insert opp;
    }

    // Helper method to update role name
    private static void updateUserRoleName(UserRole[] roles){
        UserRole role;
        if (roles.isEmpty()) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // role.OpportunityAccessForAccountOwner = 'Edit'; //This may need to be uncommented depending on your orgs Organization Wide Defaults(OWD) settings. If you are receiving FIELD_INTEGRITY_EXCEPTION, field integrity exception: unknown (Opportunity access level below organization default): [unknown], uncomment this line.
        } else {
            role = roles[0];
        }
        role.Name = 'CRO';

        upsert role;
    }
}