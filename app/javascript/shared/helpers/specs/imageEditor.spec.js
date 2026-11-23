import {
  dataUrlToFile,
  editedFileName,
  isEditableImage,
  isMeaningfulOperation,
  normalizeRect,
  renderOperations,
  strokeWidthFor,
  toCanvasPoint,
} from '../imageEditor';

const fakeContext = canvas => ({
  canvas,
  calls: [],
  imageSmoothingEnabled: true,
  drawImage(...args) {
    this.calls.push(['drawImage', args, this.imageSmoothingEnabled]);
  },
  clearRect(...args) {
    this.calls.push(['clearRect', args]);
  },
  strokeRect(...args) {
    this.calls.push(['strokeRect', args]);
  },
  ellipse(...args) {
    this.calls.push(['ellipse', args]);
  },
  save() {},
  restore() {},
  beginPath() {},
  moveTo() {},
  lineTo() {},
  closePath() {},
  stroke() {},
  fill() {},
  setLineDash() {},
});

describe('imageEditor', () => {
  beforeEach(() => {
    const contexts = new WeakMap();
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockImplementation(
      function getContext() {
        if (!contexts.has(this)) contexts.set(this, fakeContext(this));
        return contexts.get(this);
      }
    );
  });

  describe('isEditableImage', () => {
    it('opens the editor for raster images', () => {
      expect(isEditableImage('image/png')).toBe(true);
      expect(isEditableImage('image/jpeg')).toBe(true);
      expect(isEditableImage('image/webp')).toBe(true);
    });

    it('skips animated, vector and non-image files', () => {
      expect(isEditableImage('image/gif')).toBe(false);
      expect(isEditableImage('image/svg+xml')).toBe(false);
      expect(isEditableImage('application/pdf')).toBe(false);
    });
  });

  it('normalizeRect gives a positive size for a drag towards the top left', () => {
    expect(normalizeRect({ x: 50, y: 40 }, { x: 10, y: 15 })).toEqual({
      x: 10,
      y: 15,
      width: 40,
      height: 25,
    });
  });

  describe('toCanvasPoint', () => {
    const canvas = document.createElement('canvas');
    canvas.width = 1000;
    canvas.height = 500;
    canvas.getBoundingClientRect = () => ({
      left: 20,
      top: 10,
      width: 250,
      height: 125,
    });

    it('scales the display position to canvas pixels', () => {
      expect(toCanvasPoint({ clientX: 145, clientY: 60 }, canvas)).toEqual({
        x: 500,
        y: 200,
      });
    });

    it('clamps a captured pointer that left the canvas', () => {
      expect(toCanvasPoint({ clientX: 0, clientY: 900 }, canvas)).toEqual({
        x: 0,
        y: 500,
      });
    });
  });

  it('strokeWidthFor keeps a 3px minimum and grows with the image', () => {
    expect(strokeWidthFor(300, 200)).toBe(3);
    expect(strokeWidthFor(3840, 2160)).toBe(18);
  });

  it('isMeaningfulOperation treats a click as no operation', () => {
    const start = { x: 10, y: 10 };
    expect(isMeaningfulOperation({ type: 'arrow', start, end: start })).toBe(
      false
    );
    expect(
      isMeaningfulOperation({ type: 'rect', start, end: { x: 80, y: 11 } })
    ).toBe(false);
    expect(
      isMeaningfulOperation({ type: 'crop', start, end: { x: 80, y: 60 } })
    ).toBe(true);
  });

  describe('renderOperations', () => {
    const image = { width: 800, height: 600 };

    it('draws the image and then each operation in order', () => {
      const canvas = renderOperations(image, [
        { type: 'rect', start: { x: 10, y: 10 }, end: { x: 100, y: 50 } },
        { type: 'ellipse', start: { x: 0, y: 0 }, end: { x: 40, y: 20 } },
      ]);
      const names = canvas.getContext('2d').calls.map(([name]) => name);

      expect([canvas.width, canvas.height]).toEqual([800, 600]);
      expect(names).toEqual(['drawImage', 'strokeRect', 'ellipse']);
    });

    it('crops to the region and applies later operations to the cropped image', () => {
      const canvas = renderOperations(image, [
        { type: 'crop', start: { x: 300, y: 250 }, end: { x: 100, y: 50 } },
        { type: 'rect', start: { x: 0, y: 0 }, end: { x: 20, y: 20 } },
      ]);
      const [copy, rect] = canvas.getContext('2d').calls;

      expect([canvas.width, canvas.height]).toEqual([200, 200]);
      expect(copy[1].slice(1)).toEqual([-100, -50]);
      expect(rect).toEqual(['strokeRect', [0, 0, 20, 20]]);
    });

    it('replaces a blur region with its pixelated copy, without smoothing', () => {
      const canvas = renderOperations(image, [
        { type: 'blur', start: { x: 100, y: 100 }, end: { x: 200, y: 150 } },
      ]);
      const [, cleared, pixelated] = canvas.getContext('2d').calls;

      expect(cleared).toEqual(['clearRect', [100, 100, 100, 50]]);
      expect(pixelated[1].slice(5)).toEqual([100, 100, 100, 50]);
      expect(pixelated[2]).toBe(false);
      expect(canvas.getContext('2d').imageSmoothingEnabled).toBe(true);
    });
  });

  it('editedFileName swaps the extension for png', () => {
    expect(editedFileName('photo.final.jpeg')).toBe('photo.final.png');
    expect(editedFileName('clipboard')).toBe('clipboard.png');
  });

  it('dataUrlToFile rebuilds the staged file', () => {
    const file = dataUrlToFile('data:image/png;base64,aGVsbG8=', 'shot.png');

    expect([file.name, file.type, file.size]).toEqual([
      'shot.png',
      'image/png',
      'hello'.length,
    ]);
  });
});
