export const IMAGE_OPTIMIZATION_ERRORS = {
  UNSUPPORTED: 'UNSUPPORTED',
  DECODE_FAILED: 'DECODE_FAILED',
  TOO_LARGE: 'TOO_LARGE',
};

// A tiny result from a heavy source means the canvas silently came out blank (Safari).
// Light sources are exempt: a flat banner can legitimately encode to a few hundred bytes.
const MIN_VALID_BLOB_BYTES = 2048;
const BLANK_GUARD_MIN_SOURCE_BYTES = 256 * 1024;

export class ImageOptimizationError extends Error {
  constructor(code, message = code) {
    super(message);
    this.name = 'ImageOptimizationError';
    this.code = code;
  }
}

export const isImageOptimizationSupported = () => {
  try {
    if (typeof document === 'undefined') return false;
    if (typeof HTMLCanvasElement === 'undefined') return false;
    if (typeof HTMLCanvasElement.prototype.toBlob !== 'function') return false;
    if (typeof URL === 'undefined' || typeof URL.createObjectURL !== 'function')
      return false;
    const canvas = document.createElement('canvas');
    return !!canvas.getContext('2d');
  } catch (error) {
    return false;
  }
};

const assertSupported = () => {
  if (!isImageOptimizationSupported()) {
    throw new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED);
  }
};

const decodeImage = file =>
  new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const release = () => URL.revokeObjectURL(url);
    const img = new Image();
    img.onload = () => resolve({ img, release });
    img.onerror = () => {
      release();
      reject(
        new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED)
      );
    };
    img.src = url;
  });

const toBlob = (canvas, quality) =>
  new Promise(resolve => {
    canvas.toBlob(resolve, 'image/jpeg', quality);
  });

const renderStep = async (img, { maxSide, quality }) => {
  const width = img.naturalWidth;
  const height = img.naturalHeight;
  const scale = Math.min(1, maxSide / Math.max(width, height));
  const targetWidth = Math.max(1, Math.round(width * scale));
  const targetHeight = Math.max(1, Math.round(height * scale));

  const canvas = document.createElement('canvas');
  canvas.width = targetWidth;
  canvas.height = targetHeight;
  try {
    const context = canvas.getContext('2d');
    context.fillStyle = '#fff';
    context.fillRect(0, 0, targetWidth, targetHeight);
    context.imageSmoothingQuality = 'high';
    context.drawImage(img, 0, 0, targetWidth, targetHeight);
    const blob = await toBlob(canvas, quality);
    return { blob, width: targetWidth, height: targetHeight };
  } finally {
    canvas.width = 0;
    canvas.height = 0;
  }
};

export const getLongestSide = async file => {
  assertSupported();
  const { img, release } = await decodeImage(file);
  try {
    return Math.max(img.naturalWidth, img.naturalHeight);
  } finally {
    release();
  }
};

export const optimizeImage = async (file, { maxBytes, ladder }) => {
  assertSupported();
  const { img, release } = await decodeImage(file);
  try {
    // Steps run sequentially on purpose: the first one that fits wins.
    for (let i = 0; i < ladder.length; i += 1) {
      // eslint-disable-next-line no-await-in-loop
      const { blob, width, height } = await renderStep(img, ladder[i]);
      if (!blob) {
        throw new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED);
      }
      if (
        blob.size < MIN_VALID_BLOB_BYTES &&
        file.size > BLANK_GUARD_MIN_SOURCE_BYTES
      ) {
        throw new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE);
      }
      if (blob.size <= maxBytes) {
        const baseName = file.name.replace(/\.[^./\\]+$/, '');
        return {
          file: new File([blob], `${baseName}.jpg`, {
            type: 'image/jpeg',
            lastModified: Date.now(),
          }),
          width,
          height,
        };
      }
    }
    throw new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE);
  } finally {
    release();
  }
};
