public with sharing class ContactPointTypeConsentWriter_Invocable {
    @InvocableMethod(label='Write ContactPointTypeConsent record for Data Use Purpose')
    public static List<ContactPointTypeConsentWriter_ActionOutput> execute(
        List<ContactPointTypeConsentWriter_ActionInput> inputs
    ) {
        // get datause purpose
        final String str_dup = inputs[0].dataUsePurpose;
        final List<DataUsePurpose> dups = [SELECT Id FROM DataUsePurpose WHERE Name = :str_dup];
        if (dups.size() != 1) {
            throw new InvocableMethodException('Expected to find 1 DataUsePurpose record for name (' + str_dup + ')');
        }
        final DataUsePurpose dup = dups[0];

        List<ContactPointTypeConsent> newConsents = new List<ContactPointTypeConsent>();
        for (ContactPointTypeConsentWriter_ActionInput input : inputs) {
            ContactPointTypeConsent consent = new ContactPointTypeConsent();
            consent.Name = str_dup + ', ' + input.individual.id;
            consent.CaptureDate = null != input.capturedDateTime ? input.capturedDateTime : DateTime.now();
            consent.EffectiveFrom = null != input.effectiveFrom ? input.effectiveFrom : DateTime.now();
            consent.EffectiveTo = null != input.effectiveTo ? input.effectiveTo : DateTime.now().addYears(10);
            consent.PartyId = input.individual.Id;
            consent.ContactPointType = input.contactPointType;
            consent.PrivacyConsentStatus = input.status;
            consent.DataUsePurposeId = dup.Id;
            newConsents.add(consent);
        }

        // insert
        insert newConsents;

        // compose results
        final List<ContactPointTypeConsentWriter_ActionOutput> results = new List<ContactPointTypeConsentWriter_ActionOutput>();
        for (ContactPointTypeConsent c : newConsents) {
            ContactPointTypeConsentWriter_ActionOutput result = new ContactPointTypeConsentWriter_ActionOutput();
            result.record = c;
            result.recordId = c.Id;
            results.add(result);
        }

        // return
        return results;
    }

    public class ContactPointTypeConsentWriter_ActionInput {
        @InvocableVariable(label='Individual' required=true)
        public Individual individual;

        @InvocableVariable(label='Data Use Purpose' required=true)
        public String dataUsePurpose;

        @InvocableVariable(label='Effective From' description='Date/time, blank to use current timestamp')
        public Datetime effectiveFrom;

        @InvocableVariable(label='Effective To' description='Date/time, blank to use current timestamp + 10 years')
        public Datetime effectiveTo;

        @InvocableVariable(label='Captured timestamp' description='Date/time, blank to use current timestamp')
        public Datetime capturedDateTime;

        @InvocableVariable(
            label='Contact Point Type'
            description='Valid values are: "", "Web", "Email", "Phone", "Social", "MailingAddress"'
        )
        public String contactPointType;

        @InvocableVariable(
            label='Privacy Consent Status'
            description='Valid values are: "", "Seen", "NotSeen", "OptIn", "OptOut" (default is "")'
            required=true
        )
        public String status;
    }

    public class ContactPointTypeConsentWriter_ActionOutput {
        @InvocableVariable(label='Contact Point Type Consent record')
        public ContactPointTypeConsent record;

        @InvocableVariable(label='Contact Point Type Consent record ID')
        public Id recordId;
    }
}
