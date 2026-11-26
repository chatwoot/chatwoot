import { Selection } from '@chatwoot/prosemirror-schema';
import { flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import Editor from './Editor.vue';

vi.mock('dashboard/helper/uploadHelper', () => ({
  uploadFile: vi.fn(),
}));

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
    'accounts/isFeatureEnabledonAccount': () => (_accountId, feature) =>
      feature === 'captain_tasks',
    'draftMessages/getReplyEditorMode': () => 'reply',
  },
});

let wrapper = null;

afterEach(() => {
  wrapper?.unmount();
  wrapper = null;
});

const mountEditor = ({ props = {}, attrs = {} } = {}) => {
  wrapper = mount(Editor, {
    props: { modelValue: 'thanks for reaching ou', ...props },
    attrs,
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

const image = new File(['image'], 'dashboard.png', { type: 'image/png' });
const textFile = new File(['notes'], 'notes.txt', { type: 'text/plain' });

const editorPaste = files => {
  const event = {
    clipboardData: { files, getData: () => '' },
    preventDefault: vi.fn(),
  };
  view.someProp('handleDOMEvents', handlers => handlers.paste?.(view, event));
};

const editorDrop = files => {
  const event = { dataTransfer: { files }, preventDefault: vi.fn() };
  view.someProp('handleDOMEvents', handlers => handlers.drop?.(view, event));
  return event;
};

const lastContent = () => wrapper.emitted('update:modelValue').at(-1)[0];

describe('Editor', () => {
  describe('images in the canned response editor', () => {
    beforeEach(() => {
      uploadFile.mockReset();
      uploadFile.mockResolvedValue({ fileUrl: 'https://cdn.test/shot.png' });
    });

    it('writes a pasted image into the message', async () => {
      mountEditor({ props: { channelType: 'Context::CannedResponse' } });

      editorPaste([image]);
      await flushPromises();

      expect(uploadFile).toHaveBeenCalledWith(image);
      expect(lastContent()).toContain('![](https://cdn.test/shot.png)');
    });

    it('writes a dropped image into the message and skips other files', async () => {
      mountEditor({ props: { channelType: 'Context::CannedResponse' } });

      const event = editorDrop([textFile, image]);
      await flushPromises();

      expect(event.preventDefault).toHaveBeenCalled();
      expect(uploadFile).toHaveBeenCalledTimes(1);
      expect(lastContent()).toContain('![](https://cdn.test/shot.png)');
    });

    it('leaves a pasted image to the reply box on a conversation channel', async () => {
      mountEditor({ props: { channelType: 'Channel::WebWidget' } });

      editorPaste([image]);
      await flushPromises();

      expect(uploadFile).not.toHaveBeenCalled();
    });
  });

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

  describe('AI menu opened from the floating toolbar', () => {
    it('stays anchored to the selection when the editor loses focus', async () => {
      mountEditor({
        props: { channelType: 'Channel::Email' },
        attrs: { class: 'popover-prosemirror-menu' },
      });
      const selection = Selection.fromJSON(view.state.doc, {
        type: 'text',
        anchor: 1,
        head: 7,
      });
      view.dispatch(view.state.tr.setSelection(selection));
      await wrapper.find('.ProseMirror-copilot').trigger('mousedown');

      view.dom.dispatchEvent(new FocusEvent('blur'));
      await nextTick();

      const menu = wrapper.find('.copilot-editor-menu');
      expect(menu.classes()).toContain('selection-menu');
    });
  });
});
