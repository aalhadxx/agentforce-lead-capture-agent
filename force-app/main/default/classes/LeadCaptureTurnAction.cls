public with sharing class LeadCaptureTurnAction {

    private static final Pattern LAST_NAME_PATTERN = Pattern.compile(
        '(?i)last\\s*name\\s*(?:is|=|:)?\\s*([^,.;]+?)(?=\\s+and\\s+company|\\s+company\\s*(?:is|=|:)|[,.]|$)'
    );
    private static final Pattern COMPANY_PATTERN = Pattern.compile(
        '(?i)company\\s*(?:is|=|:)?\\s*(.+)$'
    );

    @InvocableMethod(
        label='Process Lead Capture Turn'
        description='Uses the current user message and any already known last name and company to ask for missing values or create a Lead with Status set to New.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Lead> leadsToInsert = new List<Lead>();
        List<Integer> leadResultIndexes = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Result result = new Result();
            result.status = 'New';

            String lastName = clean(req.knownLastName);
            String company = clean(req.knownCompany);
            String userMessage = clean(req.userMessage);
            ParsedValues parsed = parseMessage(userMessage);

            if (String.isBlank(lastName) && !String.isBlank(parsed.lastName)) {
                lastName = parsed.lastName;
            }
            if (String.isBlank(company) && !String.isBlank(parsed.company)) {
                company = parsed.company;
            }

            if (!containsFieldLabels(userMessage)) {
                if (String.isBlank(lastName) && !String.isBlank(company)) {
                    lastName = userMessage;
                } else if (!String.isBlank(lastName) && String.isBlank(company)) {
                    company = userMessage;
                }
            }

            result.resolvedLastName = clean(lastName);
            result.resolvedCompany = clean(company);
            result.needsLastName = String.isBlank(result.resolvedLastName);
            result.needsCompany = String.isBlank(result.resolvedCompany);

            if (result.needsLastName || result.needsCompany) {
                result.isSuccess = false;
                result.message = missingFieldMessage(result.needsLastName, result.needsCompany);
                results.add(result);
                continue;
            }

            Lead leadRecord = new Lead(
                LastName = result.resolvedLastName,
                Company = result.resolvedCompany,
                Status = 'New'
            );
            leadsToInsert.add(leadRecord);
            leadResultIndexes.add(i);
            results.add(result);
        }

        if (leadsToInsert.isEmpty()) {
            return results;
        }

        try {
            Database.SaveResult[] saveResults = Database.insert(leadsToInsert, false, AccessLevel.USER_MODE);
            for (Integer saveIndex = 0; saveIndex < saveResults.size(); saveIndex++) {
                Integer resultIndex = leadResultIndexes[saveIndex];
                Database.SaveResult saveResult = saveResults[saveIndex];
                Result result = results[resultIndex];

                if (saveResult.isSuccess()) {
                    result.isSuccess = true;
                    result.leadId = String.valueOf(saveResult.getId());
                    result.message = 'Lead created successfully.';
                } else {
                    result.isSuccess = false;
                    result.message = firstErrorMessage(saveResult.getErrors());
                }
            }
        } catch (Exception e) {
            for (Integer resultIndex : leadResultIndexes) {
                Result result = results[resultIndex];
                result.isSuccess = false;
                result.message = 'Failed to create lead: ' + e.getMessage();
            }
        }

        return results;
    }

    private static ParsedValues parseMessage(String userMessage) {
        ParsedValues parsed = new ParsedValues();
        if (String.isBlank(userMessage)) {
            return parsed;
        }

        Matcher lastNameMatcher = LAST_NAME_PATTERN.matcher(userMessage);
        if (lastNameMatcher.find()) {
            parsed.lastName = clean(lastNameMatcher.group(1));
        }

        Matcher companyMatcher = COMPANY_PATTERN.matcher(userMessage);
        if (companyMatcher.find()) {
            parsed.company = clean(companyMatcher.group(1));
        }

        return parsed;
    }

    private static Boolean containsFieldLabels(String userMessage) {
        if (String.isBlank(userMessage)) {
            return false;
        }
        String lower = userMessage.toLowerCase();
        return lower.contains('last name') || lower.contains('company');
    }

    private static String missingFieldMessage(Boolean needsLastName, Boolean needsCompany) {
        if (needsLastName && needsCompany) {
            return 'Please provide your last name and company to create the lead.';
        }
        if (needsLastName) {
            return 'Please provide your last name.';
        }
        return 'Please provide your company name.';
    }

    private static String firstErrorMessage(Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) {
            return 'Failed to create lead.';
        }
        return 'Failed to create lead: ' + errors[0].getMessage();
    }

    private static String clean(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        String cleaned = value.trim();
        while (
            cleaned.endsWith('.') ||
            cleaned.endsWith(',') ||
            cleaned.endsWith(';') ||
            cleaned.endsWith(':')
        ) {
            cleaned = cleaned.left(cleaned.length() - 1).trim();
        }
        return String.isBlank(cleaned) ? null : cleaned;
    }

    private class ParsedValues {
        String lastName;
        String company;
    }

    public class Request {
        @InvocableVariable(label='User Message' description='The current user message for this turn' required=true)
        public String userMessage;

        @InvocableVariable(label='Known Last Name' description='The last name already collected earlier in the conversation')
        public String knownLastName;

        @InvocableVariable(label='Known Company' description='The company already collected earlier in the conversation')
        public String knownCompany;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the lead was created successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Lead ID' description='ID of the created Lead record')
        public String leadId;

        @InvocableVariable(label='Status' description='Status set on the created Lead')
        public String status;

        @InvocableVariable(label='Resolved Last Name' description='Resolved last name after this turn is processed')
        public String resolvedLastName;

        @InvocableVariable(label='Resolved Company' description='Resolved company after this turn is processed')
        public String resolvedCompany;

        @InvocableVariable(label='Needs Last Name' description='Whether last name is still missing')
        public Boolean needsLastName;

        @InvocableVariable(label='Needs Company' description='Whether company is still missing')
        public Boolean needsCompany;

        @InvocableVariable(label='Message' description='Human-readable guidance or result message')
        public String message;
    }
}
