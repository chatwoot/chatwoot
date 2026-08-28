import { flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createStore } from 'vuex';
import { Selection } from '@chatwoot/prosemirror-schema';
import { withFullI18n } from 'test-i18n';
import { emitter } from 'shared/helpers/mitt';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
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

const attachImage = vi.fn();
const uploadExternalImage = vi.fn();

const store = createStore({
  actions: {
    'articles/attachImage': (_, payload) => attachImage(payload),
    'articles/uploadExternalImage': (_, payload) =>
      uploadExternalImage(payload),
  },
  getters: { getUISettings: () => ({}) },
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

const selectFile = async file => {
  const input = wrapper.find('input[type="file"]');
  Object.defineProperty(input.element, 'files', { value: [file] });
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

    it('alerts when the upload fails', async () => {
      mountEditor();
      attachImage.mockRejectedValue(new Error('nope'));
      await selectFile(fileOfSize(1));

      expect(alerts).toHaveLength(1);
      expect(lastEmittedValue()).toBeNull();
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

    it('alerts and returns an empty url when the paste upload fails', async () => {
      mountEditor();
      uploadExternalImage.mockRejectedValue(new Error('nope'));
      const url = await wrapper.vm.handleImageUpload('https://web.test/a.png');

      expect(url).toBe('');
      expect(alerts).toHaveLength(1);
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
