## Deploy script

```
sfdx force:org:create --targetdevhubusername consent_devhub --setdefaultusername -f config/project-scratch-def.json
sfdx force:source:deploy -m Role
ROLE_ID=`sfdx force:data:soql:query -q "select Id from UserRole where Name='Dummy'" --json | jq ".result.records[0].Id" -r`
sfdx force:data:record:update -s User -w "Name='User User'" -v "LanguageLocaleKey=en_US TimeZoneSidKey=Europe/Paris LocaleSidKey=da UserPreferencesUserDebugModePref=true UserPreferencesApexPagesDeveloperMode=true UserPermissionsInteractionUser=true UserPermissionsKnowledgeUser=true UserRoleId=$ROLE_ID"
sfdx shane:user:password:set -p Salesforce1 -g User -l User
sfdx force:package:install -p 04t4J000002Dhe1QAC -w 30

sfdx force:source:deploy -m Layout,CustomObject,CustomApplication,FlexiPage,PermissionSet:Authorization_Form_App
sfdx force:user:permset:assign -n Authorization_Form_App
sfdx force:data:tree:import -p demodata/import-plan.json
sfdx force:source:deploy -m ApexClass,LightningComponentBundle,Flow

rm *.pem *.der
rm ./force-app/main/default/connectedApps/*.xml 2> /dev/null
ORG_ID=`sfdx force:org:display --json | jq ".result.id" -r`
USER_ID=`sfdx force:org:display --json | jq ".result.username" -r`
INSTANCE_URL=`sfdx force:org:display --json | jq ".result.instanceUrl" -r`
openssl req \
    -newkey rsa:2048 \
    -nodes \
    -keyout private_key.pem \
    -x509 \
    -days 365 \
    -out certificate.pem \
    -subj "/CN=Demo Server App ($ORG_ID)/O=SFDC/C=DK"
openssl x509 \
    -in certificate.pem \
    -pubkey \
    > public_key.pem
openssl x509 \
    -outform der \
    -in certificate.pem \
    -out certificate.der

HEROKU_APP_DOMAIN="salesforce-consent-demo.herokuapp.com"
CLIENT_ID1=id1_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET1=secret1_`echo $ORG_ID`_`date +%s`
CLIENT_ID2=id2_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET2=secret2_`echo $ORG_ID`_`date +%s`
CERT_BASE64=`cat certificate.der | base64 -`

cat ./metadataTemplates/connectedApps/Demo_Server_App.connectedApp-meta.xml \
    | sed "s|REPLACE_CERT|$CERT_BASE64|" \
    | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID1|" \
    | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET1|" \
    > force-app/main/default/connectedApps/Demo_Server_App.connectedApp-meta.xml

cat ./metadataTemplates/connectedApps/Demo_User_App.connectedApp-meta.xml \
    | sed "s|REPLACE_HEROKU_APP_DOMAIN|$HEROKU_APP_DOMAIN|" \
    | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID2|" \
    | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET2|" \
    > ./force-app/main/default/connectedApps/Demo_User_App.connectedApp-meta.xml



sfdx force:source:deploy -m PermissionSet
sfdx force:user:permset:assign -n Demo_Server_App
sfdx force:source:deploy -m ConnectedApp
sfdx force:source:deploy -m ApexPage,Profile
sfdx force:source:deploy -m SiteDotCom,Network,ExperienceBundle,CustomSite
sfdx force:source:deploy -m ContentAsset
sfdx force:community:publish -n "Customer Self-Service"

echo "Demo Server App"
echo "Client ID    : $CLIENT_ID1"
echo "Client Secret: $CLIENT_SECRET1"
echo ""
echo "Demo User App"
echo "Client ID    : $CLIENT_ID2"
echo "Client Secret: $CLIENT_SECRET2"

cat ./private_key.pem | sed 's/$/\\n/g' | tr -d "\n"

echo "\n\n"
echo "Manually admin approve Demo Server App"
```

Convert private key PEM to multiline .env variable
cat ../org/private_key.pem | sed 's/$/\\n/g' | tr -d "\n"

## Create demo portal user

```
final String timezone = 'Europe/Paris';
final String locale = 'da_DK';
final String actualEmail = 'mheisterberg@salesforce.com';
final String fn = 'John';
final String ln = 'Doe';
final String alias = (fn.toLowerCase().substring(0, 1) + ln.toLowerCase()).substring(0,4) + String.valueOf(DateTime.now().getTime()).reverse().substring(0,4);
final String email = fn.toLowerCase() + '.' + ln.toLowerCase() + '@example.com';

Account a = [SELECT Id FROM Account WHERE Name = 'Foo Corp.' LIMIT 1];

Contact c = new Contact();
c.FirstName = fn;
c.LastName = ln;
c.Email = email;
c.AccountId = a.Id;
INSERT c;

Profile p = [SELECT Id FROM Profile WHERE Name = 'CC Demo User' LIMIT 1];

User u = new User();
u.firstname = fn;
u.lastname = ln;
u.username = email;
u.email = actualEmail;
u.ProfileId = p.Id;
u.Contactid = c.Id;
u.alias = alias;
u.EmailEncodingKey = 'UTF-8';
u.IsActive = true;
u.LanguageLocaleKey = 'en_US';
u.LocaleSidKey = locale;
u.TimeZoneSidKey = timezone;
insert u;
```

## Disable all portal users and delete their data

```
List<User> users = [SELECT Id, IsActive, FirstName, LastName FROM User WHERE IsPortalEnabled=true];
for (User u : Users) {
u.IsActive = false;
u.IsPortalEnabled = false;
u.FirstName = 'Disabled*' + u.FirstName;
u.LastName = 'Disabled*' + u.LastName;
}
UPDATE users;

DELETE [SELECT Id FROM ContactPointTypeConsent];
DELETE [SELECT Id FROM AuthorizationFormConsent];
final List<Contact> contacts = [SELECT Id, IndividualId FROM Contact];
for (Contact c : contacts) c.IndividualId = null;
UPDATE contacts;
DELETE [SELECT Id FROM Individual];
DELETE contacts;
```
