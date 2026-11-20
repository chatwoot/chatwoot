export const EDITOR_COLOR = '#ef4444';

export const SHAPE_TOOLS = ['arrow', 'rect', 'ellipse'];
export const REGION_TOOLS = ['blur', 'crop'];

// A drag shorter than this, in canvas pixels, is a click and draws nothing.
const MIN_DRAG = 4;

// GIF animation and SVG vectors would be flattened by a canvas, so they skip the editor.
const NON_EDITABLE_TYPES = ['image/gif', 'image/svg+xml'];

export const isEditableImage = type =>
  type.startsWith('image/') && !NON_EDITABLE_TYPES.includes(type);

export const strokeWidthFor = (width, height) =>
  Math.max(3, Math.round(Math.min(width, height) / 120));

const pixelSizeFor = (width, height) =>
  Math.max(8, Math.round(Math.min(width, height) / 60));

export const normalizeRect = (a, b) => ({
  x: Math.min(a.x, b.x),
  y: Math.min(a.y, b.y),
  width: Math.abs(a.x - b.x),
  height: Math.abs(a.y - b.y),
});

const clamp = (value, max) => Math.min(Math.max(value, 0), max);

// Pointer capture keeps reporting moves outside the canvas, so points are clamped to it.
export const toCanvasPoint = (event, canvas) => {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: clamp(
      ((event.clientX - bounds.left) * canvas.width) / bounds.width,
      canvas.width
    ),
    y: clamp(
      ((event.clientY - bounds.top) * canvas.height) / bounds.height,
      canvas.height
    ),
  };
};

export const isMeaningfulOperation = ({ type, start, end }) => {
  if (type === 'arrow') {
    return Math.hypot(end.x - start.x, end.y - start.y) >= MIN_DRAG;
  }
  const { width, height } = normalizeRect(start, end);
  return width >= MIN_DRAG && height >= MIN_DRAG;
};

const createCanvas = (width, height) => {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  return canvas;
};

const drawArrow = (ctx, start, end, lineWidth) => {
  const angle = Math.atan2(end.y - start.y, end.x - start.x);
  const head = lineWidth * 5;
  ctx.beginPath();
  ctx.moveTo(start.x, start.y);
  ctx.lineTo(end.x, end.y);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(end.x, end.y);
  ctx.lineTo(
    end.x - head * Math.cos(angle - Math.PI / 6),
    end.y - head * Math.sin(angle - Math.PI / 6)
  );
  ctx.lineTo(
    end.x - head * Math.cos(angle + Math.PI / 6),
    end.y - head * Math.sin(angle + Math.PI / 6)
  );
  ctx.closePath();
  ctx.fill();
};

const drawEllipse = (ctx, { x, y, width, height }) => {
  ctx.beginPath();
  ctx.ellipse(
    x + width / 2,
    y + height / 2,
    width / 2,
    height / 2,
    0,
    0,
    2 * Math.PI
  );
  ctx.stroke();
};

// Pixelates by shrinking the region and drawing it back without smoothing.
const pixelate = (canvas, { x, y, width, height }) => {
  const size = pixelSizeFor(canvas.width, canvas.height);
  const small = createCanvas(
    Math.max(1, Math.ceil(width / size)),
    Math.max(1, Math.ceil(height / size))
  );
  small
    .getContext('2d')
    .drawImage(canvas, x, y, width, height, 0, 0, small.width, small.height);
  const ctx = canvas.getContext('2d');
  // Clears first: on a transparent PNG, drawing over the region keeps the original detail.
  ctx.clearRect(x, y, width, height);
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(small, 0, 0, small.width, small.height, x, y, width, height);
  ctx.imageSmoothingEnabled = true;
};

const crop = (canvas, { x, y, width, height }) => {
  const cropped = createCanvas(Math.round(width), Math.round(height));
  cropped.getContext('2d').drawImage(canvas, -Math.round(x), -Math.round(y));
  return cropped;
};

// Draws a shape, or the outline that previews a blur or crop region while the user drags.
export const drawOperation = (canvas, { type, start, end }) => {
  const ctx = canvas.getContext('2d');
  const lineWidth = strokeWidthFor(canvas.width, canvas.height);
  const rect = normalizeRect(start, end);
  ctx.save();
  ctx.strokeStyle = EDITOR_COLOR;
  ctx.fillStyle = EDITOR_COLOR;
  ctx.lineWidth = lineWidth;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  if (type === 'arrow') drawArrow(ctx, start, end, lineWidth);
  if (type === 'rect') ctx.strokeRect(rect.x, rect.y, rect.width, rect.height);
  if (type === 'ellipse') drawEllipse(ctx, rect);
  if (REGION_TOOLS.includes(type)) {
    ctx.setLineDash([lineWidth * 3, lineWidth * 2]);
    ctx.strokeRect(rect.x, rect.y, rect.width, rect.height);
  }
  ctx.restore();
};

// Replays every operation over the original image. Coordinates are in the space of the
// canvas the operation was drawn on, so an operation after a crop uses the cropped space.
export const renderOperations = (image, operations) => {
  const base = createCanvas(image.width, image.height);
  base.getContext('2d').drawImage(image, 0, 0);
  return operations.reduce((canvas, operation) => {
    const rect = normalizeRect(operation.start, operation.end);
    if (operation.type === 'crop') return crop(canvas, rect);
    if (operation.type === 'blur') pixelate(canvas, rect);
    else drawOperation(canvas, operation);
    return canvas;
  }, base);
};

export const editedFileName = name => `${name.replace(/\.[^.]+$/, '')}.png`;

// The dashboard keeps a staged attachment as a data URL, so the editor gets a File back from it.
export const dataUrlToFile = (dataUrl, name) => {
  const [header, data] = dataUrl.split(',');
  const type = header.match(/^data:([^;]+)/)[1];
  const bytes = Uint8Array.from(atob(data), char => char.charCodeAt(0));
  return new File([bytes], name, { type });
};
