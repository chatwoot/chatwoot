"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.forEachMediaGroup = void 0;

/**
 * Loops through all supported media groups in master and calls the provided
 * callback for each group
 *
 * @param {Object} master
 *        The parsed master manifest object
 * @param {string[]} groups
 *        The media groups to call the callback for
 * @param {Function} callback
 *        Callback to call for each media group
 */
var forEachMediaGroup = function forEachMediaGroup(master, groups, callback) {
  groups.forEach(function (mediaType) {
    for (var groupKey in master.mediaGroups[mediaType]) {
      for (var labelKey in master.mediaGroups[mediaType][groupKey]) {
        var mediaProperties = master.mediaGroups[mediaType][groupKey][labelKey];
        callback(mediaProperties, mediaType, groupKey, labelKey);
      }
    }
  });
};

exports.forEachMediaGroup = forEachMediaGroup;