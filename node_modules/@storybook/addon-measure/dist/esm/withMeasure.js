/* eslint-env browser */
import { useEffect } from '@storybook/addons';
import { drawSelectedElement } from './box-model/visualizer';
import { init, rescale, destroy } from './box-model/canvas';
import { deepElementFromPoint } from './util';
var nodeAtPointerRef;
var pointer = {
  x: 0,
  y: 0
};

function findAndDrawElement(x, y) {
  nodeAtPointerRef = deepElementFromPoint(x, y);
  drawSelectedElement(nodeAtPointerRef);
}

export var withMeasure = function withMeasure(StoryFn, context) {
  var measureEnabled = context.globals.measureEnabled;
  useEffect(function () {
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
  useEffect(function () {
    var onMouseOver = function onMouseOver(event) {
      window.requestAnimationFrame(function () {
        event.stopPropagation();
        findAndDrawElement(event.clientX, event.clientY);
      });
    };

    var onResize = function onResize() {
      window.requestAnimationFrame(function () {
        rescale();
      });
    };

    if (measureEnabled) {
      document.addEventListener('mouseover', onMouseOver);
      init();
      window.addEventListener('resize', onResize); // Draw the element below the pointer when first enabled

      findAndDrawElement(pointer.x, pointer.y);
    }

    return function () {
      window.removeEventListener('resize', onResize);
      destroy();
    };
  }, [measureEnabled]);
  return StoryFn();
};