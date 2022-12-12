"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.withMeasure = void 0;

var _addons = require("@storybook/addons");

var _visualizer = require("./box-model/visualizer");

var _canvas = require("./box-model/canvas");

var _util = require("./util");

/* eslint-env browser */
var nodeAtPointerRef;
var pointer = {
  x: 0,
  y: 0
};

function findAndDrawElement(x, y) {
  nodeAtPointerRef = (0, _util.deepElementFromPoint)(x, y);
  (0, _visualizer.drawSelectedElement)(nodeAtPointerRef);
}

var withMeasure = function withMeasure(StoryFn, context) {
  var measureEnabled = context.globals.measureEnabled;
  (0, _addons.useEffect)(function () {
    var onMouseMove = function onMouseMove(event) {
      window.requestAnimationFrame(function () {
        event.stopPropagation();
        pointer.x = event.clientX;
        pointer.y = event.clientY;
      });
    };

    document.addEventListener('mousemove', onMouseMove);
    return function () {
      document.removeEventListener('mousemove', onMouseMove);
    };
  }, []);
  (0, _addons.useEffect)(function () {
    var onMouseOver = function onMouseOver(event) {
      window.requestAnimationFrame(function () {
        event.stopPropagation();
        findAndDrawElement(event.clientX, event.clientY);
      });
    };

    var onResize = function onResize() {
      window.requestAnimationFrame(function () {
        (0, _canvas.rescale)();
      });
    };

    if (measureEnabled) {
      document.addEventListener('mouseover', onMouseOver);
      (0, _canvas.init)();
      window.addEventListener('resize', onResize); // Draw the element below the pointer when first enabled

      findAndDrawElement(pointer.x, pointer.y);
    }

    return function () {
      window.removeEventListener('resize', onResize);
      (0, _canvas.destroy)();
    };
  }, [measureEnabled]);
  return StoryFn();
};

exports.withMeasure = withMeasure;