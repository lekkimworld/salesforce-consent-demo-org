public without sharing class AuthFormConsentLocator_Invocable {
    @InvocableMethod(label='Locate AuthorizationFormConsent record for Data Use Purpose')
    public static List<AuthFormConsentLocator_ActionOutput2> execute(List<AuthFormConsentLocator_ActionInput2> inputs) {
        final List<AuthFormConsentLocator_ActionOutput2> results = new List<AuthFormConsentLocator_ActionOutput2>();

        // locate most resent auth form for data use purpose
        final String dataUsePurpose = inputs[0].dataUsePurpose;
        final List<AuthorizationForm> authforms = [
            SELECT Id, Name
            FROM AuthorizationForm
            WHERE
                Id IN (
                    SELECT AuthorizationFormId
                    FROM AuthorizationFormDataUse
                    WHERE DataUsePurpose.Name = :dataUsePurpose
                )
                AND effectivefromdate < TODAY
                AND (effectivetodate = NULL
                OR effectivetodate > TODAY)
        ];
        if (authforms.size() != 1)
            throw new InvocableMethodException(
                'Expected to find a single AuthorizationForm record for data use purpose (' +
                dataUsePurpose +
                ' )'
            );
        final Id authformId = authforms[0].Id;

        // loop and process
        for (AuthFormConsentLocator_ActionInput2 input : inputs) {
            // define result for input
            final AuthFormConsentLocator_ActionOutput2 result = new AuthFormConsentLocator_ActionOutput2();

            // look for consent to auth form for individual
            final List<AuthorizationFormConsent> consents = [
                SELECT Id, ConsentCapturedDateTime
                FROM AuthorizationFormConsent
                WHERE
                    ConsentGiverId = :input.individual.Id
                    AND AuthorizationFormTextId IN (
                        SELECT Id
                        FROM AuthorizationFormText
                        WHERE AuthorizationFormId = :authformId
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

    public class AuthFormConsentLocator_ActionInput2 {
        @InvocableVariable(label='Data Use Purpose' required=true)
        public String dataUsePurpose;

        @InvocableVariable(label='Individual' description='Individual rerecord' required=true)
        public Individual individual;
    }

    public class AuthFormConsentLocator_ActionOutput2 {
        @InvocableVariable(label='ID of Auth. Form')
        public Id authformId;

        @InvocableVariable(label='Has consent')
        public boolean hasConsent;

        @InvocableVariable(label='Date/time of consent')
        public Datetime consentDateTime;
    }
}
