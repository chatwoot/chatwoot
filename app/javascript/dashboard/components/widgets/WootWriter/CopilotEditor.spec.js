import { mount } from '@vue/test-utils';
import { afterEach, describe, expect, it, vi } from 'vitest';
import CopilotEditor from './CopilotEditor.vue';

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

let wrapper = null;

afterEach(() => {
  wrapper?.unmount();
  wrapper = null;
});

const mountEditor = () => {
  wrapper = mount(CopilotEditor, {
    props: { modelValue: 'make it shorter', autofocus: false },
    attachTo: document.body,
  });
};

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

describe('CopilotEditor', () => {
  it('sends on a normal Enter', () => {
    mountEditor();
    editorKeydown({});
    expect(wrapper.emitted('send')).toHaveLength(1);
  });

  it('does not send while an IME composition is active', () => {
    mountEditor();
    editorKeydown({ isComposing: true });
    expect(wrapper.emitted('send')).toBeUndefined();
  });

  it('does not send when WebKit reports the composition only through keyCode 229', () => {
    mountEditor();
    editorKeydown({ keyCode: 229 });
    expect(wrapper.emitted('send')).toBeUndefined();
  });
});
