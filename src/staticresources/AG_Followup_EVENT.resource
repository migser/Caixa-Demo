/**
    * @author CRMCulture
    * @version 1.00
    * @description BatchAdd a follow-up event from a Task or Event.
    *
    * @id AG_BatchAdd_FollowUpEvent   ActionGrid custom action id that is added to the name field.
    * @param kendoEntry               ActionGrid helper for Kendo UI modal entry forms.
    * @param kendoPopup               ActionGrid helper for Kendo UI model message windows.
    * @param sfdc                     ActionGrid helper for Salesforce REST API's
*/
crmc.require(["KendoEntry", "KendoPopup", "sfdc"], function(kendoEntry, kendoPopup, sfdc) {

  var CurrentObject = {
    object: {Name: "", Plural: ""},
  };
        
  var IsContext = function(object){
    objects = [
        {Name: "Task", Plural: "Tasks"},
        {Name: "Event", Plural: "Events"}
    ];
    for (var i = 0; i < objects.length; i++) {
        if(objects[i].Name === object){
            CurrentObject.object = objects[i];
            return true;
        }
    };
    return false;
  };

  crmc.addCustomAction({
    "itemID": "AG_BatchAdd_FollowUpEvent",
    "isBatchAddItem": true,
    "isAvailable": function (context) {
      var isCorrectContext = IsContext(context.objectDescribe.name) ;
      var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
      var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false
      return isCorrectContext && multipleSelected && isEnabled;
    },
    "getLabel": function (context) {
      return "Follow-Up Event";
    },
    "createSubmenuItems": function (context) {
      return [];
    },
    "click": function (context) {

      function IsPlural(){
        return (context.selectedRows.length === 1 ? "" : "s");
      }
      /** Language strings.*/
      var TEXT_BATCH_ADD_OBJECT = "Batch Add Events"
      var TEXT_ERROR = "There was an error: ";
      var TEXT_MESSAGE = "Added {0} Event" + IsPlural() + ", review the record" + IsPlural() + " with Preview or Browse Records.";
      var TEXT_BATCH_ADD_RESULTS = "Batch Add Results";
      var TEXT_YES = "Okay";
      var TEXT_NO = "No";


      function Process(Subject, StartDateTime, EndDateTime, IsAllDayEvent, Description){
        var ids = [];
        for (var i = 0; i < context.selectedRows.length; i++) {
          ids.push(context.selectedRows[i].id);
        };

        //Query for the data that needs to be passed into new records.
        var results = sfdc.query("SELECT Id, WhoId, WhatId FROM " + CurrentObject.object.Name + " WHERE Id IN('" + ids.join("','") + "')");

        //Loop through each result and pull the data.
        var records = [];
        for (var i in results) {
          var record = new sforce.SObject('Event');
          for (var j in ids) { 
            if(ids[j] === results[i].Id){
              record.Subject = Subject;
              record.StartDateTime = StartDateTime;
              record.EndDateTime = EndDateTime;
              record.IsAllDayEvent = IsAllDayEvent;
              record.Description = Description;
              record.WhoId = results[i].WhoId;
              record.WhatId = results[i].WhatId;
              records.push(record);
              break;
            };
          };
        };

        var onfailure = function(error) {
          alert(TEXT_ERROR + (error.message || error.faultstring));
        };

        sforce.connection.create(records, {
          onSuccess: function(results) {
            // Get the new record Ids
            var recordIds = [];
            $.each(results, function(i, row) {
              if (row.errors) {
                onfailure(row.errors);
                return;
              }
              recordIds.push(row.id);
            });
            if (results.length == recordIds.length) {
              var message = kendo.format(TEXT_MESSAGE, results.length);
              var buttons = [{
                label: TEXT_YES,
                click: function() {
                  window.open(kendo.format("/apex/CRMC_PP__crmc_grid?object={0}&Ids={1}", 'Event', recordIds.join()));
                }
              }
              ];
              kendoPopup.popupWithButtons(TEXT_BATCH_ADD_RESULTS, message, buttons);
            }
          },
          onFailure: onfailure
        });
      }
      
      function GetPicklist(table, field){
        //Get the object describe.
        var fields = sfdc.getSObjectDescribe(table).fields;
        //Loop through table fields.
        for (var i = 0; i < fields.length; i++) {
            //Find the picklist.
          if (fields[i].name === field){
            //return the values.
            return fields[i].picklistValues;
          }
        };
      }
      
      KendoEntry.entry("Batch Add Follow-Up Events",
        [
          {name: "Subject", label: 'Subject', type: "number", required: true},
          {name: "StartDateTime", label: 'Start', type: "datetime", required: true},
          {name: "EndDateTime", label: 'End', type: "datetime", required: true},
          {name: "IsAllDayEvent", label: 'All-Day Event', type: "boolean", required: true},
          {name: "Description", label: 'Description', type: "textarea", required: true}
        ], 
        {width: 350},
        null,
        function(selectedValues) {
          var Subject = selectedValues["Subject"].value;
          var StartDateTime = selectedValues["StartDateTime"].value;
          var EndDateTime = selectedValues["EndDateTime"].value;
          var IsAllDayEvent = selectedValues["IsAllDayEvent"].value;
          var Description = selectedValues["Description"].value;
          Process(Subject, StartDateTime, EndDateTime, IsAllDayEvent, Description);
      });
    }
  });
});