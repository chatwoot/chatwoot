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

var autoKeyword = "auto";
var directionSetting = {
  "": 1,
  "lr": 1,
  "rl": 1
};
var alignSetting = {
  "start": 1,
  "center": 1,
  "end": 1,
  "left": 1,
  "right": 1,
  "auto": 1,
  "line-left": 1,
  "line-right": 1
};

function findDirectionSetting(value) {
  if (typeof value !== "string") {
    return false;
  }
  var dir = directionSetting[value.toLowerCase()];
  return dir ? value.toLowerCase() : false;
}

function findAlignSetting(value) {
  if (typeof value !== "string") {
    return false;
  }
  var align = alignSetting[value.toLowerCase()];
  return align ? value.toLowerCase() : false;
}

function VTTCue(startTime, endTime, text) {
  /**
   * Shim implementation specific properties. These properties are not in
   * the spec.
   */

  // Lets us know when the VTTCue's data has changed in such a way that we need
  // to recompute its display state. This lets us compute its display state
  // lazily.
  this.hasBeenReset = false;

  /**
   * VTTCue and TextTrackCue properties
   * http://dev.w3.org/html5/webvtt/#vttcue-interface
   */

  var _id = "";
  var _pauseOnExit = false;
  var _startTime = startTime;
  var _endTime = endTime;
  var _text = text;
  var _region = null;
  var _vertical = "";
  var _snapToLines = true;
  var _line = "auto";
  var _lineAlign = "start";
  var _position = "auto";
  var _positionAlign = "auto";
  var _size = 100;
  var _align = "center";

  Object.defineProperties(this, {
    "id": {
      enumerable: true,
      get: function() {
        return _id;
      },
      set: function(value) {
        _id = "" + value;
      }
    },

    "pauseOnExit": {
      enumerable: true,
      get: function() {
        return _pauseOnExit;
      },
      set: function(value) {
        _pauseOnExit = !!value;
      }
    },

    "startTime": {
      enumerable: true,
      get: function() {
        return _startTime;
      },
      set: function(value) {
        if (typeof value !== "number") {
          throw new TypeError("Start time must be set to a number.");
        }
        _startTime = value;
        this.hasBeenReset = true;
      }
    },

    "endTime": {
      enumerable: true,
      get: function() {
        return _endTime;
      },
      set: function(value) {
        if (typeof value !== "number") {
          throw new TypeError("End time must be set to a number.");
        }
        _endTime = value;
        this.hasBeenReset = true;
      }
    },

    "text": {
      enumerable: true,
      get: function() {
        return _text;
      },
      set: function(value) {
        _text = "" + value;
        this.hasBeenReset = true;
      }
    },

    "region": {
      enumerable: true,
      get: function() {
        return _region;
      },
      set: function(value) {
        _region = value;
        this.hasBeenReset = true;
      }
    },

    "vertical": {
      enumerable: true,
      get: function() {
        return _vertical;
      },
      set: function(value) {
        var setting = findDirectionSetting(value);
        // Have to check for false because the setting an be an empty string.
        if (setting === false) {
          throw new SyntaxError("Vertical: an invalid or illegal direction string was specified.");
        }
        _vertical = setting;
        this.hasBeenReset = true;
      }
    },

    "snapToLines": {
      enumerable: true,
      get: function() {
        return _snapToLines;
      },
      set: function(value) {
        _snapToLines = !!value;
        this.hasBeenReset = true;
      }
    },

    "line": {
      enumerable: true,
      get: function() {
        return _line;
      },
      set: function(value) {
        if (typeof value !== "number" && value !== autoKeyword) {
          throw new SyntaxError("Line: an invalid number or illegal string was specified.");
        }
        _line = value;
        this.hasBeenReset = true;
      }
    },

    "lineAlign": {
      enumerable: true,
      get: function() {
        return _lineAlign;
      },
      set: function(value) {
        var setting = findAlignSetting(value);
        if (!setting) {
          console.warn("lineAlign: an invalid or illegal string was specified.");
        } else {
          _lineAlign = setting;
          this.hasBeenReset = true;
        }
      }
    },

    "position": {
      enumerable: true,
      get: function() {
        return _position;
      },
      set: function(value) {
        if (value < 0 || value > 100) {
          throw new Error("Position must be between 0 and 100.");
        }
        _position = value;
        this.hasBeenReset = true;
      }
    },

    "positionAlign": {
      enumerable: true,
      get: function() {
        return _positionAlign;
      },
      set: function(value) {
        var setting = findAlignSetting(value);
        if (!setting) {
          console.warn("positionAlign: an invalid or illegal string was specified.");
        } else {
          _positionAlign = setting;
          this.hasBeenReset = true;
        }
      }
    },

    "size": {
      enumerable: true,
      get: function() {
        return _size;
      },
      set: function(value) {
        if (value < 0 || value > 100) {
          throw new Error("Size must be between 0 and 100.");
        }
        _size = value;
        this.hasBeenReset = true;
      }
    },

    "align": {
      enumerable: true,
      get: function() {
        return _align;
      },
      set: function(value) {
        var setting = findAlignSetting(value);
        if (!setting) {
          throw new SyntaxError("align: an invalid or illegal alignment string was specified.");
        }
        _align = setting;
        this.hasBeenReset = true;
      }
    }
  });

  /**
   * Other <track> spec defined properties
   */

  // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#text-track-cue-display-state
  this.displayState = undefined;
}

/**
 * VTTCue methods
 */

VTTCue.prototype.getCueAsHTML = function() {
  // Assume WebVTT.convertCueToDOMTree is on the global.
  return WebVTT.convertCueToDOMTree(window, this.text);
};

module.exports = VTTCue;
