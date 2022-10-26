@isTest
public class AccountSelectorTest {

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
        test.startTest();
        AccountSelector selector = new AccountSelector();
        test.stopTest();
        
        System.assertEquals('Account', selector.objectName, 'The Selector should have identified the appropriate sObject type');
    }
    
    //NOTE! This test is unnecessary in your actual org, I'm just including it here to show that the fields specified in the Selector instance are, in fact, populated on instantiation.
    @isTest
    private static void itShouldInitializeWithAppropriateFieldsSpecified(){     
        test.startTest();
        AccountSelector selector = new AccountSelector();
        test.stopTest();
        
        System.assertEquals(3, selector.fieldsToSelect.size(), '3 fields should be specified, as populateFieldsToSelect is not overridden and 2 additional fields were specified');
        //Multiple asserts in this test because this behavior is bundled together. Only matters that there are 3 fields IF they are the RIGHT fields
        System.assert(selector.fieldsToSelect.contains('Id'), 'Id field should be specified by default');
        System.assert(selector.fieldsToSelect.contains('Phone'), 'Phone field should be included as it was specified in the call to Initialize');
        System.assert(selector.fieldsToSelect.contains('Name'), 'Name field should be included as it was specified in the call to Initialize');
    }
    
    //NOTE! This test is unnecessary in your actual org, I'm just including it here to show that the fields specified in the Selector instance
    //AND additional fields specified are, in fact, populated on instantiation.
    @isTest
    private static void itShouldInitializeWithAdditionalFieldsSpecified(){
        Set<String> additionalFields = new Set<String>{
            'AccountSource',
                'OwnerId'
        };
        test.startTest();
        AccountSelector selector = new AccountSelector(additionalFields);
        test.stopTest();
        
        System.assertEquals(5, selector.fieldsToSelect.size(), '5 fields should be specified, as 2 additional fields were specified');
        //Multiple asserts in this test because this behavior is bundled together. Only matters that there are 3 fields IF they are the RIGHT fields
        System.assert(selector.fieldsToSelect.contains('Id'), 'Id field should be specified by default');
        System.assert(selector.fieldsToSelect.contains('Phone'), 'Phone field should be included as it was specified in the call to Initialize');
        System.assert(selector.fieldsToSelect.contains('Name'), 'Name field should be included as it was specified in the call to Initialize');
        System.assert(selector.fieldsToSelect.contains('AccountSource'), 'AccountSource field should be included as it was specified in the constructor');
        System.assert(selector.fieldsToSelect.contains('OwnerId'), 'OwnerId field should be included as it was specified in the call to constructor');
    }
    
    @isTest
    private static void itShouldSelectAll(){
        List<Account> controlAccounts = [SELECT Id, Name, AccountNumber
                                         FROM Account
                                         LIMIT 50000];
        //Sanity check
        System.assert(!controlAccounts.isEmpty(), 'For this test to be valid, some accounts must exist.');
        
        AccountSelector selector = new AccountSelector();
        
        test.startTest();
        //Note that we don't have to cast from sObject to Account, it just happens magically! Woo!
        List<Account> actualAccounts = selector.selectAll();
        test.stopTest();
        
        System.assertEquals(controlAccounts.size(), actualAccounts.size(), 'The correct number of records should have been returned');
    }
}