import {
  ImageOptimizationError,
  IMAGE_OPTIMIZATION_ERRORS,
  isImageOptimizationSupported,
  getLongestSide,
  optimizeImage,
} from '../imageOptimizer';

const LADDER = [
  { maxSide: 2000, quality: 0.9 },
  { maxSide: 1000, quality: 0.8 },
];

describe('imageOptimizer', () => {
  let imageSize;
  let decodeFails;
  let context;
  let sizeFor;
  let originalImage;
  let originalToBlob;
  let originalGetContext;
  let originalCreate;
  let originalRevoke;

  const makeFile = (name = 'photo.png') =>
    new File(['x'], name, { type: 'image/png' });

  beforeEach(() => {
    imageSize = { width: 4000, height: 3000 };
    decodeFails = false;
    context = { fillRect: vi.fn(), drawImage: vi.fn() };
    // Blob size grows with pixels and quality, so steps can be told apart.
    sizeFor = (w, h, q) => Math.round(w * h * q * 0.01);

    originalImage = global.Image;
    originalToBlob = HTMLCanvasElement.prototype.toBlob;
    originalGetContext = HTMLCanvasElement.prototype.getContext;
    originalCreate = URL.createObjectURL;
    originalRevoke = URL.revokeObjectURL;

    global.Image = class {
      set src(value) {
        this.srcValue = value;
        setTimeout(() => {
          if (decodeFails) {
            this.onerror?.();
          } else {
            this.naturalWidth = imageSize.width;
            this.naturalHeight = imageSize.height;
            this.onload?.();
          }
        });
      }
    };
    URL.createObjectURL = vi.fn(() => 'blob:fake');
    URL.revokeObjectURL = vi.fn();
    HTMLCanvasElement.prototype.getContext = vi.fn(() => context);
    HTMLCanvasElement.prototype.toBlob = function toBlob(cb, type, quality) {
      cb(
        new Blob([new Uint8Array(sizeFor(this.width, this.height, quality))], {
          type,
        })
      );
    };
  });

  afterEach(() => {
    global.Image = originalImage;
    HTMLCanvasElement.prototype.toBlob = originalToBlob;
    HTMLCanvasElement.prototype.getContext = originalGetContext;
    URL.createObjectURL = originalCreate;
    URL.revokeObjectURL = originalRevoke;
  });

  const expectCode = async (promise, code) => {
    const error = await promise.catch(e => e);
    expect(error).toBeInstanceOf(ImageOptimizationError);
    expect(error.code).toBe(code);
  };

  describe('isImageOptimizationSupported', () => {
    it('returns true when canvas, toBlob and object URLs exist', () => {
      expect(isImageOptimizationSupported()).toBe(true);
    });

    it('returns false without toBlob', () => {
      HTMLCanvasElement.prototype.toBlob = undefined;
      expect(isImageOptimizationSupported()).toBe(false);
    });

    it('returns false without a 2d context', () => {
      HTMLCanvasElement.prototype.getContext = vi.fn(() => null);
      expect(isImageOptimizationSupported()).toBe(false);
    });

    it('returns false when detection throws', () => {
      HTMLCanvasElement.prototype.getContext = vi.fn(() => {
        throw new Error('boom');
      });
      expect(isImageOptimizationSupported()).toBe(false);
    });
  });

  describe('getLongestSide', () => {
    it('returns the width for a landscape image', async () => {
      expect(await getLongestSide(makeFile())).toBe(4000);
    });

    it('returns the height for a portrait image', async () => {
      imageSize = { width: 3000, height: 5000 };
      expect(await getLongestSide(makeFile())).toBe(5000);
    });

    it('throws DECODE_FAILED when the image cannot be decoded', async () => {
      decodeFails = true;
      await expectCode(
        getLongestSide(makeFile()),
        IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED
      );
    });

    it('throws UNSUPPORTED without support', async () => {
      HTMLCanvasElement.prototype.toBlob = undefined;
      await expectCode(
        getLongestSide(makeFile()),
        IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED
      );
    });
  });

  describe('optimizeImage', () => {
    it('returns a .jpg within maxBytes at the first step', async () => {
      const result = await optimizeImage(makeFile('photo.png'), {
        maxBytes: 200000,
        ladder: LADDER,
      });
      expect(result.file.name).toBe('photo.jpg');
      expect(result.file.type).toBe('image/jpeg');
      expect(result.file.size).toBeLessThanOrEqual(200000);
      expect(result.width).toBe(2000);
      expect(result.height).toBe(1500);
    });

    it('drops to the next step when the first does not fit', async () => {
      // step 1: 2000x1500x0.9x0.01 = 27000; step 2: 1000x750x0.8x0.01 = 6000
      const result = await optimizeImage(makeFile(), {
        maxBytes: 10000,
        ladder: LADDER,
      });
      expect(result.width).toBe(1000);
      expect(result.height).toBe(750);
      expect(result.file.size).toBeLessThanOrEqual(10000);
    });

    it('never upscales smaller images', async () => {
      imageSize = { width: 800, height: 600 };
      sizeFor = () => 5000;
      const result = await optimizeImage(makeFile(), {
        maxBytes: 100000,
        ladder: LADDER,
      });
      expect(result.width).toBe(800);
      expect(result.height).toBe(600);
    });

    it('fills white before drawing', async () => {
      const order = [];
      context.fillRect.mockImplementation(() => order.push('fill'));
      context.drawImage.mockImplementation(() => order.push('draw'));
      await optimizeImage(makeFile(), { maxBytes: 200000, ladder: LADDER });
      expect(context.fillStyle).toBe('#fff');
      expect(order).toEqual(['fill', 'draw']);
    });

    it('throws DECODE_FAILED', async () => {
      decodeFails = true;
      await expectCode(
        optimizeImage(makeFile(), { maxBytes: 1, ladder: LADDER }),
        IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED
      );
    });

    it('throws UNSUPPORTED without toBlob', async () => {
      HTMLCanvasElement.prototype.toBlob = undefined;
      await expectCode(
        optimizeImage(makeFile(), { maxBytes: 1, ladder: LADDER }),
        IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED
      );
    });

    it('throws UNSUPPORTED when toBlob returns null', async () => {
      HTMLCanvasElement.prototype.toBlob = cb => cb(null);
      await expectCode(
        optimizeImage(makeFile(), { maxBytes: 200000, ladder: LADDER }),
        IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED
      );
    });

    it('throws TOO_LARGE when no step fits', async () => {
      await expectCode(
        optimizeImage(makeFile(), { maxBytes: 3000, ladder: LADDER }),
        IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE
      );
    });

    it('throws TOO_LARGE when the blob is under 2 KB', async () => {
      sizeFor = () => 100;
      await expectCode(
        optimizeImage(makeFile(), { maxBytes: 200000, ladder: LADDER }),
        IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE
      );
    });

    it('revokes the object URL on success and on failure', async () => {
      await optimizeImage(makeFile(), { maxBytes: 200000, ladder: LADDER });
      expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:fake');

      URL.revokeObjectURL.mockClear();
      await optimizeImage(makeFile(), { maxBytes: 1, ladder: LADDER }).catch(
        () => {}
      );
      expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);

      URL.revokeObjectURL.mockClear();
      decodeFails = true;
      await optimizeImage(makeFile(), { maxBytes: 1, ladder: LADDER }).catch(
        () => {}
      );
      expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);
    });
  });
});
