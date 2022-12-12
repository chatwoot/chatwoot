import "core-js/modules/es.array.reduce.js";

/* eslint-disable operator-assignment */

/* eslint-disable no-param-reassign */
const colors = {
  margin: '#f6b26b',
  border: '#ffe599',
  padding: '#93c47d',
  content: '#6fa8dc',
  text: '#232020'
};
const labelPadding = 6;

function roundedRect(context, {
  x,
  y,
  w,
  h,
  r
}) {
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

function positionCoordinate(position, {
  padding,
  border,
  width,
  height,
  top,
  left
}) {
  const contentWidth = width - border.left - border.right - padding.left - padding.right;
  const contentHeight = height - padding.top - padding.bottom - border.top - border.bottom;
  let x = left + border.left + padding.left;
  let y = top + border.top + padding.top;

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
    x,
    y
  };
}
/**
 * Offset the label based on how many layers appear before it
 * For example:
 * margin labels will shift further outwards if there are
 * padding labels
 */


function offset(type, position, {
  margin,
  border,
  padding
}, labelPaddingSize, external) {
  let shift = dir => 0;

  let offsetX = 0;
  let offsetY = 0; // If external labels then push them to the edge of the band
  // else keep them centred

  const locationMultiplier = external ? 1 : 0.5; // Account for padding within the label

  const labelPaddingShift = external ? labelPaddingSize * 2 : 0;

  if (type === 'padding') {
    shift = dir => padding[dir] * locationMultiplier + labelPaddingShift;
  } else if (type === 'border') {
    shift = dir => padding[dir] + border[dir] * locationMultiplier + labelPaddingShift;
  } else if (type === 'margin') {
    shift = dir => padding[dir] + border[dir] + margin[dir] * locationMultiplier + labelPaddingShift;
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
    offsetX,
    offsetY
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

function textWithRect(context, type, {
  x,
  y,
  w,
  h
}, text) {
  roundedRect(context, {
    x,
    y,
    w,
    h,
    r: 3
  });
  context.fillStyle = `${colors[type]}dd`;
  context.fill();
  context.strokeStyle = colors[type];
  context.stroke();
  context.fillStyle = colors.text;
  context.fillText(text, x, y);
  roundedRect(context, {
    x,
    y,
    w,
    h,
    r: 3
  });
  context.fillStyle = `${colors[type]}dd`;
  context.fill();
  context.strokeStyle = colors[type];
  context.stroke();
  context.fillStyle = colors.text;
  context.fillText(text, x, y);
  return {
    x,
    y,
    w,
    h
  };
}

function configureText(context, text) {
  context.font = '600 12px monospace';
  context.textBaseline = 'middle';
  context.textAlign = 'center';
  const metrics = context.measureText(text);
  const actualHeight = metrics.actualBoundingBoxAscent + metrics.actualBoundingBoxDescent;
  const w = metrics.width + labelPadding * 2;
  const h = actualHeight + labelPadding * 2;
  return {
    w,
    h
  };
}

function drawLabel(context, measurements, {
  type,
  position = 'center',
  text
}, prevRect, external = false) {
  let {
    x,
    y
  } = positionCoordinate(position, measurements);
  const {
    offsetX,
    offsetY
  } = offset(type, position, measurements, labelPadding + 1, external); // Shift coordinate to center within
  // the band of measurement

  x += offsetX;
  y += offsetY;
  const {
    w,
    h
  } = configureText(context, text); // Adjust for overlap

  if (prevRect && collide({
    x,
    y,
    w,
    h
  }, prevRect)) {
    const adjusted = overlapAdjustment(position, {
      x,
      y,
      w,
      h
    }, prevRect);
    x = adjusted.x;
    y = adjusted.y;
  }

  return textWithRect(context, type, {
    x,
    y,
    w,
    h
  }, text);
}

function floatingOffset(alignment, {
  w,
  h
}) {
  const deltaW = w * 0.5 + labelPadding;
  const deltaH = h * 0.5 + labelPadding;
  return {
    offsetX: (alignment.x === 'left' ? -1 : 1) * deltaW,
    offsetY: (alignment.y === 'top' ? -1 : 1) * deltaH
  };
}

export function drawFloatingLabel(context, measurements, {
  type,
  text
}) {
  const {
    floatingAlignment,
    extremities
  } = measurements;
  let x = extremities[floatingAlignment.x];
  let y = extremities[floatingAlignment.y];
  const {
    w,
    h
  } = configureText(context, text);
  const {
    offsetX,
    offsetY
  } = floatingOffset(floatingAlignment, {
    w,
    h
  });
  x += offsetX;
  y += offsetY;
  return textWithRect(context, type, {
    x,
    y,
    w,
    h
  }, text);
}

function drawStack(context, measurements, stack, external) {
  const rects = [];
  stack.forEach((l, idx) => {
    // Move the centred label to floating in external mode
    const rect = external && l.position === 'center' ? drawFloatingLabel(context, measurements, l) : drawLabel(context, measurements, l, rects[idx - 1], external);
    rects[idx] = rect;
  });
}

export function labelStacks(context, measurements, labels, externalLabels) {
  const stacks = labels.reduce((acc, l) => {
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