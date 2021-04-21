public without sharing class AuthFormConsent_IndividualUtil {
    private List<UtilData> inputs = new List<UtilData>();
    private List<UtilData> work = new List<UtilData>();

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
        final Map<Id, UtilData> getIndividuals = new Map<Id, UtilData>();
        final Set<Id> userIds = new Set<Id>();
        final Set<Id> contactIds = new Set<Id>();
        for (UtilData input : this.inputs) {
            final UtilData result = new UtilData();
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
        for (UtilData result : this.work) {
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
        for (UtilData result : this.work) {
            for (Contact c : contacts) {
                if (c.Id == result.contactId) {
                    if (String.isNotEmpty(c.IndividualId)) {
                        // there is an individual for this contact - save id
                        result.individualId = c.IndividualId;
                        getIndividuals.put(c.IndividualId, result);
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

        // get individuals if any
        if (!getIndividuals.isEmpty()) {
            List<Individual> individuals = [SELECT Id FROM Individual WHERE Id IN :getIndividuals.keySet()];
            for (Individual ind : individuals) {
                getIndividuals.get(ind.Id).individual = ind;
            }
        }

        // create individuals if any
        if (!newIndividuals.isEmpty()) {
            // insert
            insert newIndividuals;

            // add ids to results
            final List<Contact> contactsToUpdate = new List<Contact>();
            for (UtilData result : this.work) {
                result.individualId = result.individual.Id;
                result.contact.IndividualId = result.individual.Id;
                contactsToUpdate.add(result.contact);
            }

            // update
            update contactsToUpdate;
        }

        // return
        return this.work;
    }

    public virtual class UtilData {
        public Id userId;
        public Id contactId;
        public Contact contact;
        public Id individualId;
        public Individual individual;
    }
}
