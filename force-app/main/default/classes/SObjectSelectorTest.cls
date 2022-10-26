@isTest
public class SObjectSelectorTest {

    @testSetup
    private static void testsetup(){
        List<Account> accounts = new List<Account>();
        accounts.add(buildAccount('TestAccount', '0'));
        accounts.add(buildAccount('TestAccount', '1'));
        accounts.add(buildAccount('TestAccount', '2'));
        accounts.add(buildAccount('TestAccount', '3'));
        accounts.add(buildAccount('TestAccount', '4'));
        accounts.add(buildAccount('TestAccount', '5'));
        accounts.add(buildAccount('TestAccount', '6'));
        accounts.add(buildAccount('TestAccount', '7'));
        accounts.add(buildAccount('TestAccount', '8'));
        accounts.add(buildAccount('TestAccount', '9'));
        Database.insert(accounts);
    }
    
    private static Account buildAccount(String accountNameToSet, String accountNumberToSet){
        Account thisAccount = new Account(
            Name = accountNameToSet,
                AccountNumber = accountNumberToSet
        );
        return thisAccount;
    }
    
    @isTest
    private static void itShouldInitializeToCorrectObject(){
        sObjectSelector selector = new sObjectSelector();
        
        test.startTest();
        selector.Initialize(Account.getSObjectType());
        test.stopTest();
        
        System.assertEquals('Account', selector.objectName, 'The Selector should have identified the appropriate sObject type');
    }
    
    @isTest
    private static void itShouldInitializeWithOneFieldSpecified(){
        sObjectSelector selector = new sObjectSelector();
        
        test.startTest();
        selector.Initialize(Account.getSObjectType());
        test.stopTest();
        
        System.assertEquals(1, selector.fieldsToSelect.size(), '1 and only 1 field should be specified, as populateFieldsToSelect is not overridden');
    }
    
    @isTest
    private static void itShouldInitializeWithIdSpecified(){
        sObjectSelector selector = new sObjectSelector();
        
        test.startTest();
        selector.Initialize(Account.getSObjectType());
        test.stopTest();
        
        System.assert(selector.fieldsToSelect.contains('Id'), 'Id field should be specified by default');
    }
    
    @isTest
    private static void itShouldInitializeWithAdditionalFieldsSpecified(){
        sObjectSelector selector = new sObjectSelector();
        
        Set<String> fields = new Set<String>{
            'RecordTypeId',
                'Name'
        };
        
        test.startTest();
        selector.Initialize(Account.getSObjectType(), fields);
        test.stopTest();
        
        System.assertEquals(3, selector.fieldsToSelect.size(), '3 fields should be specified, as populateFieldsToSelect is not overridden and 2 additional fields were specified');
        //Multiple asserts in this test because this behavior is bundled together. Only matters that there are 3 fields IF they are the RIGHT fields
        System.assert(selector.fieldsToSelect.contains('Id'), 'Id field should be specified by default');
        System.assert(selector.fieldsToSelect.contains('RecordTypeId'), 'RecordTypeId field should be included as it was specified in the call to Initialize');
        System.assert(selector.fieldsToSelect.contains('Name'), 'Name field should be included as it was specified in the call to Initialize');
    }
    
    @isTest
    private static void itShouldGetFirstRecordFromListWhenListPopulated(){
        List<Account> records = [SELECT Id, AccountNumber FROM Account WHERE AccountNumber !=null ORDER BY AccountNumber DESC LIMIT 10];
        String expectedAccountNumber = records[0].AccountNumber;
        
        test.startTest();
        Account result = (Account)new SObjectSelector().getFirstRecordFromList(records);
        test.stopTest();
        
        System.assertEquals(expectedAccountNumber, result.AccountNumber, 'The first record should have been returned');
    }
    
    @isTest
    private static void getFirstRecordFromListShouldReturnNullWhenListNotPopulated(){
        List<Account> records = new List<Account>();
        
        test.startTest();
        Account result = (Account)new SObjectSelector().getFirstRecordFromList(records);
        test.stopTest();
        
        System.assertEquals(null, result, 'Null should have been returned as the list was empty');
    }
    
    @isTest
    private static void itShouldBuildBaseQueryProperly(){
        sObjectSelector selector = new sObjectSelector();
        selector.fieldsToSelect = new Set<String>{
            'Id',
                'Name',
                'AccountNumber'
        };
        selector.objectName = 'Account';
        
        test.startTest();
        String actualQuery = selector.buildBaseQuery();
        test.stopTest();
        
        String expectedQuery = 'SELECT Id, Name, AccountNumber FROM Account';
        
        System.assertEquals(expectedQuery, actualQuery, 'The Query should have been constructed as expected: Correct fields, correct object, no clauses');        
    }
    
