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

///////////////////////////////////////////
// Task Related
///////////////////////////////////////////

editingTask = '';
lastValue = '';

function refreshTasks(){
    if (cancelEdit()){
        jQuery('#taskList').load('/ajax/releasetasks/' + release_id);
        editingTask = '';
        lastValue = '';
    }
}

function addTask(){
    task = jQuery('#taskName').val();
    if (task != null && task != ''){
        jQuery.ajax({
          url: "/ajax/addreleasetask/?rel_id={{ release.id }}&task=" + escape(task),
          success: function(){
            refreshTasks();
            jQuery('#taskName').val('');
          }
        });
    }
    
}

function flagTask(release_id, id, is_checked, branch_id){
    jQuery.ajax({
      url: "/ajax/editreleasetask/?rel_id=' + release_id + '&task_id=" + id + '&done=' + is_checked + '&branch_id=' + branch_id,
      success: function(){
      }
    });
    
}

function deleteTask(id){
    if (confirm('Are you sure?')){
        jQuery.ajax({
          url: "/ajax/delreleasetask/?rel_id={{ release.id }}&task_id=" + id,
          success: function(){
            refreshTasks();
          }
        });
    }            
}

function editTask(id){
    if (editingTask == id)
        return;

    if (!cancelEdit()){
        return;
    }
    
    editingTask = id;
    curVal = jQuery('#' + id + 'Name').html();
    lastValue = curVal;
    jQuery('#' + id + 'Name').html('<textarea id="taskName' + id + '" name="taskName' + id + '" cols="100" rows="2">' + curVal + '</textarea>');
    if (!jQuery('#save' + id).is(":visible")){
        jQuery('#save' + id).css('display','inline');
        jQuery('#cancel' + id).css('display','inline');
        jQuery('#delete' + id).toggle();        
        jQuery('#edit' + id).toggle();
    }
}

function cancelEdit(){
    if (editingTask == ''){
        return true;
    } else {
        if (!confirm('Are you sure? You will loose changes on the current item you are editing.')){
            return false;
        }
    }
    
    id = editingTask;
    jQuery('#' + id + 'Name').html(lastValue);
    if (jQuery('#save' + id).is(":visible")){
        jQuery('#save' + id).css('display','none');
        jQuery('#cancel' + id).css('display','none');
        jQuery('#delete' + id).toggle();        
        jQuery('#edit' + id).toggle();
    }
    editingTask = '';
    lastValue = '';
    
    return true;
}

function saveTask(id, branch_id){
    newVal = jQuery('#taskName' + id).val();
    jQuery.ajax({
      url: "/ajax/editreleasetask/?rel_id={{ release.id }}&task_id=" + id + '&newVal=' + escape(newVal) + '&branch_id=' + branch_id,
      success: function(){
        editingTask = '';
        lastValue = '';
        refreshTasks();
      }
    });    
}

// Return a helper with preserved width of cells
var fixHelper = function(e, ui) {
    ui.children().each(function() {
        jQuery(this).width($(this).width());
    });
    return ui;
};
 
var updateHelper = function(e, ui) {
    orderList = jQuery("#sortable tbody").sortable( "toArray" );
    jQuery.ajax({
      url: "/ajax/reorderreleasetasks/?order=" + orderList,
      success: function(){
        refreshTasks();
      }
    });
};
