crmc.require(["KendoEntry", "KendoPopup", "ListButton", "sfdc"],
function(prompt, popup, navigate, sfdc) {
    crmc.addCustomAction({
        "itemID": "AG_AttachFile",
        "isAvailable": function (context) {
            var multipleSelected = context.selectedRows && context.selectedRows.length > 0 && context.selectedRows.length <= 5;
            if (multipleSelected && this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !==false){
               var children = context.objectDescribe.childRelationships;
               for (var i = 0; i < children.length; i++) {
                 if (children[i].childSObject == 'Attachment'){
                       return true;
                   }
               };
            }
            return false;
         },
         "getLabel": function (context) {
           return "Attach File";
         },
         "createSubmenuItems": function (context) {
             return [];
         },
         "click": function (context) {
             var ids = [];
             context.selectedRows.map(function(row) {
                 ids.push(row.Id);
             });
             var data = sfdc.query("SELECT Id, Name FROM "+context.objectDescribe.name+" WHERE Id IN('" + ids.join("','") + "')");
             for (var i = 0; i < data.length; i++) {
                 var row = data[i];
               if(row.Name != undefined && row.Name != null){
                   window.open("/p/attach/NoteAttach?pid=" + row.Id+"&parentname="+encodeURIComponent(row.Name));
               }
               else{
                   window.open("/p/attach/NoteAttach?pid="+row.Id);
               }
             };
          }
      });
});