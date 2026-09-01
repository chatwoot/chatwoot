import { Selection } from '@chatwoot/prosemirror-schema';
import { flushPromises, mount } from '@vue/test-utils';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import { emitter } from 'shared/helpers/mitt';
import { withFullI18n } from 'test-i18n';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createStore } from 'vuex';
import FullEditor from './FullEditor.vue';

// The slash menu specs assert on translated labels, so this spec needs the
// real message catalogue instead of the empty global i18n instance.
withFullI18n();

let view = null;

// The component keeps its EditorView in a module local, so subclass it to grab
// the instance and drive the editor through transactions like a user would.
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

// jsdom has no ClipboardEvent; pasteHTML only needs a bare event object.
window.ClipboardEvent = window.ClipboardEvent || Event;

// jsdom has no object URLs, and uploads preview through blob: URLs.
let objectUrlCount = 0;
URL.createObjectURL = () => {
  objectUrlCount += 1;
  return `blob:vitest-${objectUrlCount}`;
};
URL.revokeObjectURL = () => {};

const attachImage = vi.fn();
const uploadExternalImage = vi.fn();

const store = createStore({
  actions: {
    'articles/attachImage': (_, payload) => attachImage(payload),
    'articles/uploadExternalImage': (_, payload) =>
      uploadExternalImage(payload),
  },
  getters: { getUISettings: () => ({}), 'globalConfig/get': () => ({}) },
});

let wrapper = null;

const mountEditor = (props = {}) => {
  wrapper = mount(FullEditor, {
    props: {
      modelValue: '',
      enabledMenuOptions: ARTICLE_EDITOR_MENU_OPTIONS,
      ...props,
    },
    global: {
      plugins: [store],
      mocks: { $route: { params: { portalSlug: 'handbook' } } },
    },
    attachTo: document.body,
  });
  return wrapper;
};

const type = text => view.dispatch(view.state.tr.insertText(text));

// Input rules only run through handleTextInput, which insertText bypasses.
const typeWithRules = text => {
  [...text].forEach(character => {
    const { from, to } = view.state.selection;
    const handled = view.someProp('handleTextInput', rule =>
      rule(view, from, to, character)
    );
    if (!handled) view.dispatch(view.state.tr.insertText(character, from, to));
  });
};

const selectRange = (anchor, head) =>
  view.dispatch(
    view.state.tr.setSelection(
      Selection.fromJSON(view.state.doc, { type: 'text', anchor, head })
    )
  );

const selectAll = () => selectRange(1, view.state.doc.content.size - 1);

const placeCursor = pos =>
  view.dispatch(
    view.state.tr.setSelection(Selection.near(view.state.doc.resolve(pos)))
  );

const lastEmittedValue = () => {
  const events = wrapper.emitted('update:modelValue') || [];
  return events.length ? events[events.length - 1][0] : null;
};

const markNames = () => {
  const names = new Set();
  view.state.doc.descendants(node =>
    node.marks.forEach(mark => names.add(mark.type.name))
  );
  return [...names];
};

const nodeNames = () => {
  const names = new Set();
  view.state.doc.descendants(node => names.add(node.type.name));
  return [...names];
};

const menuLabels = () => wrapper.findAll('button').map(button => button.text());

const highlightedLabel = () =>
  wrapper
    .findAll('button')
    .find(button => button.classes().includes('bg-n-alpha-1'))
    ?.text();

// prosemirror-menu binds mousedown on the icon, not on the wrapping item.
const toolbarItems = () =>
  [...wrapper.vm.$refs.editor.querySelectorAll('.ProseMirror-menuitem')].map(
    item => ({
      title: item.firstChild.getAttribute('title'),
      disabled: item.firstChild.classList.contains('ProseMirror-menu-disabled'),
      hidden: item.style.display === 'none',
      icon: item.firstChild,
    })
  );

const toolbarItem = title => toolbarItems().find(item => item.title === title);

const clickToolbar = title =>
  toolbarItem(title).icon.dispatchEvent(
    new MouseEvent('mousedown', { bubbles: true })
  );

const swallowedByEditor = (key, modifiers = {}) =>
  Boolean(
    view.someProp('handleKeyDown', handler =>
      handler(view, new KeyboardEvent('keydown', { key, ...modifiers }))
    )
  );

const pressInEditor = (key, modifiers = {}) =>
  view.dom.dispatchEvent(
    new KeyboardEvent('keydown', {
      key,
      bubbles: true,
      cancelable: true,
      ...modifiers,
    })
  );

const pressEscape = () => pressInEditor('Escape');

const fileOfSize = sizeInMb => {
  const file = new File(['x'], 'photo.png', { type: 'image/png' });
  Object.defineProperty(file, 'size', { value: sizeInMb * 1024 * 1024 });
  return file;
};

// Like a real axios call: never resolves, but rejects when its signal aborts
// (also releasing the upload queue's concurrency slot).
const pendingUpload = payload =>
  new Promise((resolve, reject) => {
    payload.signal?.addEventListener('abort', () =>
      reject(new Error('canceled'))
    );
  });

const selectFile = async file => {
  const input = wrapper.find('input[type="file"]');
  Object.defineProperty(input.element, 'files', {
    value: [file],
    configurable: true,
  });
  await input.trigger('change');
  await flushPromises();
};

