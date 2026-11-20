import { mount, flushPromises } from '@vue/test-utils';
import ImageEditor from '../ImageEditor.vue';

const file = new File(['original'], 'photo.jpg', { type: 'image/jpeg' });

const fakeContext = {
  drawImage: vi.fn(),
  clearRect: vi.fn(),
  strokeRect: vi.fn(),
  save: vi.fn(),
  restore: vi.fn(),
  beginPath: vi.fn(),
  moveTo: vi.fn(),
  lineTo: vi.fn(),
  closePath: vi.fn(),
  stroke: vi.fn(),
  fill: vi.fn(),
  ellipse: vi.fn(),
  setLineDash: vi.fn(),
};

// The editor teleports to the body, so its controls are queried from the document.
const control = label => document.querySelector(`[aria-label="${label}"]`);
const button = text =>
  [...document.querySelectorAll('button')].find(
    b => b.textContent.trim() === text
  );

const click = async element => {
  element.click();
  await flushPromises();
};

// jsdom has no PointerEvent, so a MouseEvent carries the pointer fields.
const drag = async (from, to) => {
  const canvas = document.querySelector('canvas');
  [
    ['pointerdown', from],
    ['pointermove', to],
    ['pointerup', to],
  ].forEach(([type, [clientX, clientY]]) => {
    const event = new MouseEvent(type, { clientX, clientY });
    Object.assign(event, { isPrimary: true, pointerId: 1 });
    canvas.dispatchEvent(event);
  });
  await flushPromises();
};

