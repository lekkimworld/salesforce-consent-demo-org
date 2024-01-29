## Deploy script

```
sf org create scratch --set-default -f config/project-scratch-def.json
sf project deploy start -m Role
ROLE_ID=`sf data query --query "select Id from UserRole where Name='Dummy'" --json | jq ".result.records[0].Id" -r`
sf data update record -s User -w "Name='User User'" -v "LanguageLocaleKey=en_US TimeZoneSidKey=Europe/Paris LocaleSidKey=da UserPreferencesUserDebugModePref=true UserPreferencesApexPagesDeveloperMode=true UserPermissionsInteractionUser=true UserPermissionsKnowledgeUser=true UserRoleId=$ROLE_ID"

sf project deploy start -m Layout -m CustomObject -m CustomApplication -m FlexiPage -m PermissionSet:Demo_API_Only -m PermissionSet:Demo_Authorization_Form_App
sf force user permset assign -n Demo_Authorization_Form_App
sf data import tree -p demodata/plan-complete.json
sf project deploy start -m ApexClass -m LightningComponentBundle -m Flow -m Settings

sf apex run -f scripts/apex/create_api_only_user.apex
API_USERNAME=`sf data query --query "select Username from User where Name='API User'" --json | jq ".result.records[0].Username" -r`

ORG_ID=`sf org display --json | jq ".result.id" -r`
HEROKU_APP_DOMAIN="salesforce-consent-demo.herokuapp.com"
CLIENT_ID1=id1_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET1=secret1_`echo $ORG_ID`_`date +%s`
CLIENT_ID2=id2_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET2=secret2_`echo $ORG_ID`_`date +%s`

cat ./metadataTemplates/connectedApps/Demo_ClientCredentials_App.connectedApp-meta.xml \
    | sed "s|REPLACE_API_USERNAME|$API_USERNAME|" \
    | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID1|" \
    | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET1|" \
    > force-app/main/default/connectedApps/Demo_ClientCredentials_App.connectedApp-meta.xml

cat ./metadataTemplates/connectedApps/Demo_OpenID_Login_App.connectedApp-meta.xml \
    | sed "s|REPLACE_HEROKU_APP_DOMAIN|$HEROKU_APP_DOMAIN|" \
    | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID2|" \
    | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET2|" \
    > ./force-app/main/default/connectedApps/Demo_OpenID_Login_App.connectedApp-meta.xml

sf project deploy start -m ConnectedApp -m ApexPage -m Profile -m SiteDotCom -m Network -m CustomSite
sf project deploy start -m PermissionSet:Demo_ClientCredentials_App
sf force user permset assign --perm-set-name=Demo_ClientCredentials_App --on-behalf-of=$API_USERNAME
sf project deploy start -m ExperienceBundle
sf project deploy start -m ContentAsset
SITE_URL=`sfdx force community publish -n "Customer Self-Service" --json | jq -r ".result.url"`

echo "Site URL     : $SITE_URL"
echo "UserID       : $USER_ID"
echo "Demo ClientCredentials App"
echo "Client ID    : $CLIENT_ID1"
echo "Client Secret: $CLIENT_SECRET1"
echo ""
echo "Demo Authorization Form App"
echo "Client ID    : $CLIENT_ID2"
echo "Client Secret: $CLIENT_SECRET2"


echo "\n\n"
echo "Manually admin approve (add to profile) 'Demo Server App' for 'System Administrator' Profile"
echo "Manually admin approve (add to profile 'Demo User App' for 'CC Demo User' Profile"
```

## Create demo portal user

See `scripts/apex/create_demouser_johndoe.apex`


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

## Clean up ##
```
DELETE [select id from AuthorizationFormText];
DELETE [select id from AuthorizationFormDataUse];
DELETE [select id from AuthorizationForm];
DELETE [select id from DataUsePurpose];
DELETE [select id from DataUseLegalBasis];
DELETE [select id from Individual];
DELETE [select id from Contact];
DELETE [select id from Entitlement];
DELETE [select id from Account];
```
