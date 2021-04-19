```
sfdx force:org:create -a consent1 --targetdevhubusername sn-20210407 --setdefaultusername -f config/project-scratch-def.json

ROLE_ID=`sfdx force:data:soql:query -q "select Id from UserRole where Name='Dummy'" --json | jq ".result.records[0].Id" -r`

sfdx force:data:record:update -s User -w "Name='User User'" -v "LanguageLocaleKey=en_US TimeZoneSidKey=Europe/Paris LocaleSidKey=da UserPreferencesUserDebugModePref=true UserPreferencesApexPagesDeveloperMode=true UserPermissionsInteractionUser=true UserPermissionsKnowledgeUser=true UserRoleId=$ROLE_ID"

sfdx shane:user:password:set -p Salesforce1 -g User -l User

sfdx force:package:install -p 04t4J000002Dhe1QAC -w 30

ORG_ID=`sfdx force:org:display --json | jq ".result.id" -r`
openssl req -newkey rsa:2048 -nodes -keyout private_key.pem -x509 -days 365 -out certificate.pem -subj "/CN=Demo Server App ($ORG_ID)/O=SFDC/C=DK"
openssl x509 -in certificate.pem -pubkey > public_key.pem
```

Convert private key PEM to multiline .env variable
cat ../org/private_key.pem | sed 's/$/\\n/g' | tr -d "\n"

Get authorization form for specific Data Use Purpose
sfdx force:data:soql:query -q "select id,name,DefaultAuthFormTextId from authorizationform where id in (select AuthorizationFormId from AuthorizationFormDataUse where DataUsePurpose.Name = 'Terms of Service') and effectivefromdate < TODAY and (effectivetodate =null or effectivetodate > TODAY)"

Get the authorization form texts for that form including locales
sfdx force:data:soql:query -q "select id, name, locale, ContentDocumentId from AuthorizationFormText where AuthorizationFormId = '0cI090000008VtREAU'"

Finally get the URL to the content for a specific Authorization Form Text
sfdx force:data:soql:query -q "select id, versionnumber, VersionData from contentversion where contentdocumentid='06909000000R2RtAAK' order by versionnumber desc limit 1"

---

Get ContactId and IndividualId for UserId
sfdx force:data:soql:query -q "select ContactId from user where id='0053N000004CpLY'"
sfdx force:data:soql:query -q "select IndividualId FROM Contact WHERE Id='0033N00000WoA9FQAV'"

Get current authorization form for Data Use Purpose
sfdx force:data:soql:query -q "select id,name,DefaultAuthFormTextId from authorizationform where id in (select AuthorizationFormId from AuthorizationFormDataUse where DataUsePurpose.Name = 'Terms of Service') and effectivefromdate < TODAY and (effectivetodate =null or effectivetodate > TODAY)"

Get whether user consented to latest auth. form
sfdx force:data:soql:query -q "select id from AuthorizationFormConsent where ConsentGiverId='0PK3N000005ZK95WAG' AND AuthorizationFormTextId IN (select id from AuthorizationFormText where authorizationFormId='0cI3N0000008OKfUAM')"
