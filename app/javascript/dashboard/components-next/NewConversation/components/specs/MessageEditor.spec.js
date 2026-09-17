import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import MessageEditor from '../MessageEditor.vue';

const i18n = withFullI18n();

const EditorStub = {
  props: ['placeholder', 'modelValue'],
  template: '<div class="editor-stub" :data-placeholder="placeholder" />',
};

const mountEditor = (props = {}) =>
  mount(MessageEditor, {
    props: { modelValue: '', ...props },
    global: {
      stubs: { Editor: EditorStub, CopilotEditorSection: true },
    },
  });

describe('MessageEditor', () => {
  it('uses the compose placeholder and full height by default', () => {
    const editor = mountEditor().find('.editor-stub');

    expect(editor.attributes('data-placeholder')).toBe(
      i18n.global.t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
    );
    expect(editor.classes()).toContain(
      '[&_.ProseMirror-woot-style]:!min-h-[12rem]'
    );
  });

  it('accepts a custom placeholder and a compact height', () => {
    const editor = mountEditor({
      placeholder: 'Add a message',
      compact: true,
    }).find('.editor-stub');

    expect(editor.attributes('data-placeholder')).toBe('Add a message');
    expect(editor.classes()).toContain(
      '[&_.ProseMirror-woot-style]:!min-h-[4rem]'
    );
    expect(editor.classes()).not.toContain(
      '[&_.ProseMirror-woot-style]:!min-h-[12rem]'
    );
  });
});
