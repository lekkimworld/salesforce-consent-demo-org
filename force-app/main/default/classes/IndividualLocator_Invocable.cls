public with sharing class IndividualLocator_Invocable {
    @InvocableMethod(
        label='Locate or create Individual record for users ("Create missing" is only read from first argument object)'
    )
    public static List<IndividualLocator_ActionOutput> execute(List<IndividualLocator_ActionInput> inputs) {
        final List<IndividualLocator_ActionOutput> results = new List<IndividualLocator_ActionOutput>();
        final boolean createMissing = inputs[0].createMissing;

        // get data
        final AuthFormConsent_IndividualUtil util = new AuthFormConsent_IndividualUtil();
        for (IndividualLocator_ActionInput input : inputs) {
            util.addInput(input.userId, (Id) null, (Id) null);
        }

        // get / create
        final List<AuthFormConsent_IndividualUtil.UtilData> utildata = util.process(createMissing);

        // create results
        for (AuthFormConsent_IndividualUtil.UtilData data : utildata) {
            final IndividualLocator_ActionOutput result = new IndividualLocator_ActionOutput();
            result.record = data.individual;
            result.recordId = data.individualId;
            results.add(result);
        }

        // return
        return results;
    }

    public class IndividualLocator_ActionInput {
        @InvocableVariable(label='UserID' description='Leave empty to use calling users ID')
        public Id userId;

        @InvocableVariable(label='Create missing' description='Create missing Individual records')
        public boolean createMissing;
    }

    public class IndividualLocator_ActionOutput {
        @InvocableVariable(label='Individual' description='Individual record for user')
        public Individual record;

        @InvocableVariable(label='Individual ID' description='Individual record ID for user')
        public Id recordId;
    }
}
