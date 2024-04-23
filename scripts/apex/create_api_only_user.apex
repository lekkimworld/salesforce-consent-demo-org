User adminUser = [select Email, TimeZoneSidKey, LanguageLocaleKey from User where Name='User User' LIMIT 1];
final String timezone = adminUser.TimeZoneSidKey;
final String locale = adminUser.LanguageLocaleKey;
final String actualEmail = adminUser.Email;
final String fn = 'API';
final String ln = 'User';
final String alias = (fn.toLowerCase().substring(0, 1) + ln.toLowerCase()).substring(0,4) + String.valueOf(DateTime.now().getTime()).reverse().substring(0,4);
final String email = UserInfo.getOrganizationId() + '.' + fn.toLowerCase() + '.' + ln.toLowerCase() + '@example.com';

Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

User u = new User();
u.firstname = fn;
u.lastname = ln;
u.username = email;
u.email = actualEmail;
u.ProfileId = p.Id;
u.alias = alias;
u.EmailEncodingKey = 'UTF-8';
u.IsActive = true;
u.LanguageLocaleKey = 'en_US';
u.LocaleSidKey = locale;
u.TimeZoneSidKey = timezone;
insert u;

PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='Demo_API_Only' LIMIT 1];
PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id);
insert psa;
