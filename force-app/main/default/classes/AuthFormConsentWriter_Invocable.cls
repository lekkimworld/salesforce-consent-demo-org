public with sharing class AuthFormConsentWriter_Invocable {
    @InvocableMethod(label='Write AuthorizationFormConsent record for Data Use Purpose')
    public static List<AuthFormConsentWriter_ActionOutput2> execute(List<AuthFormConsentWriter_ActionInput2> inputs) {
        final List<AuthFormConsentWriter_ActionOutput2> results = new List<AuthFormConsentWriter_ActionOutput2>();

        final Map<Id, AuthorizationFormConsent> records = new Map<Id, AuthorizationFormConsent>();
        for (AuthFormConsentWriter_ActionInput2 input : inputs) {
            final AuthorizationFormConsent consent = new AuthorizationFormConsent();
            consent.Name = input.individual.Id + ', ' + input.authformTextId;
            consent.AuthorizationFormTextId = input.authformTextId;
            consent.ConsentCapturedDateTime = DateTime.now();
            if (String.isNotEmpty(input.captureSource)) {
                consent.ConsentCapturedSourceType = input.captureSource;
            }
            if (String.isNotEmpty(input.status)) {
                consent.Status = input.status;
            }
            consent.ConsentGiverId = input.individual.Id;
            records.put(input.individual.Id, consent);
        }

        // insert records
        insert records.values();

        // loop and get resulting IDs
        for (AuthFormConsentWriter_ActionInput2 input : inputs) {
            AuthorizationFormConsent consent = records.get(input.individual.Id);
            AuthFormConsentWriter_ActionOutput2 result = new AuthFormConsentWriter_ActionOutput2();
            result.record = consent;
            result.recordId = consent.Id;
            results.add(result);
        }

        // return
        return results;
    }

    public class AuthFormConsentWriter_ActionInput2 {
        @InvocableVariable(label='Individual' required=true)
        public Individual individual;

        @InvocableVariable(label='ID of Auth. Form Text' required=true)
        public Id authformTextId;

        @InvocableVariable(
            label='Capture Source'
            description='Valid values are: "", "Web", "Email", "Phone", "Social", "MailingAddress"'
        )
        public String captureSource;

        @InvocableVariable(label='Status' description='Valid values are: "", "Seen" and "Signed" (default is "")')
        public String status;
    }

    public class AuthFormConsentWriter_ActionOutput2 {
        @InvocableVariable(label='Auth. Form Consent record')
        public AuthorizationFormConsent record;

        @InvocableVariable(label='Auth. Form Consent record ID')
        public Id recordId;
    }
}
