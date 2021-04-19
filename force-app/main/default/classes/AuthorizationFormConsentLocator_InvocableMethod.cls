public with sharing class AuthorizationFormConsentLocator_InvocableMethod {
    @InvocableMethod(label='')
    public List<AuthorizationFormConsentLocator_ActionOutput> execute(
        AuthorizationFormConsentLocator_ActionInput input
    ) {
    }

    public class AuthorizationFormConsentLocator_ActionInput {
        @InvocableVariable(label='Data Use Purpose' required=true)
        public String dataUsePurpose;
    }

    public class AuthorizationFormConsentLocator_ActionOutput {
    }
}
