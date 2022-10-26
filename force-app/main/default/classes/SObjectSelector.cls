/**
 * Base (Virtual) class to be used by Selector implementations.
 * Selectors should house all SOQL SELECT actions (where reasonable).
 * This pattern allows predictable reuse of queries, and allows for speedy development of new code.
 * @created 2022-10-21 - Richard E. Moore
 * @todo - Add support for PAGING and OFFSET
 * @todo - Add queryParameter class to allow easy application of query parameters
 * @todo - Add orderClause class to allow easy application of ordering, including default ordering
 */
public inherited sharing virtual class SObjectSelector {
    
    /**
     * Fields that will be included in all queries (unless overwritten by subclass)
     */
    public Set<String> fieldsToSelect { get; set; }

    /**
     * sObjectType to be queried
     */
    public Schema.SObjectType sObjectType { get; set; }

    /**
     * describeResult of the sObjectType to be queried, kept around in case it's useful by the subclass
     */
    public Schema.DescribeSObjectResult describeResult { get ;set; }

    /**
     * Basic name for the object
     */
    public String objectName { get ;set; }

    /**
     * LIMIT to be applied to the query
     */
    public integer recordLimit { get; set; }

    /**
     * Avoids multiple instances of duplicate string, avoids typos
     */
    private static final String SPACE = ' ';

    /**
     * Default LIMIT to be applied to the query if recordLimit is not specifically set
     */
    @testVisible
    private static final integer DEFAULT_LIMIT = 50000;

    /**
     * Should be invoked in the implementing class's Constructor.
     * Sets the type (sObject that we are going to select from) and the default fields to select.
     * @param objectTypeToSelect (Schema.SObjectType): The sObject from which we will select
     */
    public void Initialize(Schema.SObjectType objectTypeToSelect){
        populateFieldsToSelect();
        privateInitialize(objectTypeToSelect);
    }

    /**
     * Should be invoked in the implementing class's Constructor.
     * Sets the type (sObject that we are going to select from) and the default fields to select, PLUS some additional fields needed for this instance.
     * @param objectTypeToSelect (Schema.SObjectType): The sObject from which we will select
     * @param additionalFields (Set<String>): Additional fields to add to the query
     */
    public void Initialize(Schema.SObjectType objectTypeToSelect, Set<String> additionalFields){
        populateFieldsToSelect();
        addFields(additionalFields);
        privateInitialize(objectTypeToSelect);
    }

    /**
     * If this method is not overridden in the implementation, adds the Id to the fields to select.
     */
    public virtual void populateFieldsToSelect(){
        if (fieldsToSelect==null){
            fieldsToSelect = new Set<String>{
                'Id'
            };
        }
    }

    /**
     * Adds fields to the query
     * Note that this can be called by the implementing class
     * @param additionalFields (Set<String>): Additional fields to add to the query
     */
    @testVisible
    private void addFields(Set<String> additionalFields){
        fieldsToSelect.addAll(additionalFields);
    }

    /**
     * Sets default values for the constructor
     * @param objectTypeToSelect (Schema.SObjectType): The sObject from which we will select
     */
    @testVisible
    private void privateInitialize(Schema.SObjectType objectTypeToSelect){
        sObjectType = objectTypeToSelect;
        describeResult = sObjectType.getDescribe();
        objectName = describeResult.getName();
        recordLimit = DEFAULT_LIMIT;
    }

    /**
     * Simple helper to get the first item from a list.
     * Our generic queries typically return a List of records, but often we only want one (or null if not present)
     * For example, if we are querying by Id, we get a List because we're reusing common components, but we only ever want one record.
     * @param records (List<sObject>): List of sObjects returned by the query
     * @return sObject: First sObject from the query results or null
     */
    public sObject getFirstRecordFromList(List<sObject> records){
        //Not using ternary operator here for readability only
        if (records.isEmpty()){
            return null;
        }
        return records[0];
    }

    /**
     * Using the fieldsToSelect and the objectName, builds a basic query without any WHERE, ORDER, or LIMIT applied.
     * Additional query parameters can be set by calling methods.
     * @return String: String of the SOQL query without any WHERE or ORDER clauses
     */
    @testVisible
    private String buildBaseQuery(){
        String query = String.join(new List<String>(fieldsToSelect), ', ');
        List<String> queryParts = new List<String>{
            'SELECT',
                query,
                'FROM',
                objectName
        };
        query = String.join(queryParts, SPACE);
        return query;
    }

    /**
     * Uses Security.stripInaccessible to remove any fields to which the current running user does not have READ access
     * @param records (List<sObject>): The initial results of the SOQL query
     * @return List<sObject>: Records with only the fields to which the user has READ access
     */
    public List<sObject> secureRead(List<sObject> records){
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, records);
        return decision.getRecords();
    }

    /**
     * Most commonly used query, filtering by the Record Id passed in
     * @param recordId (Id): Id of the record to fetch
     * @return sObject: The result of the query, or null if not found.
     */
    public virtual sObject selectById(Id recordId){
        List<String> queryParts = new List<String>{
            buildBaseQuery(),
                'WHERE Id=:recordId',
                buildLimitClause()
        };
        String query = String.join(queryParts, SPACE);
        List<sObject> records = secureRead(Database.query(String.escapeSingleQuotes(query)));
        return getFirstRecordFromList(records);
    }

    /**
     * Commonly used query, filtering by the Set of Record Ids passed in
     * @param recordIds (Set<Id>): Ids of the records to fetch
     * @return List<sObject>: Results of the query
     */
    public virtual List<sObject> selectByIds(Set<Id> recordIds){
        List<String> queryParts = new List<String>{
            buildBaseQuery(),
                'WHERE Id IN:recordIds',
                buildLimitClause()
        };
        String query = String.join(queryParts, SPACE);
        List<sObject> records = secureRead(Database.query(String.escapeSingleQuotes(query)));
        return records;
    }

    /**
     * Commonly used query, filtering by a single value in an sObject field
     * @param fieldName (String): The name of the field on which to filter
     * @param fieldValue (String): The value by which to filter
     * @return List<sObject>: Results of the query
     */
    public virtual List<sObject> selectByFieldValue(String fieldName, String fieldValue){
        List<String> queryParts = new List<String>{
            buildBaseQuery(),
            'WHERE',
            fieldName,
            '=:fieldValue',
            buildLimitClause()
        };
        String query = String.join(queryParts, SPACE);
        List<sObject> records = secureRead(Database.query(String.escapeSingleQuotes(query)));
        return records;
    }

    /**
     * Commonly used query, filtering by a set of values in an sObject field
     * @param fieldName (String): The name of the field on which to filter
     * @param fieldValue (Set<String>): The values by which to filter
     * @return List<sObject>: Results of the query
     */
    public virtual List<sObject> selectByFieldValues(String fieldName, Set<String> fieldValues){
        List<String> queryParts = new List<String>{
            buildBaseQuery(),
            'WHERE',
            fieldName,
            'IN:fieldValues',
            buildLimitClause()
        };
        String query = String.join(queryParts, SPACE);
        List<sObject> records = secureRead(Database.query(String.escapeSingleQuotes(query)));
        return records;
    }

    /**
     * Selects 'all' records from a given sObject, limited by the default or specific limit
     * @return List<sObject>: Results of the query
     */
    public virtual List<sObject> selectAll(){
        List<String> queryParts = new List<String>{
            buildBaseQuery(),
                buildLimitClause()
        };
        String query = String.join(queryParts, SPACE);
        List<sObject> records = secureRead(Database.query(String.escapeSingleQuotes(query)));
        return records;
    }

    /**
     * Builds a simple limit clause using the limit specified by implementation, or the default (SOQL maximum of 50K)
     * @return String: Limit clause
     */
    @testVisible
    private String buildLimitClause(){
        //limit is either set (to default max) in the privateInitialize method (which should be called on all constructions)
        //OR it has been deliberately set by the calling code.
        //So here we're going to just build a clause.
        return 'LIMIT ' + recordLimit;
    }
}
