import { mount } from '@vue/test-utils';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { createStore } from 'vuex';
import Editor from './Editor.vue';

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { accountId: 1 } }),
  useRouter: () => ({ push: vi.fn() }),
}));

let view = null;

// The component keeps its EditorView in a module local, so subclass it to
// reach the DOM event handlers it registers.
vi.mock('@chatwoot/prosemirror-schema', async importOriginal => {
  const actual = await importOriginal();
  class TrackedEditorView extends actual.EditorView {
    constructor(...args) {
      super(...args);
      view = this;
    }
  }
  return { ...actual, EditorView: TrackedEditorView };
});

// jsdom has no layout, and ProseMirror measures the caret through Range rects.
const zeroRect = { top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0 };
Range.prototype.getClientRects = () => [zeroRect];
Range.prototype.getBoundingClientRect = () => zeroRect;
Element.prototype.scrollIntoView = () => {};

const store = createStore({
  getters: {
    getUISettings: () => ({ editor_message_key: 'enter' }),
    getSelectedChat: () => ({}),
    'globalConfig/get': () => ({}),
    'globalConfig/isOnChatwootCloud': () => false,
    'accounts/getAccount': () => () => ({}),
    'accounts/getUIFlags': () => ({}),
    'accounts/isFeatureEnabledonAccount': () => () => false,
    'draftMessages/getReplyEditorMode': () => 'reply',
  },
});

let wrapper = null;

afterEach(() => {
  wrapper?.unmount();
  wrapper = null;
});

const mountEditor = () => {
  wrapper = mount(Editor, {
    props: { modelValue: 'thanks for reaching ou' },
    global: { plugins: [store] },
    attachTo: document.body,
  });
};

// Runs the editor's own keydown handler, without ProseMirror's keymap, so the
// assertion is about what this component does with the event.
const editorKeydown = init => {
  const event = new KeyboardEvent('keydown', {
    key: 'Enter',
    code: 'Enter',
    cancelable: true,
    ...init,
  });
  view.someProp('handleDOMEvents', handlers => handlers.keydown?.(view, event));
  return event;
};

describe('Editor', () => {
  describe('Enter with enter-to-send enabled', () => {
    it('prevents the line break on a normal Enter', () => {
      mountEditor();
      expect(editorKeydown({}).defaultPrevented).toBe(true);
    });

    it('leaves Enter alone while an IME composition is active', () => {
      mountEditor();
      expect(editorKeydown({ isComposing: true }).defaultPrevented).toBe(false);
    });

    it('leaves Enter alone when WebKit reports the composition only through keyCode 229', () => {
      mountEditor();
      expect(editorKeydown({ keyCode: 229 }).defaultPrevented).toBe(false);
    });
  });
});
