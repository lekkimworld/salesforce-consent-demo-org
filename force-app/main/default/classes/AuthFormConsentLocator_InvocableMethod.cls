public without sharing class AuthFormConsentLocator_InvocableMethod {
    @InvocableMethod(label='Locate AuthorizationFormConsent record for Data Use Purpose')
    public static List<AuthFormConsentLocator_ActionOutput> execute(List<AuthFormConsentLocator_ActionInput> inputs) {
        final List<AuthFormConsentLocator_ActionOutput> results = new List<AuthFormConsentLocator_ActionOutput>();

        // get data about users without creating Individual records
        final AuthFormConsent_IndividualUtil util = new AuthFormConsent_IndividualUtil();
        for (AuthFormConsentLocator_ActionInput input : inputs) {
            util.addInput(input.userId, (Id) null, (Id) null);
        }
        final List<AuthFormConsent_IndividualUtil.UtilData> utildata = util.process(false);

        // loop and process
        for (integer i = 0; i < inputs.size(); i++) {
            // define result for input
            final AuthFormConsentLocator_ActionInput input = inputs[i];
            final AuthFormConsentLocator_ActionOutput result = new AuthFormConsentLocator_ActionOutput();
            final AuthFormConsent_IndividualUtil.UtilData data = utildata[i];

            // locate most resent auth form for data use purpose
            final List<AuthorizationForm> authforms = [
                SELECT Id, Name
                FROM AuthorizationForm
                WHERE
                    Id IN (
                        SELECT AuthorizationFormId
                        FROM AuthorizationFormDataUse
                        WHERE DataUsePurpose.Name = :input.dataUsePurpose
                    )
                    AND effectivefromdate < TODAY
                    AND (effectivetodate = NULL
                    OR effectivetodate > TODAY)
            ];
            if (authforms.size() != 1)
                throw new InvocableMethodException(
                    'Expected to find a single AuthorizationForm record for data use purpose (' +
                    input.dataUsePurpose +
                    ' )'
                );

            // add data to result
            result.authformId = authforms[0].Id;
            result.userId = data.userId;
            result.contactId = data.contactId;

            // if no individual Id there is no reason to proceed
            if (String.isEmpty(data.individualId)) {
                results.add(result);
                continue;
            } else {
                result.individualId = data.individualId;
            }

            // look for consent to auth form for individual
            final List<AuthorizationFormConsent> consents = [
                SELECT Id, ConsentCapturedDateTime
                FROM AuthorizationFormConsent
                WHERE
                    ConsentGiverId = :result.individualId
                    AND AuthorizationFormTextId IN (
                        SELECT Id
                        FROM AuthorizationFormText
                        WHERE AuthorizationFormId = :result.authformId
                    )
            ];
            if (consents.size() == 0) {
                // consent not given
                System.debug('Consent not given yet for user');
            } else {
                // we have consent
                System.debug('Consent ALREADY given for user');
                result.hasConsent = true;
                result.consentDateTime = consents[0].ConsentCapturedDateTime;
            }

            // add to result
            results.add(result);
        }

        // return
        return results;
    }

    public class AuthFormConsentLocator_ActionInput {
        @InvocableVariable(label='Data Use Purpose' required=true)
        public String dataUsePurpose;

        @InvocableVariable(label='UserID' description='Leave empty to use calling users ID')
        public Id userId;
    }

    public class AuthFormConsentLocator_ActionOutput {
        @InvocableVariable(label='ID of Individual')
        public Id individualId;

        @InvocableVariable(label='ID of User')
        public Id userId;

        @InvocableVariable(label='ID of Contact')
        public Id contactId;

        @InvocableVariable(label='ID of Auth. Form')
        public Id authformId;

        @InvocableVariable(label='Has consent')
        public boolean hasConsent;

        @InvocableVariable(label='Date/time of consent')
        public Datetime consentDateTime;
    }
}
