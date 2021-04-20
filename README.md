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
ORG_ID=`sfdx force:org:display --json | jq ".result.id" -r`
openssl req -newkey rsa:2048 -nodes -keyout private_key.pem -x509 -days 365 -out certificate.pem -subj "/CN=Demo Server App ($ORG_ID)/O=SFDC/C=DK"
openssl x509 -in certificate.pem -pubkey > public_key.pem
openssl x509 -outform der -in certificate.pem -out certificate.der

CLIENT_ID1=id1_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET1=secret1_`echo $ORG_ID`_`date +%s`
CLIENT_ID2=id2_`echo $ORG_ID`_`date +%s`
CLIENT_SECRET2=secret2_`echo $ORG_ID`_`date +%s`
CERT_BASE64=`cat certificate.der | base64 -`

cat ./connectedAppTemplates/Demo_Server_App_dev.connectedApp-meta.xml | sed "s|REPLACE_CERT|$CERT_BASE64|" | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID1|" | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET1|" > force-app/main/default/connectedApps/Demo_Server_App_dev.connectedApp-meta.xml
cat ./connectedAppTemplates/Demo_User_App_dev.connectedApp-meta.xml | sed "s|REPLACE_CLIENT_ID|$CLIENT_ID2|" | sed "s|REPLACE_CLIENT_SECRET|$CLIENT_SECRET2|" > ./force-app/main/default/connectedApps/Demo_User_App_dev.connectedApp-meta.xml

sfdx force:source:deploy -m ConnectedApp
sfdx force:source:deploy -m Profile
sfdx force:source:deploy -m SiteDotCom,Network,ExperienceBundle,CustomSite,ApexPage
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
```

Convert private key PEM to multiline .env variable
cat ../org/private_key.pem | sed 's/$/\\n/g' | tr -d "\n"