describe('FullEditor', () => {
  let alerts = [];
  const collectAlert = ({ message }) => alerts.push(message);

  beforeEach(() => {
    alerts = [];
    emitter.on('newToastMessage', collectAlert);
    attachImage.mockResolvedValue('https://cdn.test/photo.png');
    uploadExternalImage.mockResolvedValue('https://cdn.test/remote.png');
  });

  afterEach(() => {
    emitter.off('newToastMessage', collectAlert);
    vi.restoreAllMocks();
    wrapper?.unmount();
    wrapper = null;
    view = null;
  });

  describe('content', () => {
    it('parses the initial markdown into the document', () => {
      mountEditor({ modelValue: '# Title\n\nBody' });

      expect(view.dom.querySelector('h1').textContent).toBe('Title');
      expect(view.state.doc.textContent).toBe('TitleBody');
    });

    it('emits the serialized markdown on every edit', async () => {
      mountEditor({ modelValue: 'Hello' });
      type(' world');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toBe('Hello world');
      expect(wrapper.emitted('input').at(-1)).toEqual(['Hello world']);
    });

    it('reloads when the model value changes outside the editor', async () => {
      mountEditor({ modelValue: 'Hello' });
      await wrapper.setProps({ modelValue: 'Replaced' });

      expect(view.state.doc.textContent).toBe('Replaced');
    });

    it('keeps the caret when the incoming value matches the editor', async () => {
      mountEditor({ modelValue: 'Hello' });
      view.dispatch(
        view.state.tr.setSelection(Selection.near(view.state.doc.resolve(1)))
      );
      await wrapper.setProps({ modelValue: 'Hello' });

      expect(view.state.selection.from).toBe(1);
    });

    it('ignores a stale echo of its own earlier output', async () => {
      mountEditor({ modelValue: 'Hello' });
      type(' world');
      await wrapper.vm.$nextTick();
      type('!');
      await wrapper.vm.$nextTick();

      // A slow autosave answering late hands back an older emission.
      await wrapper.setProps({ modelValue: 'Hello world' });

      expect(view.state.doc.textContent).toBe('Hello world!');
    });

    it('applies an external reset it initially held back once the echo window passes', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'Date'] });
      try {
        mountEditor({ modelValue: 'Hello' });
        type(' world');
        await wrapper.vm.$nextTick();
        type('!');
        await wrapper.vm.$nextTick();

        // A discard arrives while its text still looks like our own echo,
        // and no further prop update ever follows.
        await wrapper.setProps({ modelValue: 'Hello world' });
        expect(view.state.doc.textContent).toBe('Hello world!');

        vi.advanceTimersByTime(31000);
        expect(view.state.doc.textContent).toBe('Hello world');
      } finally {
        vi.useRealTimers();
      }
    });

    it('accepts external content matching an old emission once the echo window has passed', async () => {
      mountEditor({ modelValue: 'Hello' });
      type(' world');
      await wrapper.vm.$nextTick();
      type('!');
      await wrapper.vm.$nextTick();

      // E.g. discarding a draft after undoing back to the published copy.
      const nowSpy = vi
        .spyOn(Date, 'now')
        .mockImplementation(() => new Date().getTime() + 31000);
      await wrapper.setProps({ modelValue: 'Hello world' });
      nowSpy.mockRestore();

      expect(view.state.doc.textContent).toBe('Hello world');
    });

    it('applies a draft reset during a file upload and cancels the upload', async () => {
      mountEditor({ modelValue: 'Hello' });
      attachImage.mockImplementation(pendingUpload);
      await selectFile(new File(['x'], 'clip.mp4', { type: 'video/mp4' }));
      expect(view.dom.querySelector('.pm-upload-card')).not.toBeNull();

      // Discarding a draft reseeds the model with the live article.
      await wrapper.setProps({ modelValue: 'Published copy' });
      await flushPromises();

      expect(view.state.doc.textContent).toBe('Published copy');
      expect(view.dom.querySelector('.pm-upload-card')).toBeNull();
      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(true);
    });

    it('applies a draft reset during an image upload and cancels the upload', async () => {
      mountEditor({ modelValue: 'Hello' });
      attachImage.mockImplementation(pendingUpload);
      await selectFile(fileOfSize(1));
      expect(view.dom.querySelector('.pm-image-uploading')).not.toBeNull();

      await wrapper.setProps({ modelValue: 'Published copy' });
      await flushPromises();

      expect(view.state.doc.textContent).toBe('Published copy');
      expect(view.dom.querySelector('.pm-image-uploading')).toBeNull();
      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(true);
    });

    it('lets an external reset replace content once an image upload has failed', async () => {
      mountEditor({ modelValue: 'Hello' });
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(fileOfSize(1));
      expect(view.dom.querySelector('.pm-upload-overlay').dataset.state).toBe(
        'error'
      );

      // Discarding a draft reseeds the model with the live article.
      await wrapper.setProps({ modelValue: 'Published copy' });
      await flushPromises();

      expect(view.state.doc.textContent).toBe('Published copy');
      expect(view.dom.querySelector('.pm-upload-overlay')).toBeNull();
    });

    it('lets an external reset replace content once a file upload has failed', async () => {
      mountEditor({ modelValue: 'Hello' });
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(new File(['x'], 'clip.mp4', { type: 'video/mp4' }));
      expect(view.dom.querySelector('.pm-upload-card').dataset.state).toBe(
        'error'
      );

      await wrapper.setProps({ modelValue: 'Published copy' });
      await flushPromises();

      expect(view.state.doc.textContent).toBe('Published copy');
      expect(view.dom.querySelector('.pm-upload-card')).toBeNull();
    });

    it('reports a pending upload so parents can gate publish on it', async () => {
      mountEditor({ modelValue: 'Hello' });
      expect(wrapper.vm.hasPendingUploads()).toBe(false);

      let finishUpload;
      attachImage.mockImplementation(
        () =>
          new Promise(resolve => {
            finishUpload = resolve;
          })
      );
      await selectFile(new File(['x'], 'clip.mp4', { type: 'video/mp4' }));
      expect(wrapper.vm.hasPendingUploads()).toBe(true);

      finishUpload('https://cdn.test/clip.mp4');
      await flushPromises();
      expect(wrapper.vm.hasPendingUploads()).toBe(false);
    });

    it('reports a failed upload as pending until it is removed', async () => {
      mountEditor({ modelValue: 'Hello' });
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(new File(['x'], 'clip.mp4', { type: 'video/mp4' }));
      expect(view.dom.querySelector('.pm-upload-card').dataset.state).toBe(
        'error'
      );
      expect(wrapper.vm.hasPendingUploads()).toBe(true);

      view.dom.querySelector('.pm-upload-card [aria-label="Remove"]').click();
      await flushPromises();
      expect(wrapper.vm.hasPendingUploads()).toBe(false);
    });

    it('reloads when the editor id changes', async () => {
      mountEditor({ modelValue: 'Hello', editorId: 'article-1' });
      type(' edited');
      await wrapper.setProps({ editorId: 'article-2' });

      expect(view.state.doc.textContent).toBe('Hello');
    });

    it('places the caret at the end when autofocus is on', () => {
      mountEditor({ modelValue: 'First\n\nSecond' });

      expect(view.state.selection.from).toBe(view.state.doc.content.size - 1);
    });

    it('leaves the caret at the start when autofocus is off', () => {
      mountEditor({ modelValue: 'First\n\nSecond', autofocus: false });

      expect(view.state.selection.from).toBe(1);
    });
  });

  describe('slash menu', () => {
    it('opens when a slash starts a block', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showSlashMenu).toBe(true);
      expect(wrapper.vm.slashMenuPosition).toEqual({ top: 4, left: 0 });
    });

    it('stays closed for a slash inside a word', async () => {
      mountEditor({ modelValue: 'and/or' });
      type('/');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showSlashMenu).toBe(false);
    });

    it('opens with a clean term when the trigger sits right before a line break', async () => {
      mountEditor({ modelValue: 'a \\\nafter' });
      placeCursor(3);
      type('/div');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showSlashMenu).toBe(true);
      expect(menuLabels()).toEqual(['Divider']);
    });

    it('filters the list by the typed term', async () => {
      mountEditor();
      type('/div');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual(['Divider']);
    });

    it('hides on a term that matches nothing', async () => {
      mountEditor();
      type('/zzz');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual([]);
    });

    it('lists every enabled command', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual([
        'Heading 1',
        'Heading 2',
        'Heading 3',
        'Bold',
        'Italic',
        'Table',
        'Image',
        'Video',
        'Divider',
        'Strikethrough',
        'Code',
        'Bullet List',
        'Ordered List',
      ]);
    });

    it('lists only the enabled options', async () => {
      mountEditor({ enabledMenuOptions: ['h1', 'horizontalRule'] });
      type('/');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual(['Heading 1', 'Divider']);
    });

    it('closes on escape', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();
      pressEscape();
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showSlashMenu).toBe(false);
      expect(wrapper.vm.slashMenuPosition).toBeNull();
    });

    it('closes when the trigger text is deleted', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();
      view.dispatch(view.state.tr.delete(1, 2));
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showSlashMenu).toBe(false);
    });

    it('runs the command picked from the menu', async () => {
      mountEditor();
      type('/div');
      await wrapper.vm.$nextTick();
      await wrapper.find('button').trigger('click');

      expect(lastEmittedValue()).toContain('---');
    });

    it('anchors to the right edge in a right-to-left article', async () => {
      const computedStyle = window.getComputedStyle;
      vi.spyOn(window, 'getComputedStyle').mockImplementation(element => ({
        ...computedStyle(element),
        direction: 'rtl',
      }));
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.slashMenuPosition).toEqual({ top: 4, right: 0 });
    });
  });

  describe('slash menu keyboard', () => {
    it.each([
      ['arrow keys', 'ArrowDown', 'ArrowUp', {}],
      ['control n and p', 'n', 'p', { ctrlKey: true }],
    ])(
      'moves the highlight with the %s',
      async (_name, forward, backward, modifiers) => {
        mountEditor({ enabledMenuOptions: ['h1', 'h2', 'horizontalRule'] });
        type('/');
        await wrapper.vm.$nextTick();

        expect(highlightedLabel()).toBe('Heading 1');

        pressInEditor(forward, modifiers);
        await wrapper.vm.$nextTick();
        expect(highlightedLabel()).toBe('Heading 2');

        pressInEditor(backward, modifiers);
        await wrapper.vm.$nextTick();
        expect(highlightedLabel()).toBe('Heading 1');
      }
    );

    it('wraps the highlight around both ends', async () => {
      mountEditor({ enabledMenuOptions: ['h1', 'h2'] });
      type('/');
      await wrapper.vm.$nextTick();

      pressInEditor('ArrowUp');
      await wrapper.vm.$nextTick();
      expect(highlightedLabel()).toBe('Heading 2');

      pressInEditor('ArrowDown');
      await wrapper.vm.$nextTick();
      expect(highlightedLabel()).toBe('Heading 1');
    });

    it('runs the highlighted command on enter', async () => {
      mountEditor({ enabledMenuOptions: ['h1', 'horizontalRule'] });
      type('/');
      await wrapper.vm.$nextTick();
      pressInEditor('ArrowDown');
      await wrapper.vm.$nextTick();
      pressInEditor('Enter');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toContain('---');
      expect(wrapper.vm.showSlashMenu).toBe(false);
    });

    it.each([
      ['Enter', {}],
      ['ArrowUp', {}],
      ['ArrowDown', {}],
      ['n', { ctrlKey: true }],
      ['p', { ctrlKey: true }],
    ])('keeps %s from the editor while it is open', async (key, modifiers) => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();

      expect(swallowedByEditor(key, modifiers)).toBe(true);
    });

    it.each([
      ['ArrowDown', { shiftKey: true }],
      ['ArrowDown', { metaKey: true }],
      ['ArrowUp', { altKey: true }],
      ['Enter', { altKey: true }],
    ])('leaves modified %s to the editor', async (key, modifiers) => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();

      expect(swallowedByEditor(key, modifiers)).toBe(false);
    });

    it('still breaks the line on shift enter while it is open', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();
      pressInEditor('Enter', { shiftKey: true });
      await wrapper.vm.$nextTick();

      expect(nodeNames()).toContain('hard_break');
    });

    it.each([
      [
        'nothing matches the term',
        async () => {
          type('/zzz');
        },
      ],
      [
        'it is closed',
        async () => {
          type('/');
          await wrapper.vm.$nextTick();
          pressEscape();
        },
      ],
    ])('leaves the arrow keys to the editor when %s', async (_name, open) => {
      mountEditor();
      await open();
      await wrapper.vm.$nextTick();

      expect(swallowedByEditor('ArrowDown')).toBe(false);
    });
  });

  describe('slash menu inside a table', () => {
    const openInFirstCell = async () => {
      wrapper.vm.executeSlashCommand('insertTable');
      await wrapper.vm.$nextTick();
      placeCursor(4);
      type('/');
      await wrapper.vm.$nextTick();
    };

    it('omits the commands a cell cannot store', async () => {
      mountEditor();
      await openInFirstCell();

      expect(menuLabels()).toEqual(['Bold', 'Italic', 'Strikethrough', 'Code']);
    });

    it('still filters the remaining commands by the typed term', async () => {
      mountEditor();
      await openInFirstCell();
      type('i');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual(['Italic', 'Strikethrough']);
    });

    it('closes the menu when nothing is left to offer', async () => {
      mountEditor({ enabledMenuOptions: ['insertTable', 'horizontalRule'] });
      await openInFirstCell();

      expect(menuLabels()).toEqual([]);
    });

    it('offers the hidden commands again outside the table', async () => {
      mountEditor();
      await openInFirstCell();
      pressEscape();
      await wrapper.vm.$nextTick();

      placeCursor(view.state.doc.content.size);
      type('/div');
      await wrapper.vm.$nextTick();

      expect(menuLabels()).toEqual(['Divider']);
    });
  });

  describe('slash commands', () => {
    it.each([
      ['strong', '**Hello**'],
      ['em', '*Hello*'],
      ['strike', '~~Hello~~'],
      ['code', '`Hello`'],
    ])('applies the %s mark to the selection', async (action, markdown) => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      wrapper.vm.executeSlashCommand(action);
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toBe(markdown);
    });

    it.each([
      ['h1', '# Hello'],
      ['h2', '## Hello'],
      ['h3', '### Hello'],
      ['bulletList', '* Hello'],
      ['orderedList', '1. Hello'],
    ])('turns the block into %s', async (action, markdown) => {
      mountEditor({ modelValue: 'Hello' });
      wrapper.vm.executeSlashCommand(action);
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe(markdown);
    });

    it('inserts a table with a header row and a body row', async () => {
      mountEditor();
      wrapper.vm.executeSlashCommand('insertTable');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toContain('| --- | --- | --- |');
      expect(view.dom.querySelectorAll('th')).toHaveLength(3);
      expect(view.dom.querySelectorAll('td')).toHaveLength(3);
    });

    it('inserts a divider and keeps typing below it', async () => {
      mountEditor({ modelValue: 'Above' });
      wrapper.vm.executeSlashCommand('horizontalRule');
      await wrapper.vm.$nextTick();

      expect(view.state.selection.node).toBeUndefined();

      type('Below');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe('Above\n\n---\n\nBelow');
    });

    it('inserts a divider on its own into an empty article', async () => {
      mountEditor();
      wrapper.vm.executeSlashCommand('horizontalRule');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe('---');
    });

    it('opens the file browser for an image', () => {
      mountEditor();
      const input = wrapper.find('input[type="file"]');
      const click = vi.spyOn(input.element, 'click');
      wrapper.vm.executeSlashCommand('imageUpload');

      expect(click).toHaveBeenCalled();
    });

    it('opens the embed input for a video instead of editing the document', async () => {
      mountEditor();
      type('/');
      await wrapper.vm.$nextTick();
      wrapper.vm.executeSlashCommand('video');
      await wrapper.vm.$nextTick();

      expect(wrapper.findComponent({ name: 'VideoEmbedInput' }).exists()).toBe(
        true
      );
      expect(view.state.doc.textContent).toBe('');
    });

    it('removes the trigger text before running the command', async () => {
      mountEditor();
      type('/head');
      await wrapper.vm.$nextTick();
      wrapper.vm.executeSlashCommand('h1');
      await wrapper.vm.$nextTick();

      expect(view.state.doc.textContent).toBe('');
      expect(view.dom.querySelector('h1')).not.toBeNull();
    });

    it('ignores an unknown command', async () => {
      mountEditor({ modelValue: 'Hello' });
      wrapper.vm.executeSlashCommand('nope');
      await wrapper.vm.$nextTick();

      expect(view.state.doc.textContent).toBe('Hello');
      expect(wrapper.emitted('update:modelValue')).toBeFalsy();
    });

    it('ignores a command after the editor is torn down', () => {
      const editor = mountEditor({ modelValue: 'Hello' });
      const destroyed = view;
      editor.unmount();
      wrapper = null;

      expect(destroyed.isDestroyed).toBe(true);
      expect(() => editor.vm.executeSlashCommand('h1')).not.toThrow();
    });
  });

  describe('video embed', () => {
    const openEmbedInput = async (trigger = '/') => {
      type(trigger);
      await wrapper.vm.$nextTick();
      wrapper.vm.executeSlashCommand('video');
      await wrapper.vm.$nextTick();
    };

    it('inserts the link and closes the input on submit', async () => {
      mountEditor();
      await openEmbedInput();
      wrapper
        .findComponent({ name: 'VideoEmbedInput' })
        .vm.$emit('submit', 'https://youtu.be/dQw4w9WgXcQ');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe('<https://youtu.be/dQw4w9WgXcQ>');
      expect(wrapper.findComponent({ name: 'VideoEmbedInput' }).exists()).toBe(
        false
      );
    });

    it('leaves the document untouched on cancel', async () => {
      mountEditor({ modelValue: 'Hello' });
      await openEmbedInput(' /');
      wrapper.findComponent({ name: 'VideoEmbedInput' }).vm.$emit('cancel');
      await wrapper.vm.$nextTick();

      expect(wrapper.findComponent({ name: 'VideoEmbedInput' }).exists()).toBe(
        false
      );
      expect(view.state.doc.textContent).toBe('Hello ');
    });

    it('closes on escape from anywhere inside the popover', async () => {
      mountEditor();
      await openEmbedInput();
      // Keyboard tab switching leaves focus on the tab button, not the panel.
      await wrapper
        .findComponent({ name: 'VideoEmbedInput' })
        .find('button')
        .trigger('keydown', { key: 'Escape' });

      expect(wrapper.findComponent({ name: 'VideoEmbedInput' }).exists()).toBe(
        false
      );
    });

    it('switches tabs with the arrow keys', async () => {
      mountEditor();
      await openEmbedInput();
      const embedInput = () =>
        wrapper.findComponent({ name: 'VideoEmbedInput' });

      await embedInput()
        .find('button')
        .trigger('keydown', { key: 'ArrowRight' });
      expect(embedInput().find('input[type="file"]').exists()).toBe(true);

      await embedInput()
        .find('button')
        .trigger('keydown', { key: 'ArrowLeft' });
      expect(embedInput().find('input[type="url"]').exists()).toBe(true);
    });

    it('keeps arrow keys for the caret inside the link field', async () => {
      mountEditor();
      await openEmbedInput();
      await wrapper
        .findComponent({ name: 'VideoEmbedInput' })
        .find('input[type="url"]')
        .trigger('keydown', { key: 'ArrowRight' });

      expect(
        wrapper
          .findComponent({ name: 'VideoEmbedInput' })
          .find('input[type="url"]')
          .exists()
      ).toBe(true);
    });

    it('rejects a non-video file dropped on the upload tab', async () => {
      mountEditor();
      await openEmbedInput();
      const embedInput = () =>
        wrapper.findComponent({ name: 'VideoEmbedInput' });
      await embedInput()
        .find('button')
        .trigger('keydown', { key: 'ArrowRight' });

      await embedInput()
        .find('[class*="border-dashed"]')
        .trigger('drop', { dataTransfer: { files: [fileOfSize(1)] } });

      expect(embedInput().exists()).toBe(true);
      expect(embedInput().text()).toContain('Only MP4');
      expect(attachImage).not.toHaveBeenCalled();
    });

    it('uploads an mp4 dropped on the upload tab', async () => {
      mountEditor();
      await openEmbedInput();
      const embedInput = () =>
        wrapper.findComponent({ name: 'VideoEmbedInput' });
      await embedInput()
        .find('button')
        .trigger('keydown', { key: 'ArrowRight' });

      await embedInput()
        .find('[class*="border-dashed"]')
        .trigger('drop', {
          dataTransfer: {
            files: [new File(['x'], 'clip.mp4', { type: 'video/mp4' })],
          },
        });
      await flushPromises();

      expect(embedInput().exists()).toBe(false);
      expect(attachImage).toHaveBeenCalled();
    });
  });

  describe('image upload', () => {
    it('uploads a selected file and inserts it', async () => {
      mountEditor();
      await selectFile(fileOfSize(1));

      expect(attachImage).toHaveBeenCalledWith(
        expect.objectContaining({ portalSlug: 'handbook' })
      );
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');
    });

    it('rejects a file over the size limit', async () => {
      mountEditor();
      await selectFile(fileOfSize(5));

      expect(attachImage).not.toHaveBeenCalled();
      expect(alerts).toHaveLength(1);
    });

    it('rejects an image type the picker does not advertise', async () => {
      mountEditor();
      await selectFile(
        new File(['x'], 'diagram.svg', { type: 'image/svg+xml' })
      );

      expect(attachImage).not.toHaveBeenCalled();
      expect(alerts).toHaveLength(1);
    });

    it('keeps the preview with retry and remove controls when the upload fails', async () => {
      mountEditor();
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(fileOfSize(1));

      expect(alerts).toHaveLength(0);
      const overlay = view.dom.querySelector('.pm-upload-overlay');
      expect(overlay.dataset.state).toBe('error');
      const buttons = [...overlay.querySelectorAll('.pm-upload-action')];
      expect(buttons.map(button => button.getAttribute('aria-label'))).toEqual([
        'Retry',
        'Remove',
      ]);
      // The half-uploaded preview must never reach the serialized document.
      expect(lastEmittedValue() || '').not.toContain('blob:');
    });

    it('inserts the image where the files arrived even if the caret moves while decoding', async () => {
      mountEditor({ modelValue: 'Hello world' });
      const decodes = [];
      // eslint-disable-next-line func-names
      window.Image.prototype.decode = function () {
        return new Promise(resolve => {
          decodes.push(resolve);
        });
      };
      try {
        placeCursor(6);
        await selectFile(fileOfSize(1));
        // The caret moves away while the preview is still decoding.
        placeCursor(1);
        decodes.shift()();
        await flushPromises();
        // Release the post-upload preload of the final URL too.
        decodes.shift()?.();
        await flushPromises();

        const doc = view.state.doc;
        expect(doc.child(0).textContent).toBe('Hello');
        expect(doc.child(1).firstChild.type.name).toBe('image');
        expect(doc.child(2).textContent).toBe(' world');
      } finally {
        decodes.forEach(resolve => resolve());
        delete window.Image.prototype.decode;
      }
    });

    it('reports a pending upload while a picked image is still decoding', async () => {
      mountEditor();
      const decodes = [];
      // eslint-disable-next-line func-names
      window.Image.prototype.decode = function () {
        return new Promise(resolve => {
          decodes.push(resolve);
        });
      };
      try {
        await selectFile(fileOfSize(1));
        // No preview node exists yet — the insert anchor keeps the guard on.
        expect(view.dom.querySelector('img')).toBeNull();
        expect(wrapper.vm.hasPendingUploads()).toBe(true);

        decodes.shift()();
        await flushPromises();
        // Release the post-upload preload of the final URL too.
        decodes.shift()?.();
        await flushPromises();

        expect(wrapper.vm.hasPendingUploads()).toBe(false);
      } finally {
        decodes.forEach(resolve => resolve());
        delete window.Image.prototype.decode;
      }
    });

    it('retries a failed upload in place', async () => {
      mountEditor();
      attachImage.mockRejectedValueOnce(new Error('nope'));
      await selectFile(fileOfSize(1));

      view.dom.querySelector('.pm-upload-overlay .pm-upload-action').click();
      await flushPromises();

      expect(attachImage).toHaveBeenCalledTimes(2);
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');
    });

    it('removes a failed upload on request', async () => {
      mountEditor();
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(fileOfSize(1));

      const buttons = view.dom.querySelectorAll(
        '.pm-upload-overlay .pm-upload-action'
      );
      buttons[1].click();
      await flushPromises();

      expect(view.dom.querySelector('.pm-image-wrapper')).toBeNull();
    });

    it('uploads an image pasted as a file', async () => {
      mountEditor();
      const paste = new Event('paste', { bubbles: true, cancelable: true });
      paste.clipboardData = { files: [fileOfSize(1)] };
      view.dom.dispatchEvent(paste);
      await flushPromises();

      expect(attachImage).toHaveBeenCalled();
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');
    });

    it('resolves a pasted image url through the upload action', async () => {
      mountEditor();
      const url = await wrapper.vm.handleImageUpload('https://web.test/a.png');

      expect(uploadExternalImage).toHaveBeenCalledWith({
        portalSlug: 'handbook',
        url: 'https://web.test/a.png',
      });
      expect(url).toBe('https://cdn.test/remote.png');
    });

    it('propagates a failed paste mirror to the plugin instead of alerting', async () => {
      mountEditor();
      uploadExternalImage.mockRejectedValue(new Error('nope'));

      await expect(
        wrapper.vm.handleImageUpload('https://web.test/a.png')
      ).rejects.toThrow('nope');
      expect(alerts).toHaveLength(0);
    });

    it('leaves pasted same-origin images alone instead of re-mirroring them', async () => {
      mountEditor();
      const ownUrl = `${window.location.origin}/rails/active_storage/blobs/abc/pic.png`;
      view.pasteHTML(`<p><img src="${ownUrl}"></p>`);
      await new Promise(resolve => {
        setTimeout(resolve);
      });
      await flushPromises();

      expect(uploadExternalImage).not.toHaveBeenCalled();
      expect(
        view.dom.querySelector('.pm-image-wrapper img').getAttribute('src')
      ).toBe(ownUrl);
      expect(view.dom.querySelector('.pm-upload-overlay')).toBeNull();
    });

    it('mirrors a pasted external image and swaps to the uploaded url', async () => {
      mountEditor();
      view.pasteHTML('<p><img src="https://web.test/a.png"></p>');
      // The paste plugin defers its work with setTimeout(0).
      await new Promise(resolve => {
        setTimeout(resolve);
      });
      await flushPromises();

      expect(uploadExternalImage).toHaveBeenCalledWith(
        expect.objectContaining({
          portalSlug: 'handbook',
          url: 'https://web.test/a.png',
        })
      );
      expect(lastEmittedValue()).toContain('![](https://cdn.test/remote.png)');
    });

    it('keeps a pasted external image with retry controls when the mirror fails', async () => {
      mountEditor();
      uploadExternalImage.mockRejectedValue(new Error('nope'));
      view.pasteHTML('<p><img src="https://web.test/a.png"></p>');
      await new Promise(resolve => {
        setTimeout(resolve);
      });
      await flushPromises();

      const img = view.dom.querySelector('.pm-image-wrapper img');
      expect(img.getAttribute('src')).toBe('https://web.test/a.png');
      expect(view.dom.querySelector('.pm-upload-overlay').dataset.state).toBe(
        'error'
      );
    });

    it('aborts the request and drops the preview when an upload is cancelled', async () => {
      mountEditor();
      attachImage.mockImplementation(pendingUpload);
      await selectFile(fileOfSize(1));

      expect(view.dom.querySelector('.pm-image-wrapper')).not.toBeNull();
      view.dom.querySelector('.pm-upload-overlay .pm-upload-cancel').click();
      await flushPromises();

      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(true);
      expect(view.dom.querySelector('.pm-image-wrapper')).toBeNull();
    });

    it('aborts the request when the uploading image is deleted from the doc', async () => {
      mountEditor();
      attachImage.mockImplementation(pendingUpload);
      await selectFile(fileOfSize(1));

      view.dispatch(view.state.tr.delete(0, view.state.doc.content.size));
      await flushPromises();

      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(true);
    });

    it('hides the video source line and removes the embed from its button', async () => {
      mountEditor({
        modelValue: '[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });

      expect(view.dom.querySelector('.cw-embed-source-hidden')).not.toBeNull();
      view.dom.querySelector('.cw-embed-remove').click();

      expect(view.state.doc.textContent).toBe('after');
      expect(view.dom.querySelector('.cw-embed-source-hidden')).toBeNull();
    });

    it('selects the whole document with Cmd+A outside a table', async () => {
      mountEditor({
        modelValue: 'before\n\n[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });
      placeCursor(2);

      expect(swallowedByEditor('a', { ctrlKey: true })).toBe(true);
      expect(view.state.selection.toJSON().type).toBe('all');
    });

    it('steps onto a video with arrow keys instead of skipping past it', async () => {
      mountEditor({
        modelValue: 'before\n\n[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });
      placeCursor(view.state.doc.child(0).nodeSize - 1);

      expect(swallowedByEditor('ArrowRight')).toBe(true);
      expect(view.state.selection.node?.textContent).toBe('clip.mp4');

      expect(swallowedByEditor('ArrowRight')).toBe(true);
      expect(view.state.selection.$from.parent.textContent).toBe('after');
    });

    it('creates a line above a leading video and lands the caret in it', async () => {
      mountEditor({
        modelValue: '[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });
      placeCursor(view.state.doc.child(0).nodeSize + 1);

      expect(swallowedByEditor('ArrowLeft')).toBe(true);
      expect(view.state.selection.node?.textContent).toBe('clip.mp4');

      expect(swallowedByEditor('ArrowLeft')).toBe(true);
      expect(view.state.doc.child(0).textContent).toBe('');
      expect(view.state.selection.from).toBe(1);
    });

    it('starts a new line below a selected video on Enter', async () => {
      mountEditor({
        modelValue:
          '[a.mp4](https://cdn.test/a.mp4)\n\n[b.mp4](https://cdn.test/b.mp4)\n\nafter',
      });
      view.dispatch(
        view.state.tr.setSelection(
          Selection.fromJSON(view.state.doc, { type: 'node', anchor: 0 })
        )
      );

      expect(swallowedByEditor('Enter')).toBe(true);
      expect(view.state.doc.child(1).type.name).toBe('paragraph');
      expect(view.state.doc.child(1).textContent).toBe('');
      expect(view.state.selection.from).toBe(
        view.state.doc.child(0).nodeSize + 1
      );
    });

    it('keeps a paragraph after a trailing video so there is a place to type', async () => {
      mountEditor({
        modelValue: 'before\n\n[clip.mp4](https://cdn.test/clip.mp4)',
      });
      placeCursor(2);
      type('x');

      const last = view.state.doc.lastChild;
      expect(last.type.name).toBe('paragraph');
      expect(last.textContent).toBe('');
    });

    it('steps a caret stuck in the hidden source line out with an arrow key', async () => {
      mountEditor({
        modelValue: 'before\n\n[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });
      placeCursor(view.state.doc.child(0).nodeSize + 1);

      expect(swallowedByEditor('ArrowRight')).toBe(true);
      expect(view.state.selection.$from.parent.textContent).toBe('after');
    });

    it('removes the whole video embed on backspace after it', async () => {
      mountEditor({
        modelValue: '[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });

      placeCursor(11);
      expect(swallowedByEditor('Backspace')).toBe(true);
      expect(view.state.doc.textContent).toBe('after');
    });

    it('reloads a video that failed to load once the connection returns', async () => {
      mountEditor({
        modelValue: '[clip.mp4](https://cdn.test/clip.mp4)\n\nafter',
      });
      const media = view.dom.querySelector('.cw-embed-preview video');
      media.load = vi.fn();

      // Online again without a prior failure: nothing to reload.
      window.dispatchEvent(new Event('online'));
      expect(media.load).not.toHaveBeenCalled();

      // All sources failed: the element parks in NETWORK_NO_SOURCE.
      Object.defineProperty(media, 'networkState', {
        value: 3,
        configurable: true,
      });
      window.dispatchEvent(new Event('online'));
      expect(media.load).toHaveBeenCalledTimes(1);

      // The plugin view removes its listener when the editor is destroyed.
      wrapper.unmount();
      wrapper = null;
      window.dispatchEvent(new Event('online'));
      expect(media.load).toHaveBeenCalledTimes(1);
    });

    it('keeps an uploading video card when an image is pasted at the same spot', async () => {
      mountEditor();
      attachImage.mockImplementationOnce(pendingUpload);
      const video = new File(['x'], 'clip.mp4', { type: 'video/mp4' });
      await selectFile(video);
      expect(view.dom.querySelector('.pm-upload-card')).not.toBeNull();

      await selectFile(fileOfSize(1));

      expect(view.dom.querySelector('.pm-upload-card')).not.toBeNull();
      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(false);
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');
    });

    it('cancels the uploading card on backspace at its position', async () => {
      mountEditor();
      attachImage.mockImplementation(pendingUpload);
      const file = new File(['x'], 'clip.mp4', { type: 'video/mp4' });
      await selectFile(file);

      expect(view.dom.querySelector('.pm-upload-card')).not.toBeNull();
      expect(swallowedByEditor('Backspace')).toBe(true);
      await flushPromises();

      expect(view.dom.querySelector('.pm-upload-card')).toBeNull();
      expect(attachImage.mock.calls[0][0].signal.aborted).toBe(true);
    });

    it('uploads a video through a progress card and inserts its link', async () => {
      mountEditor();
      attachImage.mockResolvedValue('https://cdn.test/clip.mp4');
      const file = new File(['x'], 'clip.mp4', { type: 'video/mp4' });

      await selectFile(file);

      expect(view.dom.querySelector('.pm-upload-card')).toBeNull();
      // The file name links to the upload; embed previews match on the href,
      // so the video player still renders from this shape.
      expect(lastEmittedValue()).toContain(
        '[clip.mp4](https://cdn.test/clip.mp4)'
      );
    });

    it('drops a decoded image insert when the document was reset meanwhile', async () => {
      mountEditor({ modelValue: 'Hello' });
      const decodes = [];
      // eslint-disable-next-line func-names
      window.Image.prototype.decode = function () {
        return new Promise(resolve => {
          decodes.push(resolve);
        });
      };
      try {
        await selectFile(fileOfSize(1));
        // The preview is still decoding: nothing is in the doc yet, so an
        // external reset (e.g. discard draft) is accepted.
        await wrapper.setProps({ modelValue: 'reset content' });
        decodes.shift()();
        await flushPromises();

        expect(view.state.doc.textContent).toBe('reset content');
        expect(nodeNames()).not.toContain('image');
        expect(attachImage).not.toHaveBeenCalled();
      } finally {
        decodes.forEach(resolve => resolve());
        delete window.Image.prototype.decode;
      }
    });

    it('undo after cancelling an upload does not revive the preview', async () => {
      mountEditor();
      attachImage.mockImplementation(pendingUpload);
      await selectFile(fileOfSize(1));
      view.dom.querySelector('.pm-upload-overlay .pm-upload-cancel').click();
      await flushPromises();
      expect(view.dom.querySelector('.pm-image-wrapper')).toBeNull();

      pressInEditor('z', { ctrlKey: true });
      await wrapper.vm.$nextTick();

      expect(view.dom.querySelector('.pm-image-wrapper')).toBeNull();
      expect(nodeNames()).not.toContain('image');
    });

    it('undo after a completed upload removes the image instead of reviving the preview', async () => {
      mountEditor();
      await selectFile(fileOfSize(1));
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');

      pressInEditor('z', { ctrlKey: true });
      await wrapper.vm.$nextTick();
      // The whole image goes, not just the swap — a surviving blob preview
      // would display in the editor while vanishing from the saved markdown.
      expect(view.dom.querySelector('.pm-image-wrapper')).toBeNull();
      expect(lastEmittedValue() || '').not.toContain('photo.png');

      pressInEditor('z', { ctrlKey: true, shiftKey: true });
      await wrapper.vm.$nextTick();
      expect(lastEmittedValue()).toContain('![](https://cdn.test/photo.png)');
    });

    it('cancelling a duplicate paste mirror keeps every matching image', async () => {
      mountEditor({ modelValue: '![](https://web.test/a.png)' });
      uploadExternalImage.mockImplementation(pendingUpload);
      view.pasteHTML('<p><img src="https://web.test/a.png"></p>');
      await new Promise(resolve => {
        setTimeout(resolve);
      });
      await flushPromises();
      expect(view.dom.querySelectorAll('.pm-image-wrapper')).toHaveLength(2);

      view.dom.querySelector('.pm-upload-overlay .pm-upload-cancel').click();
      await flushPromises();

      expect(view.dom.querySelectorAll('.pm-image-wrapper')).toHaveLength(2);
      expect(view.dom.querySelector('.pm-image-uploading')).toBeNull();
      expect(lastEmittedValue()).toContain('![](https://web.test/a.png)');
    });

    it('resizes the existing video preview when the sizing param changes', async () => {
      mountEditor({
        modelValue:
          '[clip.mp4](https://cdn.test/clip.mp4?cw_video_width=300px)\n\nafter',
      });
      const preview = view.dom.querySelector('.cw-embed-preview');
      expect(preview.style.width).toBe('300px');

      // Rewrite the hidden source link the way a resize commit (or its undo)
      // does — the widget survives, so its width must sync in place.
      const linkType = view.state.schema.marks.link;
      const end = 1 + view.state.doc.child(0).content.size;
      const tr = view.state.tr;
      tr.removeMark(1, end, linkType);
      tr.addMark(
        1,
        end,
        linkType.create({
          href: 'https://cdn.test/clip.mp4?cw_video_width=500px',
        })
      );
      view.dispatch(tr);

      expect(view.dom.querySelector('.cw-embed-preview')).toBe(preview);
      expect(preview.style.width).toBe('500px');
    });

    it('inserts videos in the order picked even when uploads finish out of order', async () => {
      mountEditor();
      const settle = new Map();
      attachImage.mockImplementation(
        ({ file }) =>
          new Promise(resolve => {
            settle.set(file.name, resolve);
          })
      );
      const first = new File(['x'], 'first.mp4', { type: 'video/mp4' });
      const second = new File(['x'], 'second.mp4', { type: 'video/mp4' });
      const input = wrapper.find('input[type="file"]');
      Object.defineProperty(input.element, 'files', {
        value: [first, second],
        configurable: true,
      });
      await input.trigger('change');
      await flushPromises();

      settle.get('second.mp4')('https://cdn.test/second.mp4');
      await flushPromises();
      // The finished second file waits for the first pick to land.
      expect(lastEmittedValue() || '').not.toContain('second.mp4');

      settle.get('first.mp4')('https://cdn.test/first.mp4');
      await flushPromises();

      const content = lastEmittedValue();
      expect(content).toContain('[first.mp4](https://cdn.test/first.mp4)');
      expect(content).toContain('[second.mp4](https://cdn.test/second.mp4)');
      expect(content.indexOf('first.mp4')).toBeLessThan(
        content.indexOf('second.mp4')
      );
    });
  });

  describe('editor events', () => {
    it('forwards focus, blur, keyup and keydown', async () => {
      mountEditor({ autofocus: false });
      view.dom.dispatchEvent(new FocusEvent('focus'));
      view.dom.dispatchEvent(new FocusEvent('blur'));
      view.dom.dispatchEvent(new KeyboardEvent('keyup', { key: 'a' }));
      view.dom.dispatchEvent(new KeyboardEvent('keydown', { key: 'a' }));
      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('focus')).toHaveLength(1);
      expect(wrapper.emitted('blur')).toHaveLength(1);
      expect(wrapper.emitted('keyup')).toHaveLength(1);
      expect(wrapper.emitted('keydown')).toHaveLength(1);
    });

    it('flags a text range and positions the floating menubar', async () => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      await wrapper.vm.$nextTick();

      const editor = wrapper.vm.$refs.editor;
      expect(editor.classList.contains('has-selection')).toBe(true);
      expect(editor.style.getPropertyValue('--selection-top')).toBe('10px');
      expect(editor.style.getPropertyValue('--selection-left')).toBe('0px');
    });

    it('clears the selection flag on blur', async () => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      await wrapper.vm.$nextTick();
      view.dom.dispatchEvent(new FocusEvent('blur'));
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.$refs.editor.classList.contains('has-selection')).toBe(
        false
      );
    });

    it('collapses the selection on escape when the menu is closed', async () => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      pressEscape();
      await wrapper.vm.$nextTick();

      expect(view.state.selection.empty).toBe(true);
    });
  });

  describe('floating toolbar', () => {
    it('renders a button for every enabled option that has one', () => {
      mountEditor();

      // `video` and `horizontalRule` are slash-only keys; buildMenuOptions drops
      // what it does not recognise, so they must not add a toolbar button.
      expect(toolbarItems().map(item => item.title)).toEqual([
        'Toggle strong style',
        'Toggle emphasis',
        'Toggle strikethrough',
        'Add or remove link',
        'Undo last change',
        'Redo last undone change',
        'Wrap in bullet list',
        'Wrap in ordered list',
        'Heading 1',
        'Heading 2',
        'Heading 3',
        'Upload image',
        'Toggle code font',
        'Insert table',
      ]);
    });

    it('honours a narrower set of enabled options', () => {
      mountEditor({ enabledMenuOptions: ['strong', 'undo'] });

      expect(toolbarItems().map(item => item.title)).toEqual([
        'Toggle strong style',
        'Undo last change',
      ]);
    });

    it.each([
      ['Toggle strong style', '**Hello**'],
      ['Toggle emphasis', '*Hello*'],
      ['Toggle strikethrough', '~~Hello~~'],
      ['Toggle code font', '`Hello`'],
    ])('applies %s to the selection', async (title, markdown) => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      await wrapper.vm.$nextTick();
      clickToolbar(title);
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toBe(markdown);
    });

    it.each([
      ['Wrap in bullet list', '* Hello'],
      ['Wrap in ordered list', '1. Hello'],
      ['Heading 1', '# Hello'],
      ['Heading 2', '## Hello'],
      ['Heading 3', '### Hello'],
    ])('applies %s to the block', async (title, markdown) => {
      mountEditor({ modelValue: 'Hello' });
      clickToolbar(title);
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe(markdown);
    });

    it('inserts a table', async () => {
      mountEditor();
      clickToolbar('Insert table');
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toContain('| --- | --- | --- |');
    });

    it('opens the file browser', () => {
      mountEditor();
      const click = vi.spyOn(
        wrapper.find('input[type="file"]').element,
        'click'
      );
      clickToolbar('Upload image');

      expect(click).toHaveBeenCalled();
    });

    it('disables the link button until text is selected', async () => {
      mountEditor({ modelValue: 'Hello' });

      expect(toolbarItem('Add or remove link').disabled).toBe(true);

      selectAll();
      await wrapper.vm.$nextTick();

      expect(toolbarItem('Add or remove link').disabled).toBe(false);
    });

    it('disables undo and redo until there is history', async () => {
      mountEditor({ modelValue: 'Hello' });

      expect(toolbarItem('Undo last change').disabled).toBe(true);
      expect(toolbarItem('Redo last undone change').disabled).toBe(true);

      type(' edited');
      await wrapper.vm.$nextTick();

      expect(toolbarItem('Undo last change').disabled).toBe(false);
    });

    it('hides block level buttons while the caret is inside a table', async () => {
      mountEditor();
      wrapper.vm.executeSlashCommand('insertTable');
      await wrapper.vm.$nextTick();
      placeCursor(4);
      await wrapper.vm.$nextTick();

      expect(
        toolbarItems()
          .filter(item => item.hidden)
          .map(i => i.title)
      ).toEqual([
        'Toggle strikethrough',
        'Wrap in bullet list',
        'Wrap in ordered list',
        'Heading 1',
        'Heading 2',
        'Heading 3',
        'Upload image',
        'Toggle code font',
        'Insert table',
      ]);
      expect(toolbarItem('Toggle strong style').hidden).toBe(false);
    });
  });

  describe('markdown shortcuts', () => {
    it.each([
      ['# Title', '# Title'],
      ['## Title', '## Title'],
      ['### Title', '### Title'],
      ['- item', '* item'],
      ['1. item', '1. item'],
      ['> quote', '> quote'],
      ['--- ', '---'],
    ])('turns %j into a block while typing', async (typed, markdown) => {
      mountEditor();
      typeWithRules(typed);
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue().trim()).toBe(markdown);
    });

    it('opens a code block on a triple backtick', async () => {
      mountEditor();
      typeWithRules('```');
      await wrapper.vm.$nextTick();

      expect(view.state.doc.firstChild.type.name).toBe('code_block');
    });

    it.each([
      ['**bold**', 'strong'],
      ['*italic*', 'em'],
      ['~~struck~~', 'strike'],
      ['`code`', 'code'],
    ])('turns %j into the %s mark while typing', async (typed, mark) => {
      mountEditor();
      typeWithRules(typed);
      await wrapper.vm.$nextTick();

      expect(markNames()).toEqual([mark]);
    });
  });

  describe('keyboard shortcuts', () => {
    it.each([
      ['b', 'strong'],
      ['i', 'em'],
    ])('applies the %s shortcut to the selection', async (key, mark) => {
      mountEditor({ modelValue: 'Hello' });
      selectAll();
      pressInEditor(key, { ctrlKey: true });
      await wrapper.vm.$nextTick();

      expect(markNames()).toEqual([mark]);
    });

    it('undoes and redoes an edit', async () => {
      mountEditor({ modelValue: 'Hello' });
      type(' world');
      await wrapper.vm.$nextTick();

      pressInEditor('z', { ctrlKey: true });
      await wrapper.vm.$nextTick();
      expect(lastEmittedValue()).toBe('Hello');

      pressInEditor('z', { ctrlKey: true, shiftKey: true });
      await wrapper.vm.$nextTick();
      expect(lastEmittedValue()).toBe('Hello world');
    });

    it('undoes an inserted divider in a single step', async () => {
      mountEditor({ modelValue: 'Above' });
      wrapper.vm.executeSlashCommand('horizontalRule');
      await wrapper.vm.$nextTick();
      expect(lastEmittedValue()).toContain('---');

      pressInEditor('z', { ctrlKey: true });
      await wrapper.vm.$nextTick();

      expect(lastEmittedValue()).toBe('Above');
    });
  });

  describe('markdown round trip', () => {
    it.each([
      ['heading', '# Title'],
      ['inline marks', '**bold** and *italic* and ~~struck~~ and `code`'],
      ['bullet list', '* one\n\n* two'],
      ['ordered list', '1. one\n\n2. two'],
      ['blockquote', '> quote'],
      ['code block', '```\ncode\n```'],
      ['divider', 'Above\n\n---\n\nBelow'],
      ['image', '![](https://cdn.test/photo.png)'],
      ['link', '[label](https://example.com)'],
      ['table', '|     |     |\n| --- | --- |\n|     |     |'],
    ])('serializes %s back to the same markdown', (_label, markdown) => {
      mountEditor({ modelValue: markdown });

      expect(wrapper.vm.contentFromEditor().trim()).toBe(markdown);
    });
  });
});
