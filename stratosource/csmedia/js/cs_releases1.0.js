/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

function newRelease(branch) {
     $("#createRelease" + branch).show();
     $("#createReleaseLink" + branch).hide();
     if ($("#" + branch + "releasesListE"))
        $("#" + branch + "releasesListE").hide();
}

function refreshReleases(branch){
    $.ajax({
      url: "/ajax/releases",
      cache: false,
      data: "branch=" + branch,
      success: function(html){
         var rows = $("tr");
         for(var i = 0; i < rows.length; i++){
            if (rows[i].id.match('^' + branch + 'releasesList')){
                $("#" + rows[i].id).remove();
            }
         }
         $("#" + branch + "headers").after(html);
      }
    });
}

function cancelCreate(branch){
    $("#createRelease" + branch).hide();
    $("#createReleaseLink" + branch).show();
    $( "#estRelDate" + branch ).val('');
    $( "#relName" + branch ).val('');
    if ($("#" + branch + "releasesListE"))
        $("#" + branch + "releasesListE").show();
}

function createRelease(branch){
    $.ajax({
      url: "/ajax/createrelease",
      cache: false,
      data: "branch=" + encodeURI(branch) + "&name=" + encodeURI($( "#relName" + branch ).val()) + "&estRelDate=" +  $( "#estRelDate" + branch ).val(),
      success: function(data){
          if (!data.success){
               alert(data.error)
          } else {
               refreshReleases(branch);
               $("#createRelease" + branch).hide();
               $("#createReleaseLink" + branch).show();
               $( "#estRelDate" + branch ).val('');
               $( "#relName" + branch ).val('');
          }
      }
    });
}

function deleteRelease(id, name, branch){
    if (confirm("Are you sure you want to delete '" + name + "'?")){
        $.ajax({
          url: "/ajax/deleterelease",
          cache: false,
          data: "id=" + id + "&branch=" + branch,
          success: function(html){
            refreshReleases(branch);
          }
        });
        }
}

function markReleased(id, name, branch, refreshPage){
    if (confirm("Are you sure you want to mark '" + name + "' released? This cannot be undone!")){
        $.ajax({
          url: "/ajax/markreleased",
          cache: false,
          data: "id=" + id,
          success: function(json){
            if (json.success && !refreshPage){
                refreshReleases(branch);
            } if (json.success && refreshPage) {
                location.reload();
            } else {
                alert(json.error);
            }
          }
        });
        }
}

function updateReleaseDate(releaseId, date, branch){
    $.ajax({
      url: "/ajax/updatereleasedate",
      cache: false,
      data: "id=" + releaseId + "&date=" + encodeURI(date),
      success: function(json){
          if(json.success){
              refreshReleases(branch);
          } else {
              alert(json.error);
          }
      }
    });
}
