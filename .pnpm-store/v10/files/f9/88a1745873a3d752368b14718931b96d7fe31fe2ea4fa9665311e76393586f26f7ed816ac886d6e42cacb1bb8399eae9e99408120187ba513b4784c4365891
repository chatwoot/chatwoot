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
export const forEachMediaGroup = (master, groups, callback) => {
  groups.forEach((mediaType) => {
    for (const groupKey in master.mediaGroups[mediaType]) {
      for (const labelKey in master.mediaGroups[mediaType][groupKey]) {
        const mediaProperties = master.mediaGroups[mediaType][groupKey][labelKey];

        callback(mediaProperties, mediaType, groupKey, labelKey);
      }
    }
  });
};
