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

// If we're in Node.js then require VTTCue so we can extend it, otherwise assume
// VTTCue is on the global.
if (typeof module !== "undefined" && module.exports) {
  this.VTTCue = this.VTTCue || require("./vttcue").VTTCue;
}

// Extend VTTCue with methods to convert to JSON, from JSON, and construct a
// VTTCue from an options object. The primary purpose of this is for use in the
// vtt.js test suite (for testing only properties that we care about). It's also
// useful if you need to work with VTTCues in JSON format.
(function(root) {

  root.VTTCue.prototype.toJSON = function() {
    var cue = {},
        self = this;
    // Filter out getCueAsHTML as it's a function and hasBeenReset and displayState as
    // they're only used when running the processing model algorithm.
    Object.keys(this).forEach(function(key) {
      if (key !== "getCueAsHTML" && key !== "hasBeenReset" && key !== "displayState") {
        cue[key] = self[key];
      }
    });
    return cue;
  };

  root.VTTCue.create = function(options) {
    if (!options.hasOwnProperty("startTime") || !options.hasOwnProperty("endTime") ||
        !options.hasOwnProperty("text")) {
      throw new Error("You must at least have start time, end time, and text.");
    }
    var cue = new root.VTTCue(options.startTime, options.endTime, options.text);
    for (var key in options) {
      if (cue.hasOwnProperty(key)) {
        cue[key] = options[key];
      }
    }
    return cue;
  };

  root.VTTCue.fromJSON = function(json) {
    return this.create(JSON.parse(json));
  };

}(this));
