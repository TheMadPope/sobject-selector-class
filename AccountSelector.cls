/**
 * Example selector implementation, using the Account object
 * @created 2022-10-21 - Richard E. Moore
 */
public class AccountSelector extends SObjectSelector{
    
    /**
     * Default constructor, sets object type and standard fields to select in all queries
     * @created 2022-10-21 - Richard E. Moore
     */
    public AccountSelector(){
        Initialize(Account.getSObjectType());
    }
    
    /**
     * Default constructor, sets object type and standard fields to select in all queries
     * Also adds additional fields specified by the caller. This way some use cases can have specific fields
     * @created 2022-10-21 - Richard E. Moore
     */
    public AccountSelector(Set<String> additionalFields){
        Initialize(Account.getSObjectType(), additionalFields);
    }
    
    /**
     * Populates the fields to select for all queries.
     * Add here any fields that should be present in NEARLY ALL queries against this object
     * @created 2022-10-21 - Richard E. Moore
     */
    public override void populateFieldsToSelect(){
        fieldsToSelect = new Set<String>{
            'Id',
                'Name',
                'RecordTypeId'
        };
    }
}
