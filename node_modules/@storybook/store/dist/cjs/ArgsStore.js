"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ArgsStore = void 0;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.object.assign.js");

var _args = require("./args");

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function deleteUndefined(obj) {
  // eslint-disable-next-line no-param-reassign
  Object.keys(obj).forEach(function (key) {
    return obj[key] === undefined && delete obj[key];
  });
  return obj;
}

var ArgsStore = /*#__PURE__*/function () {
  function ArgsStore() {
    _classCallCheck(this, ArgsStore);

    this.initialArgsByStoryId = {};
    this.argsByStoryId = {};
  }

  _createClass(ArgsStore, [{
    key: "get",
    value: function get(storyId) {
      if (!(storyId in this.argsByStoryId)) {
        throw new Error("No args known for ".concat(storyId, " -- has it been rendered yet?"));
      }

      return this.argsByStoryId[storyId];
    }
  }, {
    key: "setInitial",
    value: function setInitial(story) {
      if (!this.initialArgsByStoryId[story.id]) {
        this.initialArgsByStoryId[story.id] = story.initialArgs;
        this.argsByStoryId[story.id] = story.initialArgs;
      } else if (this.initialArgsByStoryId[story.id] !== story.initialArgs) {
        // When we get a new version of a story (with new initialArgs), we re-apply the same diff
        // that we had previously applied to the old version of the story
        var delta = (0, _args.deepDiff)(this.initialArgsByStoryId[story.id], this.argsByStoryId[story.id]);
        this.initialArgsByStoryId[story.id] = story.initialArgs;
        this.argsByStoryId[story.id] = story.initialArgs;

        if (delta !== _args.DEEPLY_EQUAL) {
          this.updateFromDelta(story, delta);
        }
      }
    }
  }, {
    key: "updateFromDelta",
    value: function updateFromDelta(story, delta) {
      // Use the argType to ensure we setting a type with defined options to something outside of that
      var validatedDelta = (0, _args.validateOptions)(delta, story.argTypes); // NOTE: we use `combineArgs` here rather than `combineParameters` because changes to arg
      // array values are persisted in the URL as sparse arrays, and we have to take that into
      // account when overriding the initialArgs (e.g. we patch [,'changed'] over ['initial', 'val'])

      this.argsByStoryId[story.id] = (0, _args.combineArgs)(this.argsByStoryId[story.id], validatedDelta);
    }
  }, {
    key: "updateFromPersisted",
    value: function updateFromPersisted(story, persisted) {
      // Use the argType to ensure we aren't persisting the wrong type of value to the type.
      // For instance you could try and set a string-valued arg to a number by changing the URL
      var mappedPersisted = (0, _args.mapArgsToTypes)(persisted, story.argTypes);
      return this.updateFromDelta(story, mappedPersisted);
    }
  }, {
    key: "update",
    value: function update(storyId, argsUpdate) {
      if (!(storyId in this.argsByStoryId)) {
        throw new Error("No args known for ".concat(storyId, " -- has it been rendered yet?"));
      }

      this.argsByStoryId[storyId] = deleteUndefined(Object.assign({}, this.argsByStoryId[storyId], argsUpdate));
    }
  }]);

  return ArgsStore;
}();

exports.ArgsStore = ArgsStore;