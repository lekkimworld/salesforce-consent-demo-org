public with sharing class CommunicationConsentLCC {

    public CommunicationConsentLCC() {

    }

    public static List<Id> getSalesCommunicationDataUsePurposeIds() {
        final List<Id> result = new List<Id>();
        for (DataUsePurpose dup : [SELECT Id FROM DataUsePurpose WHERE LegalBasis.Name = 'Sales Communication']) {
            result.add(dup.Id);
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String,Object> getContactConsentData(Id contactId) {
        List<Contact> contacts = [SELECT IndividualId, MailingCountry FROM Contact WHERE Id =: contactId];
        if (contacts.size() != 1) throw new AuraHandledException(String.format('Unable to find unique contact for ID <{0}>', new List<Id>{contactId}));

        // define result
        final Map<String,Object> result = new Map<String,Object>();

        final Contact contact = contacts.get(0);
        final List<Id> dataUsePurposeIds = getSalesCommunicationDataUsePurposeIds();
        List<ContactPointConsent> consents = [SELECT Id, PrivacyConsentStatus, EffectiveFrom, EffectiveTo, DataUsePurposeId FROM ContactPointConsent WHERE PartyRoleId IN (SELECT Id FROM Customer WHERE PartyId =: contact.IndividualId) AND DataUsePurposeId IN : dataUsePurposeIds];
        for (ContactPointConsent c : consents) {
            result.put(c.PrivacyConsentStatus, c.DataUsePurposeId);
            System.debug(String.format('{0} {1}', new List<String>{c.PrivacyConsentStatus, c.DataUsePurposeId}));
        }

        
        return result;
    }
}