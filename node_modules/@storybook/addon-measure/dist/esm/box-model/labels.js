import "core-js/modules/es.array.fill.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";

/* eslint-disable operator-assignment */

/* eslint-disable no-param-reassign */
var colors = {
  margin: '#f6b26b',
  border: '#ffe599',
  padding: '#93c47d',
  content: '#6fa8dc',
  text: '#232020'
};
var labelPadding = 6;

function roundedRect(context, _ref) {
  var x = _ref.x,
      y = _ref.y,
      w = _ref.w,
      h = _ref.h,
      r = _ref.r;
  x = x - w / 2;
  y = y - h / 2;
  if (w < 2 * r) r = w / 2;
  if (h < 2 * r) r = h / 2;
  context.beginPath();
  context.moveTo(x + r, y);
  context.arcTo(x + w, y, x + w, y + h, r);
  context.arcTo(x + w, y + h, x, y + h, r);
  context.arcTo(x, y + h, x, y, r);
  context.arcTo(x, y, x + w, y, r);
  context.closePath();
}

function positionCoordinate(position, _ref2) {
  var padding = _ref2.padding,
      border = _ref2.border,
      width = _ref2.width,
      height = _ref2.height,
      top = _ref2.top,
      left = _ref2.left;
  var contentWidth = width - border.left - border.right - padding.left - padding.right;
  var contentHeight = height - padding.top - padding.bottom - border.top - border.bottom;
  var x = left + border.left + padding.left;
  var y = top + border.top + padding.top;

  if (position === 'top') {
    x += contentWidth / 2;
  } else if (position === 'right') {
    x += contentWidth;
    y += contentHeight / 2;
  } else if (position === 'bottom') {
    x += contentWidth / 2;
    y += contentHeight;
  } else if (position === 'left') {
    y += contentHeight / 2;
  } else if (position === 'center') {
    x += contentWidth / 2;
    y += contentHeight / 2;
  }

  return {
    x: x,
    y: y
  };
}
/**
 * Offset the label based on how many layers appear before it
 * For example:
 * margin labels will shift further outwards if there are
 * padding labels
 */


function offset(type, position, _ref3, labelPaddingSize, external) {
  var margin = _ref3.margin,
      border = _ref3.border,
      padding = _ref3.padding;

  var shift = function shift(dir) {
    return 0;
  };

  var offsetX = 0;
  var offsetY = 0; // If external labels then push them to the edge of the band
  // else keep them centred

  var locationMultiplier = external ? 1 : 0.5; // Account for padding within the label

  var labelPaddingShift = external ? labelPaddingSize * 2 : 0;

  if (type === 'padding') {
    shift = function shift(dir) {
      return padding[dir] * locationMultiplier + labelPaddingShift;
    };
  } else if (type === 'border') {
    shift = function shift(dir) {
      return padding[dir] + border[dir] * locationMultiplier + labelPaddingShift;
    };
  } else if (type === 'margin') {
    shift = function shift(dir) {
      return padding[dir] + border[dir] + margin[dir] * locationMultiplier + labelPaddingShift;
    };
  }

  if (position === 'top') {
    offsetY = -shift('top');
  } else if (position === 'right') {
    offsetX = shift('right');
  } else if (position === 'bottom') {
    offsetY = shift('bottom');
  } else if (position === 'left') {
    offsetX = -shift('left');
  }

  return {
    offsetX: offsetX,
    offsetY: offsetY
  };
}

function collide(a, b) {
  return Math.abs(a.x - b.x) < Math.abs(a.w + b.w) / 2 && Math.abs(a.y - b.y) < Math.abs(a.h + b.h) / 2;
}

function overlapAdjustment(position, currentRect, prevRect) {
  if (position === 'top') {
    currentRect.y = prevRect.y - prevRect.h - labelPadding;
  } else if (position === 'right') {
    currentRect.x = prevRect.x + prevRect.w / 2 + labelPadding + currentRect.w / 2;
  } else if (position === 'bottom') {
    currentRect.y = prevRect.y + prevRect.h + labelPadding;
  } else if (position === 'left') {
    currentRect.x = prevRect.x - prevRect.w / 2 - labelPadding - currentRect.w / 2;
  }

  return {
    x: currentRect.x,
    y: currentRect.y
  };
}

