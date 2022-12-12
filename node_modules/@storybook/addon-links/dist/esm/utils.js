function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.search.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.string.match.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import global from 'global';
import qs from 'qs';
import { addons, makeDecorator } from '@storybook/addons';
import { STORY_CHANGED, SELECT_STORY } from '@storybook/core-events';
import { toId } from '@storybook/csf';
import { PARAM_KEY } from './constants';
var document = global.document,
    HTMLElement = global.HTMLElement;
export var navigate = function navigate(params) {
  return addons.getChannel().emit(SELECT_STORY, params);
};
export var hrefTo = function hrefTo(title, name) {
  return new Promise(function (resolve) {
    var location = document.location;
    var query = qs.parse(location.search, {
      ignoreQueryPrefix: true
    });
    var existingId = [].concat(query.id)[0];
    var titleToLink = title || existingId.split('--', 2)[0];
    var id = toId(titleToLink, name);
    var url = "".concat(location.origin + location.pathname, "?").concat(qs.stringify(Object.assign({}, query, {
      id: id
    }), {
      encode: false
    }));
    resolve(url);
  });
};

var valueOrCall = function valueOrCall(args) {
  return function (value) {
    return typeof value === 'function' ? value.apply(void 0, _toConsumableArray(args)) : value;
  };
};

export var linkTo = function linkTo(idOrTitle, nameInput) {
  return function () {
    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    var resolver = valueOrCall(args);
    var title = resolver(idOrTitle);
    var name = resolver(nameInput);

    if (title !== null && title !== void 0 && title.match(/--/) && !name) {
      navigate({
        storyId: title
      });
    } else {
      navigate({
        kind: title,
        story: name
      });
    }
  };
};

var linksListener = function linksListener(e) {
  var target = e.target;

  if (!(target instanceof HTMLElement)) {
    return;
  }

  var element = target;
  var _element$dataset = element.dataset,
      kind = _element$dataset.sbKind,
      story = _element$dataset.sbStory;

  if (kind || story) {
    e.preventDefault();
    navigate({
      kind: kind,
      story: story
    });
  }
};

var hasListener = false;

var on = function on() {
  if (!hasListener) {
    hasListener = true;
    document.addEventListener('click', linksListener);
  }
};

var off = function off() {
  if (hasListener) {
    hasListener = false;
    document.removeEventListener('click', linksListener);
  }
};

export var withLinks = makeDecorator({
  name: 'withLinks',
  parameterName: PARAM_KEY,
  wrapper: function wrapper(getStory, context) {
    on();
    addons.getChannel().once(STORY_CHANGED, off);
    return getStory(context);
  }
});