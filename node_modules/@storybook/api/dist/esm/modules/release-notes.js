function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import global from 'global';
import memoize from 'memoizerific';
var RELEASE_NOTES_DATA = global.RELEASE_NOTES_DATA;
var getReleaseNotesData = memoize(1)(function () {
  try {
    return Object.assign({}, JSON.parse(RELEASE_NOTES_DATA) || {});
  } catch (e) {
    return {};
  }
});
export var init = function init(_ref) {
  var store = _ref.store;
  var releaseNotesData = getReleaseNotesData();

  var getReleaseNotesViewed = function getReleaseNotesViewed() {
    var _store$getState = store.getState(),
        persistedReleaseNotesViewed = _store$getState.releaseNotesViewed;

    return persistedReleaseNotesViewed || [];
  };

  var api = {
    releaseNotesVersion: function releaseNotesVersion() {
      return releaseNotesData.currentVersion;
    },
    setDidViewReleaseNotes: function setDidViewReleaseNotes() {
      var releaseNotesViewed = getReleaseNotesViewed();

      if (!releaseNotesViewed.includes(releaseNotesData.currentVersion)) {
        store.setState({
          releaseNotesViewed: [].concat(_toConsumableArray(releaseNotesViewed), [releaseNotesData.currentVersion])
        }, {
          persistence: 'permanent'
        });
      }
    },
    showReleaseNotesOnLaunch: function showReleaseNotesOnLaunch() {
      // The currentVersion will only exist for dev builds
      if (!releaseNotesData.currentVersion) return false;
      var releaseNotesViewed = getReleaseNotesViewed();
      var didViewReleaseNotes = releaseNotesViewed.includes(releaseNotesData.currentVersion);
      var showReleaseNotesOnLaunch = releaseNotesData.showOnFirstLaunch && !didViewReleaseNotes;
      return showReleaseNotesOnLaunch;
    }
  };

  var initModule = function initModule() {};

  return {
    init: initModule,
    api: api
  };
};