describe('ImageEditor', () => {
  let wrapper;

  const mountEditor = async () => {
    wrapper = mount(ImageEditor, {
      props: { file, confirmClass: 'bg-[var(--widget-color)]', isDark: true },
      attachTo: document.body,
    });
    await flushPromises();
  };

  const savedFiles = () => (wrapper.emitted('save') || []).map(([f]) => f);

  beforeEach(() => {
    window.createImageBitmap = vi.fn(async () => ({
      width: 800,
      height: 600,
      close: vi.fn(),
    }));
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue(
      fakeContext
    );
    HTMLCanvasElement.prototype.setPointerCapture = vi.fn();
    HTMLCanvasElement.prototype.getBoundingClientRect = () => ({
      left: 0,
      top: 0,
      width: 800,
      height: 600,
    });
    HTMLCanvasElement.prototype.toBlob = function toBlob(callback, type) {
      callback(new Blob(['edited'], { type }));
    };
  });

  afterEach(() => wrapper.unmount());

  it('uses the confirm classes and the dark mode it receives', async () => {
    await mountEditor();
    const send = button('IMAGE_EDITOR.SEND');

    expect(send.classList.contains('bg-[var(--widget-color)]')).toBe(true);
    expect(send.getAttribute('style')).toBeNull();
    expect(
      document.querySelector('[role="dialog"]').closest('.dark')
    ).not.toBeNull();
  });

  it('sends the original file untouched when nothing was drawn', async () => {
    await mountEditor();

    await click(button('IMAGE_EDITOR.SEND'));

    expect(savedFiles()).toHaveLength(1);
    expect(savedFiles()[0]).toBe(file);
  });

  it('sends a PNG of the edited image after a drawing', async () => {
    await mountEditor();

    await drag([10, 10], [200, 150]);
    await click(button('IMAGE_EDITOR.SEND'));

    const [saved] = savedFiles();
    expect(saved).not.toBe(file);
    expect(saved.name).toBe('photo.png');
    expect(saved.type).toBe('image/png');
  });

  it('ignores a click without a drag', async () => {
    await mountEditor();

    await drag([50, 50], [51, 50]);

    expect(control('IMAGE_EDITOR.UNDO').disabled).toBe(true);
  });

  it('undo removes the drawing and redo brings it back', async () => {
    await mountEditor();
    const undo = control('IMAGE_EDITOR.UNDO');
    const redo = control('IMAGE_EDITOR.REDO');

    await drag([10, 10], [200, 150]);
    await click(undo);

    expect(undo.disabled).toBe(true);
    await click(button('IMAGE_EDITOR.SEND'));
    expect(savedFiles()[0]).toBe(file);

    await click(redo);
    expect(redo.disabled).toBe(true);
    expect(undo.disabled).toBe(false);
  });

  it('a new drawing after undo clears the redo history', async () => {
    await mountEditor();

    await drag([10, 10], [200, 150]);
    await click(control('IMAGE_EDITOR.UNDO'));
    await drag([10, 10], [200, 150]);

    expect(control('IMAGE_EDITOR.REDO').disabled).toBe(true);
  });

  it('keeps the focus, undoes with Ctrl+Z and cancels with Escape', async () => {
    await mountEditor();
    const press = init =>
      document.activeElement.dispatchEvent(
        new KeyboardEvent('keydown', { bubbles: true, ...init })
      );

    expect(document.activeElement.getAttribute('role')).toBe('dialog');
    const chatInput = document.body.appendChild(
      document.createElement('textarea')
    );
    chatInput.focus();
    expect(document.activeElement.getAttribute('role')).toBe('dialog');
    chatInput.remove();
    await drag([10, 10], [200, 150]);
    press({ key: 'z', ctrlKey: true });
    await flushPromises();
    expect(control('IMAGE_EDITOR.UNDO').disabled).toBe(true);

    press({ key: 'Escape' });
    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('gives the focus back to the composer when it closes', async () => {
    const composer = document.body.appendChild(
      document.createElement('textarea')
    );
    composer.focus();
    await mountEditor();

    wrapper.unmount();

    expect(document.activeElement).toBe(composer);
    composer.remove();
    wrapper = mount({ render: () => null });
  });

  it('keeps key presses inside the editor, away from page shortcuts', async () => {
    await mountEditor();
    const page = vi.fn();
    document.addEventListener('keypress', page);
    document.addEventListener('keydown', page);

    control('IMAGE_EDITOR.UNDO').dispatchEvent(
      new KeyboardEvent('keypress', { key: 'Enter', bubbles: true })
    );
    control('IMAGE_EDITOR.UNDO').dispatchEvent(
      new KeyboardEvent('keydown', { key: 'p', altKey: true, bubbles: true })
    );

    document.removeEventListener('keypress', page);
    document.removeEventListener('keydown', page);
    expect(page).not.toHaveBeenCalled();
  });

  it('stays open and sends nothing when the browser cannot encode the image', async () => {
    HTMLCanvasElement.prototype.toBlob = callback => callback(null);
    await mountEditor();

    await drag([10, 10], [200, 150]);
    await click(button('IMAGE_EDITOR.SEND'));

    expect(wrapper.emitted('save')).toBeUndefined();
    expect(button('IMAGE_EDITOR.SEND').disabled).toBe(false);
    expect(document.querySelector('[role="alert"]').textContent).toContain(
      'IMAGE_EDITOR.EXPORT_ERROR'
    );
  });

  it('stays open with the drawing when the edit is over the size limit', async () => {
    wrapper = mount(ImageEditor, {
      props: { file, maxSizeMb: 0.000001 },
      attachTo: document.body,
    });
    await flushPromises();

    await drag([10, 10], [200, 150]);
    await click(button('IMAGE_EDITOR.SEND'));

    expect(wrapper.emitted('save')).toBeUndefined();
    expect(control('IMAGE_EDITOR.UNDO').disabled).toBe(false);
    expect(document.querySelector('[role="alert"]').textContent).toContain(
      'IMAGE_EDITOR.TOO_LARGE'
    );
  });

  it('drops an image that finishes decoding after the editor closed', async () => {
    let finishDecode;
    const bitmap = { width: 800, height: 600, close: vi.fn() };
    window.createImageBitmap = vi.fn(
      () =>
        new Promise(resolve => {
          finishDecode = resolve;
        })
    );
    await mountEditor();

    wrapper.unmount();
    finishDecode(bitmap);
    await flushPromises();

    expect(bitmap.close).toHaveBeenCalled();
    wrapper = mount({ render: () => null });
  });

  it('discards the image on cancel', async () => {
    await mountEditor();

    await click(button('IMAGE_EDITOR.CANCEL'));

    expect(wrapper.emitted('cancel')).toHaveLength(1);
    expect(wrapper.emitted('save')).toBeUndefined();
  });

  it('sends the original file when the browser cannot decode it', async () => {
    window.createImageBitmap = vi.fn(async () => {
      throw new DOMException('decode failed', 'InvalidStateError');
    });

    await mountEditor();

    expect(savedFiles()[0]).toBe(file);
  });
});
