/* eslint-disable no-param-reassign */
import global from 'global';

function getDocumentWidthAndHeight() {
  var container = global.document.documentElement;
  var height = Math.max(container.scrollHeight, container.offsetHeight);
  var width = Math.max(container.scrollWidth, container.offsetWidth);
  return {
    width: width,
    height: height
  };
}

function createCanvas() {
  var canvas = global.document.createElement('canvas');
  canvas.id = 'storybook-addon-measure';
  var context = canvas.getContext('2d'); // Set canvas width & height

  var _getDocumentWidthAndH = getDocumentWidthAndHeight(),
      width = _getDocumentWidthAndH.width,
      height = _getDocumentWidthAndH.height;

  setCanvasWidthAndHeight(canvas, context, {
    width: width,
    height: height
  }); // Position canvas

  canvas.style.position = 'absolute';
  canvas.style.left = '0';
  canvas.style.top = '0';
  canvas.style.zIndex = '2147483647'; // Disable any user interactions

  canvas.style.pointerEvents = 'none';
  global.document.body.appendChild(canvas);
  return {
    canvas: canvas,
    context: context,
    width: width,
    height: height
  };
}

function setCanvasWidthAndHeight(canvas, context, _ref) {
  var width = _ref.width,
      height = _ref.height;
  canvas.style.width = "".concat(width, "px");
  canvas.style.height = "".concat(height, "px"); // Scale

  var scale = global.window.devicePixelRatio;
  canvas.width = Math.floor(width * scale);
  canvas.height = Math.floor(height * scale); // Normalize coordinate system to use css pixels.

  context.scale(scale, scale);
}

var state = {};
export function init() {
  if (!state.canvas) {
    state = createCanvas();
  }
}
export function clear() {
  if (state.context) {
    state.context.clearRect(0, 0, state.width, state.height);
  }
}
export function draw(callback) {
  clear();
  callback(state.context);
}
export function rescale() {
  // First reset so that the canvas size doesn't impact the container size
  setCanvasWidthAndHeight(state.canvas, state.context, {
    width: 0,
    height: 0
  });

  var _getDocumentWidthAndH2 = getDocumentWidthAndHeight(),
      width = _getDocumentWidthAndH2.width,
      height = _getDocumentWidthAndH2.height;

  setCanvasWidthAndHeight(state.canvas, state.context, {
    width: width,
    height: height
  }); // update state

  state.width = width;
  state.height = height;
}
export function destroy() {
  if (state.canvas) {
    clear();
    state.canvas.parentNode.removeChild(state.canvas);
    state = {};
  }
}