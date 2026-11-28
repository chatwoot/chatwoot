import { Selection } from '@chatwoot/prosemirror-schema';
import { mount } from '@vue/test-utils';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import Editor from './Editor.vue';
import KeyboardEmojiSelector from './keyboardEmojiSelector.vue';
import CannedResponse from '../conversation/CannedResponse.vue';
import TagAgents from '../conversation/TagAgents.vue';

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

const mountEditor = ({ props = {}, attrs = {}, stubs = {} } = {}) => {
  wrapper = mount(Editor, {
    props: { modelValue: 'thanks for reaching ou', ...props },
    attrs,
    global: { plugins: [store], stubs },
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

  describe('a trigger typed in front of existing text', () => {
    const stubs = { CannedResponse: true, KeyboardEmojiSelector: true };

    const typeAtStart = async text => {
      const start = Selection.atStart(view.state.doc);
      view.dispatch(view.state.tr.setSelection(start).insertText(text));
      await nextTick();
    };

    it('searches for nothing until something is typed after it', async () => {
      mountEditor({ props: { modelValue: 'refund' }, stubs });
      await typeAtStart('/');

      expect(wrapper.findComponent(CannedResponse).props('searchKey')).toBe('');
    });

    it('keeps that text when the pick is inserted', async () => {
      mountEditor({ props: { modelValue: 'refund' }, stubs });
      await typeAtStart('/');

      wrapper.findComponent(CannedResponse).vm.$emit('replace', 'Hello');
      await nextTick();

      expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([
        'Hello refund',
      ]);
    });

    it('does not open the emoji picker for a lone colon', async () => {
      mountEditor({ props: { modelValue: 'refund' }, stubs });
      await typeAtStart(':');

      expect(wrapper.findComponent(KeyboardEmojiSelector).exists()).toBe(false);
    });
  });

  describe('mention list in a private note', () => {
    const mountNote = async () => {
      mountEditor({
        props: { modelValue: '', isPrivate: true, overrideLineBreaks: true },
        stubs: { TagAgents: true },
      });
      view.dispatch(view.state.tr.insertText('@di'));
      await nextTick();
      return wrapper.findComponent(TagAgents);
    };

    const setMatches = async (list, hasMatches) => {
      list.vm.$emit('update:hasMatches', hasMatches);
      await nextTick();
    };

    const press = (key, keyCode) =>
      view.dom.dispatchEvent(
        new KeyboardEvent('keydown', {
          key,
          keyCode,
          bubbles: true,
          cancelable: true,
        })
      );

    const pressEnter = () => press('Enter', 13);

    it('counts as open only while somebody matches', async () => {
      const list = await mountNote();
      await setMatches(list, true);
      await setMatches(list, false);

      expect(wrapper.emitted('toggleUserMention')).toEqual([[true], [false]]);
    });

    it('keeps the arrow and Tab keys from the bullet list being typed in', async () => {
      mountEditor({
        props: { modelValue: '- first\n- second', isPrivate: true },
        stubs: { TagAgents: true },
      });
      const end = Selection.atEnd(view.state.doc);
      view.dispatch(view.state.tr.setSelection(end).insertText(' @di'));
      await nextTick();
      await setMatches(wrapper.findComponent(TagAgents), true);
      const note = view.state.doc.toJSON();

      press('ArrowDown', 40);
      press('Tab', 9);

      expect(view.state.doc.toJSON()).toEqual(note);
    });

    it('takes Enter only while somebody matches', async () => {
      const list = await mountNote();
      await setMatches(list, true);
      pressEnter();
      expect(view.state.doc.childCount).toBe(1);

      await setMatches(list, false);
      pressEnter();
      expect(view.state.doc.childCount).toBe(2);
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
