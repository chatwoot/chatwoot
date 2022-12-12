/**
 * Copyright 2013 vtt.js Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var scrollSetting = {
  "": true,
  "up": true
};

function findScrollSetting(value) {
  if (typeof value !== "string") {
    return false;
  }
  var scroll = scrollSetting[value.toLowerCase()];
  return scroll ? value.toLowerCase() : false;
}

function isValidPercentValue(value) {
  return typeof value === "number" && (value >= 0 && value <= 100);
}

// VTTRegion shim http://dev.w3.org/html5/webvtt/#vttregion-interface
function VTTRegion() {
  var _width = 100;
  var _lines = 3;
  var _regionAnchorX = 0;
  var _regionAnchorY = 100;
  var _viewportAnchorX = 0;
  var _viewportAnchorY = 100;
  var _scroll = "";

  Object.defineProperties(this, {
    "width": {
      enumerable: true,
      get: function() {
        return _width;
      },
      set: function(value) {
        if (!isValidPercentValue(value)) {
          throw new Error("Width must be between 0 and 100.");
        }
        _width = value;
      }
    },
    "lines": {
      enumerable: true,
      get: function() {
        return _lines;
      },
      set: function(value) {
        if (typeof value !== "number") {
          throw new TypeError("Lines must be set to a number.");
        }
        _lines = value;
      }
    },
    "regionAnchorY": {
      enumerable: true,
      get: function() {
        return _regionAnchorY;
      },
      set: function(value) {
        if (!isValidPercentValue(value)) {
          throw new Error("RegionAnchorX must be between 0 and 100.");
        }
        _regionAnchorY = value;
      }
    },
    "regionAnchorX": {
      enumerable: true,
      get: function() {
        return _regionAnchorX;
      },
      set: function(value) {
        if(!isValidPercentValue(value)) {
          throw new Error("RegionAnchorY must be between 0 and 100.");
        }
        _regionAnchorX = value;
      }
    },
    "viewportAnchorY": {
      enumerable: true,
      get: function() {
        return _viewportAnchorY;
      },
      set: function(value) {
        if (!isValidPercentValue(value)) {
          throw new Error("ViewportAnchorY must be between 0 and 100.");
        }
        _viewportAnchorY = value;
      }
    },
    "viewportAnchorX": {
      enumerable: true,
      get: function() {
        return _viewportAnchorX;
      },
      set: function(value) {
        if (!isValidPercentValue(value)) {
          throw new Error("ViewportAnchorX must be between 0 and 100.");
        }
        _viewportAnchorX = value;
      }
    },
    "scroll": {
      enumerable: true,
      get: function() {
        return _scroll;
      },
      set: function(value) {
        var setting = findScrollSetting(value);
        // Have to check for false as an empty string is a legal value.
        if (setting === false) {
          console.warn("Scroll: an invalid or illegal string was specified.");
        } else {
          _scroll = setting;
        }
      }
    }
  });
}

module.exports = VTTRegion;
