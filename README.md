# sobject-selector-class
A reasonably lightweight selector class to streamline and centralize queries
Try it out:

<code>
Set<String> fields = new Set<String>();
fields.add('Site');
fields.add('AccountSource');
fields.add('Id');
AccountSelector s = new AccountSelector(fields);
List<Account> records = s.selectAll();
System.debug(Json.serializePretty(records));
</code>

**OR**

<code>
AccountSelector s = new AccountSelector();
List<Account> records = s.selectAll();
System.debug(Json.serializePretty(records));
</code>