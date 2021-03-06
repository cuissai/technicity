/**
 * An Object Oriented page handler for the curate process.
 */



// Declare a ss (street seen) name space if it doesn't exist
var ss = ss || {};
ss.handler = ss.handler || {};

ss.handler.Curate = function(regionId) {

  this.regionId = regionId;

  // These instance variables can easily be overridden by setting
  // the appropriate property.
  this.panoramaMapId = 'panorama-map';
  this.panoramaId = 'panorama';
  this.editModalId = 'edit-location-modal';
  this.deleteModalId = 'delete-location-modal';
  this.deleteRegionModalId = 'delete-region-modal';
  this.locationIdPrefix = 'location-';
  this.countId = 'location-count'
  this.quantityId = 'quantity';
  this.proximityId = 'proximity';

  this.panoramaMap = null;
  this.panorama = null;
  this.marker = null;

  this.locked = false;

}

ss.handler.Curate.prototype.initialize = function (mapId, center, zoom, path) {

  polygon = new ss.Polygon(path);
  this.polygonMap = new ss.PolygonMap(polygon, mapId, center, zoom, false);

  var $this = this;

  if (!this.locked) {
    this.polygonMap.markerClickCb = function() {
      // Fire the click handler of the curate link
      // $('#' + $this.locationIdPrefix + this.getZIndex()).click();
      $this.editLocation(this.data.id, this.data.latitude , this.data.longitude, this.data.heading, this.data.pitch);
    }
  }

  this.polygonMap.markerPersistCb = function(position) {
    ss.Location.create($this.regionId, position.lat(), position.lng(), function(location, status, xhr) {

      // Promote our point from a pending point to a full marker
      point = new google.maps.LatLng(location.latitude, location.longitude);
      $this.polygonMap.promotePendingToMarker(location.id, point);

      // Update our counter
      $('#' + $this.countId).html($this.polygonMap.markers.length);

      // We should append a linked image below
      $(
        '<a>',
        {
          id: $this.locationIdPrefix + location.id,
          class: 'thumbnail cursor new',
          'data-toggle': 'modal',
          onclick: 'curate.editLocation(' + location.id + ', ' + location.latitude + ', ' + location.longitude + ', ' +location.heading + ', ' + location.pitch + ');'
        }
      ).html('<img class="img-polaroid" src="http://maps.googleapis.com/maps/api/streetview?size=200x150'
        + '&location=' + location.latitude + ',' + location.longitude
        + '&heading=' + location.heading + '&pitch=' + location.pitch + '&sensor=false" />').prependTo('#images');

    });
  }
}

ss.handler.Curate.prototype.addPoints = function() {
  this.polygonMap.addPoints(
    document.getElementById(this.quantityId).value,
    document.getElementById(this.proximityId).value);
}

ss.handler.Curate.prototype.editLocation = function(id, latitude, longitude, heading, pitch) {
  if (this.locked) {
    alert('After launching a study, images can no longer be curated.');
  }
  else {
    // Clean up any old maps in modal before enabling
    // $('#' + this.panoramaId).html('');
    // $('#' + this.panoramaMapId).html('');

    // Set the working location to be this location.
    this.workingLocation = new ss.Location(id, latitude, longitude, heading, pitch);
    var $this = this;

    editModal = $('#' + this.editModalId);

    // Create a panorama and google map (required for panorama?)
    var position = new google.maps.LatLng($this.workingLocation.latitude, $this.workingLocation.longitude);

    if ($this.panorama) {
      // Update things, preserving memory
      $this.marker.setPosition(position);
      $this.marker.setTitle('Location Id:\n  '+ id + '\n\nCoordinates:\n  ' + position.lat() + ', ' + position.lng());
      $this.map.setCenter(position);

      $this.panorama.setPosition(position);
      $this.panorama.setPov({ heading: $this.workingLocation.heading, pitch: $this.workingLocation.pitch });
    }

    editModal.on('shown', function () {

      if (!$this.panorama) {
        // Create things from scratch

        // Create panorama options
        var panoramaOptions = {
          position: position,
          pov: {
            heading: $this.workingLocation.heading,
            pitch: $this.workingLocation.pitch,
          },

          addressControl: false,
          linksControl: false,
          disableDoubleClickZoom: true,
          zoomControl: false,
          navigationControl: false,
          enableCloseButton: false,
          disableDefaultUI: true,
          scrollwheel: false,
          scaleControl: false,
          draggable: false,
          mapTypeControl: false,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        };

        // Create a map
        var mapOptions = {
          center: position,
          zoom: 12,
          disableDefaultUI: true,
          disableDoubleClickZoom: true,
          draggable: false,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        }
        $this.map = new google.maps.Map(document.getElementById($this.panoramaMapId), mapOptions);

        // Associate the panorama
        $this.panorama = new google.maps.StreetViewPanorama(document.getElementById($this.panoramaId), panoramaOptions);
        $this.map.setStreetView($this.panorama);

        $this.marker = new google.maps.Marker({
          position: position,
          map: $this.map,
          title: 'Location Id:\n  '+ id + '\n\nCoordinates:\n  ' + position.lat() + ', ' + position.lng(),

          });

          var $that = $this;

          google.maps.event.trigger($this.panorama, 'resize');
          google.maps.event.addListener($this.panorama, 'pov_changed', function() {
            heading = $that.panorama.getPov().heading;
            while (heading < 0) {
              heading = heading + 360;
            }
            while (heading > 360) {
              heading = heading - 360;
            }
            $that.workingLocation.heading = heading;
            $that.workingLocation.pitch = $that.panorama.getPov().pitch;
          });
        }
      }); // end editModal.on('shown')

    // Enable modal
    editModal.modal();
  }

}


/**
 * Shows the confirm delete dialog.
 */
ss.handler.Curate.prototype.deleteLocation = function() {
  $('#' + this.editModalId).modal('toggle');
  $('#' + this.deleteModalId).modal('toggle');
}

/**
 * Actually deletes the location.
 */
ss.handler.Curate.prototype.deleteLocationConfirm = function() {
  $('#' + this.deleteModalId).modal('toggle');
  $this = this;
  this.workingLocation.delete(function (location, status, xhr) {
    // delete the image
    $('#' + $this.locationIdPrefix + location.id).remove();

    $this.polygonMap.removeMarker(location.id);
  });
}

/**
 * Actually deletes the location.
 */
ss.handler.Curate.prototype.deleteRegion = function(id) {
  $('#' + this.deleteRegionModalId).modal('toggle');
  $this = this;
  region = new ss.Region(id);
  region.delete(function (region, status, xhr) {
    location = 'vote'
  });
}

/**
 * Cancels deletion and returns to the edit modal.
 */
ss.handler.Curate.prototype.deleteLocationCancel = function() {
  $('#' + this.deleteModalId).modal('toggle');
  $('#' + this.editModalId).modal('toggle');
}

ss.handler.Curate.prototype.updateLocation = function() {
  var $this = this;
  this.workingLocation.update(function(location, status, xhr) {
    if (status == "success") {
      // update the onclick
      $('#' + $this.locationIdPrefix + location.id).click(function(){
        $this.editLocation(location.id, location.latitude, location.longitude, location.heading, location.pitch);
      });
      // update the image
      $('#' + $this.locationIdPrefix + location.id).html(
        '<img class="img-polaroid" src="http://maps.googleapis.com/maps/api/streetview?size=200x150'
        + '&location=' + location.latitude + ',' + location.longitude
        + '&heading=' + location.heading + '&pitch=' + location.pitch + '&sensor=false" />'
        );
      $('#' + $this.editModalId).modal('toggle');
    }
  });

}