    @isTest
    private static void itShouldSelectRecordById(){
        Account expectedAccount = [SELECT Id, Name FROM Account ORDER BY Name DESC NULLS LAST LIMIT 1];
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        sObject actualAccount = selector.selectById(expectedAccount.Id);
        test.stopTest();
        
        System.assertEquals(expectedAccount.Id, actualAccount.Id, 'The correct record should have been returned');
    }
    
    @isTest
    private static void itShouldSelectRecordsByIds(){
        integer myLimit = 10;
        List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name DESC NULLS LAST LIMIT :myLimit];
        Set<Id> ids = new Set<Id>();
        for (Account thisAccount :accounts){
            ids.add(thisAccount.Id);
        }
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectByIds(ids);
        test.stopTest();
        
        System.assertEquals(myLimit, actualAccounts.size(), 'The correct number of records should have been returned');
    }
    
    @isTest
    private static void itShouldSelectSingleRecordByFieldValue(){
        Account controlAccount = [SELECT Id, Name, AccountNumber
                                  FROM Account
                                  WHERE AccountNumber !=null
                                  ORDER BY AccountNumber DESC
                                  LIMIT 1];
        String accountNumber = controlAccount.AccountNumber;
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectByFieldValue('AccountNumber', accountNumber);
        test.stopTest();
        
        System.assertEquals(1, actualAccounts.size(), 'The correct number of records should have been returned');
        System.assertEquals(controlAccount.Id, actualAccounts[0].Id, 'The correct record should have been returned');
    }
    
    @isTest
    private static void itShouldSelectMultipleRecordsByFieldValue(){
        String nameToUse = 'TestAccount';
        List<Account> controlAccounts = [SELECT Id, Name, AccountNumber
                                         FROM Account
                                         WHERE Name =:nameToUse
                                         ORDER BY AccountNumber DESC];
        //Sanity check
        System.assert(!controlAccounts.isEmpty(), 'For this test to be valid, some accounts with the name ' + nameToUse + ' must exist.');
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectByFieldValue('Name', nameToUse);
        test.stopTest();
        
        System.assertEquals(controlAccounts.size(), actualAccounts.size(), 'The correct number of records should have been returned');
    }
    
    @isTest
    private static void itShouldSelectMultipleRecordsByFieldValues(){
        Set<String> values = new Set<String>{
            '1',
                '2',
                '3'
        };
        List<Account> controlAccounts = [SELECT Id, Name, AccountNumber
                                         FROM Account
                                         WHERE AccountNumber IN:values
                                         ORDER BY AccountNumber DESC];
        //Sanity check
        System.assert(!controlAccounts.isEmpty(), 'For this test to be valid, some accounts with the expected AccountNumber values (1, 2, 3) must exist.');
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectByFieldValues('AccountNumber', values);
        test.stopTest();
        
        System.assertEquals(controlAccounts.size(), actualAccounts.size(), 'The correct number of records should have been returned');
    }
    
    @isTest
    private static void itShouldSelectAll(){
        List<Account> controlAccounts = [SELECT Id, Name, AccountNumber
                                         FROM Account
                                         LIMIT 50000];
        //Sanity check
        System.assert(!controlAccounts.isEmpty(), 'For this test to be valid, some accounts must exist.');
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectAll();
        test.stopTest();
        
        System.assertEquals(controlAccounts.size(), actualAccounts.size(), 'The correct number of records should have been returned');
    }
    
    @isTest
    private static void itShouldBuildApplyClauseOnSelectAll(){
        Integer myLimit = 7;
        List<Account> controlAccounts = [SELECT Id, Name, AccountNumber
                                         FROM Account
                                         LIMIT :myLimit];
        //Sanity check
        System.assert(!controlAccounts.isEmpty(), 'For this test to be valid, some accounts must exist.');
        
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        selector.recordLimit = myLimit;
        
        test.startTest();
        List<sObject> actualAccounts = selector.selectAll();
        test.stopTest();
        
        System.assertEquals(controlAccounts.size(), actualAccounts.size(), 'The correct number of records should have been returned');
    }
    
    @isTest
    private static void itShouldBuildCorrectLimitClauseWithSpecifiedValue(){
        Integer myLimit = 7;
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        selector.recordLimit = myLimit;
        
        test.startTest();
        String actualClause = selector.buildLimitClause();
        test.stopTest();
        
        System.assertEquals('LIMIT 7', actualClause, 'The LIMIT clause should have been built properly (spacing, value)');
    }
    
    @isTest
    private static void itShouldBuildCorrectLimitClauseWithDefaultValue(){
        sObjectSelector selector = new sObjectSelector();
        selector.Initialize(Account.getSObjectType());
        
        test.startTest();
        String actualClause = selector.buildLimitClause();
        test.stopTest();
        
        System.assertEquals('LIMIT ' + SObjectSelector.DEFAULT_LIMIT, actualClause, 'The LIMIT clause should have been built properly with default value (spacing, value)');
    }
}