function textWithRect(context, type, _ref4, text) {
  var x = _ref4.x,
      y = _ref4.y,
      w = _ref4.w,
      h = _ref4.h;
  roundedRect(context, {
    x: x,
    y: y,
    w: w,
    h: h,
    r: 3
  });
  context.fillStyle = "".concat(colors[type], "dd");
  context.fill();
  context.strokeStyle = colors[type];
  context.stroke();
  context.fillStyle = colors.text;
  context.fillText(text, x, y);
  roundedRect(context, {
    x: x,
    y: y,
    w: w,
    h: h,
    r: 3
  });
  context.fillStyle = "".concat(colors[type], "dd");
  context.fill();
  context.strokeStyle = colors[type];
  context.stroke();
  context.fillStyle = colors.text;
  context.fillText(text, x, y);
  return {
    x: x,
    y: y,
    w: w,
    h: h
  };
}

function configureText(context, text) {
  context.font = '600 12px monospace';
  context.textBaseline = 'middle';
  context.textAlign = 'center';
  var metrics = context.measureText(text);
  var actualHeight = metrics.actualBoundingBoxAscent + metrics.actualBoundingBoxDescent;
  var w = metrics.width + labelPadding * 2;
  var h = actualHeight + labelPadding * 2;
  return {
    w: w,
    h: h
  };
}

function drawLabel(context, measurements, _ref5, prevRect) {
  var type = _ref5.type,
      _ref5$position = _ref5.position,
      position = _ref5$position === void 0 ? 'center' : _ref5$position,
      text = _ref5.text;
  var external = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : false;

  var _positionCoordinate = positionCoordinate(position, measurements),
      x = _positionCoordinate.x,
      y = _positionCoordinate.y;

  var _offset = offset(type, position, measurements, labelPadding + 1, external),
      offsetX = _offset.offsetX,
      offsetY = _offset.offsetY; // Shift coordinate to center within
  // the band of measurement


  x += offsetX;
  y += offsetY;

  var _configureText = configureText(context, text),
      w = _configureText.w,
      h = _configureText.h; // Adjust for overlap


  if (prevRect && collide({
    x: x,
    y: y,
    w: w,
    h: h
  }, prevRect)) {
    var adjusted = overlapAdjustment(position, {
      x: x,
      y: y,
      w: w,
      h: h
    }, prevRect);
    x = adjusted.x;
    y = adjusted.y;
  }

  return textWithRect(context, type, {
    x: x,
    y: y,
    w: w,
    h: h
  }, text);
}

function floatingOffset(alignment, _ref6) {
  var w = _ref6.w,
      h = _ref6.h;
  var deltaW = w * 0.5 + labelPadding;
  var deltaH = h * 0.5 + labelPadding;
  return {
    offsetX: (alignment.x === 'left' ? -1 : 1) * deltaW,
    offsetY: (alignment.y === 'top' ? -1 : 1) * deltaH
  };
}

export function drawFloatingLabel(context, measurements, _ref7) {
  var type = _ref7.type,
      text = _ref7.text;
  var floatingAlignment = measurements.floatingAlignment,
      extremities = measurements.extremities;
  var x = extremities[floatingAlignment.x];
  var y = extremities[floatingAlignment.y];

  var _configureText2 = configureText(context, text),
      w = _configureText2.w,
      h = _configureText2.h;

  var _floatingOffset = floatingOffset(floatingAlignment, {
    w: w,
    h: h
  }),
      offsetX = _floatingOffset.offsetX,
      offsetY = _floatingOffset.offsetY;

  x += offsetX;
  y += offsetY;
  return textWithRect(context, type, {
    x: x,
    y: y,
    w: w,
    h: h
  }, text);
}

function drawStack(context, measurements, stack, external) {
  var rects = [];
  stack.forEach(function (l, idx) {
    // Move the centred label to floating in external mode
    var rect = external && l.position === 'center' ? drawFloatingLabel(context, measurements, l) : drawLabel(context, measurements, l, rects[idx - 1], external);
    rects[idx] = rect;
  });
}

export function labelStacks(context, measurements, labels, externalLabels) {
  var stacks = labels.reduce(function (acc, l) {
    if (!Object.prototype.hasOwnProperty.call(acc, l.position)) {
      acc[l.position] = [];
    }

    acc[l.position].push(l);
    return acc;
  }, {});

  if (stacks.top) {
    drawStack(context, measurements, stacks.top, externalLabels);
  }

  if (stacks.right) {
    drawStack(context, measurements, stacks.right, externalLabels);
  }

  if (stacks.bottom) {
    drawStack(context, measurements, stacks.bottom, externalLabels);
  }

  if (stacks.left) {
    drawStack(context, measurements, stacks.left, externalLabels);
  }

  if (stacks.center) {
    drawStack(context, measurements, stacks.center, externalLabels);
  }
}