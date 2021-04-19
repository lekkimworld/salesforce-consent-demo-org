public without sharing class AuthorizationFormDisplayController {
  @AuraEnabled(cacheable=true)
  public static AuthFormDisplayResult getConsentData(String dataUsePurpose) {
    if (String.isEmpty(dataUsePurpose))
      throw new AuraHandledException('Must supply dataUserPurpose');

    // get auth form from data use purpose
    final List<AuthorizationForm> forms = [
      SELECT Id, Name, DefaultAuthFormTextId
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
    if (forms.size() != 1) {
      throw new AuraHandledException(
        'Found more than 1 active AuthorizationForm for data use purpose (' +
        dataUsePurpose +
        ')'
      );
    }
    final String defaultFormTextId = forms[0].DefaultAuthFormTextId;
    System.debug('Default Form Text ID: ' + defaultFormTextId);

    // get auth form texts
    final List<AuthorizationFormText> texts = [
      SELECT id, name, locale, FormText__c
      FROM AuthorizationFormText
      WHERE AuthorizationFormId = :forms[0].Id
    ];
    if (texts.size() == 0) {
      throw new AuraHandledException(
        'Unable to locate any texts for authorization form'
      );
    }
    System.debug('Loaded ' + texts.size() + ' AuthorizationFormText records');

    // get actual texts and build result
    final AuthFormDisplayResult result = new AuthFormDisplayResult();
    for (AuthorizationFormText f : texts) {
      AuthFormText text = new AuthFormText();
      text.id = f.Id;
      text.locale = f.Locale;
      text.language = getLanguageFromLocale(f.Locale);
      text.text = f.FormText__c;
      result.texts.add(text);
      if (f.Id.equals(defaultFormTextId))
        result.defaultId = f.Id;
    }

    // return
    System.debug('Returning data');
    return result;
  }

  private static String getLanguageFromLocale(String locale) {
    if (!String.isEmpty(locale)) {
      if (locale.startsWith('en_'))
        return 'English';
      if (locale.startsWith('es_'))
        return 'Spanish';
    }
    return 'Unknown (' + locale + ')';
  }

  public class AuthFormDisplayResult {
    @AuraEnabled
    public String defaultId = null;
    @AuraEnabled
    public List<AuthFormText> texts = new List<AuthFormText>();
  }

  public class AuthFormText {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String locale;
    @AuraEnabled
    public String language;
    @AuraEnabled
    public String text;
  }
}
