(function(root) {
  var vttjs = root.vttjs = {};
  var cueShim = vttjs.VTTCue;
  var regionShim = vttjs.VTTRegion;
  var oldVTTCue = root.VTTCue;
  var oldVTTRegion = root.VTTRegion;

  vttjs.shim = function() {
    vttjs.VTTCue = cueShim;
    vttjs.VTTRegion = regionShim;
  };

  vttjs.restore = function() {
    vttjs.VTTCue = oldVTTCue;
    vttjs.VTTRegion = oldVTTRegion;
  };
}(this));
