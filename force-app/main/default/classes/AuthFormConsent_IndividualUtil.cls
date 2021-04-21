public inherited sharing class AuthFormConsent_IndividualUtil {
    private List<UtilData> inputs = new List<UtilData>();
    private List<UtilDataInternal> work = new List<UtilDataInternal>();

    public AuthFormConsent_IndividualUtil addInput(final Id userId, final Id contactId, final Id individualId) {
        UtilData i = new UtilData();
        i.userId = userId;
        i.contactId = contactId;
        i.individualId = individualId;
        this.inputs.add(i);
        return this;
    }

    public List<UtilData> process(boolean createIndividuals) {
        final List<Individual> newIndividuals = new List<Individual>();
        final Set<Id> userIds = new Set<Id>();
        final Set<Id> contactIds = new Set<Id>();
        for (UtilData input : this.inputs) {
            final UtilDataInternal result = new UtilDataInternal();
            this.work.add(result);

            // decide on userId
            if (String.isEmpty(input.userId)) {
                result.userId = UserInfo.getUserId();
            } else {
                result.userId = input.userId;
            }

            // get contacts
            userIds.add(result.userId);
        }

        // find contact from user
        final List<User> users = [SELECT Id, ContactId FROM User WHERE Id IN :userIds];
        for (UtilDataInternal result : this.work) {
            for (User u : users) {
                if (u.Id == result.userId) {
                    result.contactId = u.ContactId;
                }
            }
            if (String.isEmpty(result.contactId)) {
                throw new InvocableMethodException('Unable to find Contact record from User record');
            }
            contactIds.add(result.contactId);
        }

        // find individual from contact
        final List<Contact> contacts = [
            SELECT Id, FirstName, LastName, IndividualId
            FROM Contact
            WHERE Id IN :contactIds
        ];
        for (UtilDataInternal result : this.work) {
            for (Contact c : contacts) {
                if (c.Id == result.contactId) {
                    if (String.isNotEmpty(c.IndividualId)) {
                        // there is an individual for this contact - save id
                        result.individualId = c.IndividualId;
                    } else if (createIndividuals) {
                        // there isn't an Individual record and we should create it
                        Individual ind = new Individual();
                        ind.FirstName = c.FirstName;
                        ind.LastName = c.LastName;
                        result.individual = ind;
                        result.contact = c;
                        newIndividuals.add(ind);
                    }
                }
            }
        }

        // create individuals if any
        if (!newIndividuals.isEmpty()) {
            // insert
            insert newIndividuals;

            // add ids to results
            final List<Contact> contactsToUpdate = new List<Contact>();
            for (UtilDataInternal result : this.work) {
                result.individualId = result.individual.Id;
                result.contact.IndividualId = result.individual.Id;
                contactsToUpdate.add(result.contact);
            }

            // update
            update contactsToUpdate;
        }

        // build result
        List<UtilData> results = new List<UtilData>();
        for (UtilDataInternal r : this.work) {
            UtilData d = new UtilData();
            d.userId = r.userId;
            d.contactId = r.contactId;
            d.individualId = r.individualId;
            results.add(d);
        }

        // return
        return results;
    }

    public virtual class UtilData {
        public Id userId;
        public Id contactId;
        public Id individualId;
    }

    private class UtilDataInternal extends UtilData {
        public Individual individual;
        public Contact contact;
    }
}
