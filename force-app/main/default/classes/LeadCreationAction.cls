public with sharing class LeadCreationAction {

    @InvocableMethod(
        label='Create Minimal Lead'
        description='Creates a Salesforce Lead with only last name and company, and sets Status to New.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Lead> leadsToInsert = new List<Lead>();
        List<Integer> requestIndexes = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Result result = new Result();
            result.isSuccess = false;
            result.status = 'New';

            if (String.isBlank(req.lastName) || String.isBlank(req.company)) {
                result.message = 'Last name and company are required to create a lead.';
                results.add(result);
                continue;
            }

            Lead leadRecord = new Lead(
                LastName = req.lastName.trim(),
                Company = req.company.trim(),
                Status = 'New'
            );
            leadsToInsert.add(leadRecord);
            requestIndexes.add(i);
            results.add(result);
        }

        if (leadsToInsert.isEmpty()) {
            return results;
        }

        try {
            Database.SaveResult[] saveResults = Database.insert(leadsToInsert, false, AccessLevel.USER_MODE);
            for (Integer saveIndex = 0; saveIndex < saveResults.size(); saveIndex++) {
                Integer resultIndex = requestIndexes[saveIndex];
                Database.SaveResult saveResult = saveResults[saveIndex];
                Result result = results[resultIndex];

                if (saveResult.isSuccess()) {
                    result.isSuccess = true;
                    result.leadId = String.valueOf(saveResult.getId());
                    result.message = 'Lead created successfully.';
                } else {
                    result.message = firstErrorMessage(saveResult.getErrors());
                }
            }
        } catch (Exception e) {
            for (Integer resultIndex : requestIndexes) {
                Result result = results[resultIndex];
                if (!result.isSuccess) {
                    result.message = 'Failed to create lead: ' + e.getMessage();
                }
            }
        }

        return results;
    }

    private static String firstErrorMessage(Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) {
            return 'Failed to create lead.';
        }
        return 'Failed to create lead: ' + errors[0].getMessage();
    }

    public class Request {
        @InvocableVariable(label='Last Name' description='Lead last name' required=true)
        public String lastName;

        @InvocableVariable(label='Company' description='Lead company' required=true)
        public String company;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the lead was created successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Lead ID' description='ID of the created Lead record')
        public String leadId;

        @InvocableVariable(label='Status' description='Status set on the created Lead')
        public String status;

        @InvocableVariable(label='Message' description='Human-readable result message')
        public String message;
    }
}
