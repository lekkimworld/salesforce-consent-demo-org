public without sharing class AuthFormConsentWriter_InvocableMethod {
    @InvocableMethod(label='Write AuthorizationFormConsent record for Data Use Purpose')
    public static List<AuthFormConsentWriter_ActionOutput> execute(List<AuthFormConsentWriter_ActionInput> inputs) {
        final List<AuthFormConsentWriter_ActionOutput> results = new List<AuthFormConsentWriter_ActionOutput>();

        // get data about users and create Individual records if required
        final AuthFormConsent_IndividualUtil util = new AuthFormConsent_IndividualUtil();
        for (AuthFormConsentWriter_ActionInput input : inputs) {
            util.addInput(
                input.userId,
                input.contactId,
                String.isEmpty(input.individualId) ? null : Id.valueOf(input.individualId)
            );
        }
        final List<AuthFormConsent_IndividualUtil.UtilData> utildata = util.process(true);

        final Map<Id, AuthorizationFormConsent> records = new Map<Id, AuthorizationFormConsent>();
        for (integer i = 0; i < inputs.size(); i++) {
            final AuthFormConsentWriter_ActionInput input = inputs[i];
            final AuthFormConsent_IndividualUtil.UtilData data = utildata[i];
            final AuthorizationFormConsent consent = new AuthorizationFormConsent();
            consent.Name = data.individualId + ', ' + input.authformTextId;
            consent.AuthorizationFormTextId = input.authformTextId;
            consent.ConsentCapturedDateTime = DateTime.now();
            if (String.isNotEmpty(input.captureSource)) {
                consent.ConsentCapturedSourceType = input.captureSource;
            }
            if (String.isNotEmpty(input.status)) {
                consent.Status = input.status;
            }
            consent.ConsentGiverId = data.individualId;
            records.put(data.individualId, consent);
        }

        // insert records
        insert records.values();

        // loop and get resulting IDs
        for (integer i = 0; i < inputs.size(); i++) {
            final AuthFormConsentWriter_ActionInput input = inputs[i];
            final AuthFormConsent_IndividualUtil.UtilData data = utildata[i];
            AuthorizationFormConsent consent = records.get(data.individualId);
            AuthFormConsentWriter_ActionOutput result = new AuthFormConsentWriter_ActionOutput();
            result.individualId = data.individualId;
            result.recordId = consent.Id;
            results.add(result);
        }

        // return
        return results;
    }

    public class AuthFormConsentWriter_ActionInput {
        @InvocableVariable(label='ID of Individual')
        public String individualId;

        @InvocableVariable(label='UserID' description='Leave empty to use calling users ID')
        public Id userId;

        @InvocableVariable(label='ID of Contact')
        public Id contactId;

        @InvocableVariable(label='ID of Auth. Form Text' required='true')
        public Id authformTextId;

        @InvocableVariable(
            label='Capture Source'
            description='Valid values are: "", "Web", "Email", "Phone", "Social", "Mailing Address"'
        )
        public String captureSource;

        @InvocableVariable(label='Status' description='Valid values are: "", "Seen" and "Signed" (default is "")')
        public String status;
    }

    public class AuthFormConsentWriter_ActionOutput {
        @InvocableVariable(label='ID of Individual' required='true')
        public Id individualId;

        @InvocableVariable(label='ID of Auth. Form Consent record')
        public Id recordId;
    }
}
