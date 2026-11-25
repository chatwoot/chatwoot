import { shallowMount } from '@vue/test-utils';
import ActionButtons from '../ActionButtons.vue';

const mockAlert = vi.fn();
vi.mock('dashboard/composables', async () => {
  const actual = await vi.importActual('dashboard/composables');
  return { ...actual, useAlert: (...args) => mockAlert(...args) };
});

const mockOnFileUpload = vi.fn();
vi.mock('dashboard/composables/useFileUpload', () => ({
  useFileUpload: () => ({
    onFileUpload: (...args) => mockOnFileUpload(...args),
  }),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({
    uiSettings: {},
    updateUISettings: vi.fn(),
    isEditorHotKeyEnabled: () => false,
  }),
}));

const file = (name, type, size) =>
  new File(size ? [new Uint8Array(size)] : [], name, { type });

// The paste listener is bound to `document` and outlives the component in this environment
// (measured with a bare probe component too, so it is @vueuse plus the test runner rather than
// anything this component does). Every example still unmounts, and the upload assertions look at
// the last call rather than the count, so a listener from an earlier example cannot decide the
// result.
const mounted = [];
afterEach(() => {
  while (mounted.length) mounted.pop().unmount();
});

const mountButtons = () => {
  const wrapper = shallowMount(ActionButtons, {
    props: { isEmailOrWebWidgetInbox: true },
    global: { mocks: { $t: key => key } },
  });
  mounted.push(wrapper);
  return wrapper;
};

const paste = clipboardData => {
  const event = new Event('paste');
  event.clipboardData = clipboardData;
  document.dispatchEvent(event);
};

// The third composer with the same paste handler, and the one nobody would think to check: it
// only exists inside the new-conversation modal. Without an example here, the empty-file
// refusal could be removed from it and every other test would stay green.
describe('ActionButtons paste', () => {
  it('says the pasted file was empty when the clipboard carried no text', () => {
    mountButtons();

    paste({ types: ['Files'], files: [file('vazio.txt', 'text/plain', 0)] });

    expect(mockAlert).toHaveBeenCalledWith('CONVERSATION.FILE_IS_EMPTY');
    expect(mockOnFileUpload).not.toHaveBeenCalled();
  });

  it('stays quiet for a rich paste that brings an empty attachment along', () => {
    mountButtons();

    paste({
      types: ['text/plain', 'text/html', 'text/rtf', 'Files'],
      files: [file('image.png', 'image/png', 0)],
    });

    expect(mockAlert).not.toHaveBeenCalled();
    expect(mockOnFileUpload).not.toHaveBeenCalled();
  });

  it('still uploads a real pasted file', () => {
    mountButtons();

    paste({ types: ['Files'], files: [file('valido.txt', 'text/plain', 4)] });

    expect(mockAlert).not.toHaveBeenCalled();
    expect(mockOnFileUpload).toHaveBeenCalled();
    expect(mockOnFileUpload.mock.calls.at(-1)[0]).toMatchObject({
      name: 'valido.txt',
      size: 4,
    });
  });
});
