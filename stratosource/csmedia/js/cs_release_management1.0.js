/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
function promptAddStories(){
    $("#storyList" ).dialog(
    {
        buttons:
        {
            "Cancel": function()
             {
                 $(this).dialog("close");
             },
            "Add to Release": function()
             { 
                var query = 'releaseid=' + $("#release").val()
                    + "&storyId=" + $("#storyId").val();
                addToStory(query, this);
             }
         }, 
         modal: true,
         minWidth: 600,
         maxWidth: 600,
         maxHeight: 300,
         minHeight: 300,
         height: 300
     });
}

function addToStory(query, modal){
    $(modal).dialog( "disable" );
    $.ajax({
      url: "/ajax/addstoriestorelease",
      data: query,
      cache: false,
      success: function(json){
          if(json.success){
              document.location.reload();
          } else {
              alert(json.error);
          }
      }
    });
}

