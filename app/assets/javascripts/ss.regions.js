/**
 * JavaScript wrappers for Locations.
 */

// Declare a ss (street seen) name space if it doesn't exist
var ss = ss || {};

/**
 * Region class
 */
ss.Region = function (id, name, description) {
  this.id = id;
  this.name = name;
  this.description = description;
}

/**
 * Updates a region.
 *
 * Used example here:
 * http://blog.project-sierra.de/archives/1788
 *
 * @param  {function} successHandler function to be called upon success.
 */
ss.Region.prototype.update = function(successHandler) {
  $.ajax({
    url:'/regions/' + this.id,
    // Expect JSON to be returned. This is also enforced on the server via mimetype.
    dataType: 'json',
    type: 'post',
    processData: false,
    contentType: "application/json",
    data: JSON.stringify({
      region: {
        id: this.id,
        name: this.name,
        description: this.description,
      }
    }),
    beforeSend: function(xhr) {
      xhr.setRequestHeader("X-Http-Method-Override", "PUT");
    },
    success: successHandler
    });
}


/**
 * Deletes a region
 *
 * Used example here:
 * http://humanwebdevelopment.com/rails-jquery-ajax-delete-and-put-methods/
 *
 * @param   {function} successHandler function to be called upon successful felete.
 */
ss.Region.prototype.delete = function(successHandler) {
  $.ajax({
    url: "/regions/" + this.id,
    type: "post",
    dataType: "json",
    data: {"_method":"delete"},
    type: 'POST',
    success: successHandler
  });
}
