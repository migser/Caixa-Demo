crmc.require(["KendoEntry", "KendoPopup", "ListButton", "sfdc"], function(prompt, popup, navigate, sfdc) {

    /**
        * @author CRMCulture
        * @description Basic batch create example
    */

    /**
        *   "ITEM_ID" Is the ID that uniquely identifies our Action item.
        *   "CONTEXT_OBJECT" Is the context object that your action is based on.
        *   "CREATE_OBJECT" Is the name of the object that you are batch creating and/or updating.
        *   "SINGULAR_NAME" Is the singular label text of CREATE_OBJECT.
        *   "PLURAL_NAME" Is the plural version of the SINGULAR_NAME.
    */
    var ITEM_ID = "Batch_Add_Campaign_Members_MSerrano";
    var CONTEXT_OBJECT = "Account";
    var CREATE_OBJECT = "Campana__c";
    var SINGULAR_NAME = "Campaign Member";
    var PLURAL_NAME = "Campaign Members";

    /**
        *   "FIELD_SET_NAME" Is the name of a field set based on the object that you are creating.
            This is the template of fields used when creating the modal form window.
        *   "DEFAULT_FORM_VALUES" Is a list of Field Names and values used to populate the modal form fields.
            Each line item must be in the format of "Field Name": "Value" (include comma if not only or last item).
    */
    var FIELD_SET_NAME = "FIELDSETBATCHADD";
    var DEFAULT_FORM_VALUES = {
        /**Example*/
        //Probability: "60",
        //Amount: "0"
    }

    /** Language strings.*/
    var TEXT_BATCH_ADD_OBJECT = "Batch Add to Campaign";
    var TEXT_ERROR = "There was an error: ";
    var TEXT_MESSAGE = "Added {0} " + PLURAL_NAME + ", would you like to ActionGrid the results?";
    var TEXT_BATCH_ADD_RESULTS = "Batch Add Results";
    var TEXT_YES = "Yes";
    var TEXT_NO = "No";

    /**
        *   "SET_CUSTOM_RECORD_VALUES" Is a function that sets the specified values "Under the hood" rather than by a form.
            Please note that you do not have access to fields that are not currently loaded into the grid.
        *   @row
        *   @record
    */
    var SET_CUSTOM_RECORD_VALUES = function(SELECTED_ROW, NEW_RECORD){
        /**Required, set the Primary ID of each row to the Foreign Key relationship.*/
        NEW_RECORD.AccountId__c = SELECTED_ROW.Id;

        /** Set other default values below.*/
        //Example// NEW_RECORD.ContactId = SELECTED_ROW.ContactId;
        //Example// NEW_RECORD.Comments = SELECTED_ROW.Description;
    }

    //////////////////////////////////////
    /**
        * Custom action core code below.
    */
    //////////////////////////////////////

    // Define a custom action for batch adding
    crmc.addCustomAction({
        // Uniquely identifies our Action item
        "itemID": ITEM_ID,
        // Indicates this item should appear under batch add menu
        "isBatchAddItem": true,
        "isAvailable": function (context) {
            // This function is called before the action item is displayed and returns a boolean if the item should be displayed
            // By default determine availability based on Feature Security for this action
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            // Only allow batch adding from Accounts object for now
            var isAccessible = context.objectDescribe.name == CONTEXT_OBJECT;
            var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
            return isAccessible && isEnabled && multipleSelected;
        },
        "getLabel": function (context) {
            // This function returns the display label of the action item and is calld before the item is shown
            // Note the use of kendo ui library can be used in any actions
            return kendo.format(PLURAL_NAME + " ({0}) ", context.selectedRows.length);
        },
        "click": function (context) {
            var records = [];
            // Show a prompt that contains the fields in FIELDSETNAME
            prompt.fieldSetEntry(TEXT_BATCH_ADD_OBJECT, CREATE_OBJECT, FIELD_SET_NAME, DEFAULT_FORM_VALUES, function(values) {
                var recordIds = [];
                
                var onfailure = function(error) {
                    alert(TEXT_ERROR + (error.message || error.faultstring));
                };

                var onsuccess = function(results){
                    $.each(results, function(i, row) {
                        if (row.errors) {
                            // Handle first error if any
                            onfailure(row.errors);
                            return;
                        }
                        recordIds.push(row.id);
                    });
                    if (results.length == recordIds.length) {
                        // Prompt to navigate the user to the results
                        var message = kendo.format(TEXT_MESSAGE, results.length);
                        var buttons = [{
                            label: TEXT_YES,
                            click: function() {
                                // Navigate to a list of just these recordIds
                                window.open(kendo.format("/apex/CRMC_PP__crmc_grid?object={0}&Ids={1}", CREATE_OBJECT, recordIds.join()));
                            }
                        },
                        {
                            label: TEXT_NO
                        }];
                        popup.popupWithButtons(TEXT_BATCH_ADD_RESULTS, message, buttons);
                    }
                }

                var process = function(){
                    sforce.connection.create(records, {
                        onSuccess: onsuccess,
                        onFailure: onfailure
                    });
                } 

                // For every selected row.
                // Set custom values.
                // Set prompt values.
                context.selectedRows.map(function(row) {
                    var record = new sforce.SObject(CREATE_OBJECT);
                    SET_CUSTOM_RECORD_VALUES(row, record);
                    for (var field in values) {
                        record[field] = values[field].value;
                    }
                    records.push(record);
                });

                if(context.selectedRows.length > 200){
                    sfdc.batchInsert(records, onsuccess) 

                } else {
                    process();
                }
            });
        }
    });
});