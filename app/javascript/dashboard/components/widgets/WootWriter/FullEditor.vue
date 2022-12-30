<template>
  <div>
    <div class="editor-root editor--article">
      <div ref="editor" />
    </div>
  </div>
</template>

<script>
import {
  schema,
  // articleSchema,
  wootArticleWriterSetup,
  EditorView,
  defaultMarkdownParser,
  defaultMarkdownSerializer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';

// import { buildFullEditorMenuItems } from './src/menu';

import '@chatwoot/prosemirror-schema/src/styles/article.scss';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

const createState = (content, placeholder, plugins = []) => {
  return EditorState.create({
    doc: defaultMarkdownParser.parse(content),
    plugins: wootArticleWriterSetup({
      schema,
      placeholder,
      plugins,
    }),
  });
};

export default {
  name: 'WootMessageEditor',
  mixins: [eventListenerMixins, uiSettingsMixin],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    isPrivate: { type: Boolean, default: false },
  },
  data() {
    return {
      showCannedMenu: false,
      mentionSearchKey: '',
      cannedSearchTerm: '',
      editorView: null,
      range: null,
      state: undefined,
      plugins: [],
    };
  },
  computed: {
    contentFromEditor() {
      if (this.editorView) {
        return defaultMarkdownSerializer.serialize(this.editorView.state.doc);
      }
      return '';
    },
  },
  watch: {
    value(newValue = '') {
      if (newValue !== this.contentFromEditor) {
        this.reloadState();
      }
    },
    editorId() {
      this.reloadState();
    },
  },
  created() {
    this.state = createState(this.value, this.placeholder, this.plugins);
  },
  mounted() {
    this.createEditorView();

    this.editorView.updateState(this.state);
    this.focusEditorInputField();
  },
  methods: {
    reloadState() {
      this.state = createState(this.value, this.placeholder, this.plugins);
      this.editorView.updateState(this.state);
      this.focusEditorInputField();
    },
    createEditorView() {
      this.editorView = new EditorView(this.$refs.editor, {
        state: this.state,
        dispatchTransaction: tx => {
          this.state = this.state.apply(tx);
          this.emitOnChange();
        },
        handleDOMEvents: {
          keyup: () => {
            this.onKeyup();
          },
          keydown: (view, event) => {
            this.onKeydown(event);
          },
          focus: () => {
            this.onFocus();
          },
          blur: () => {
            this.onBlur();
          },
        },
      });
    },

    handleKeyEvents() {},
    focusEditorInputField() {
      const { tr } = this.editorView.state;
      const selection = Selection.atEnd(tr.doc);

      this.editorView.dispatch(tr.setSelection(selection));
      this.editorView.focus();
    },

    emitOnChange() {
      this.editorView.updateState(this.state);

      this.$emit('input', this.contentFromEditor);
    },

    onKeyup() {},
    onKeydown() {},
    onBlur() {
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
  },
};
</script>

<style lang="scss">
.ProseMirror-menubar-wrapper {
  display: flex;
  flex-direction: column;

  > .ProseMirror {
    padding: 0;
    word-break: break-word;
  }
}

.editor-root {
  width: 100%;
}

.ProseMirror-woot-style {
  min-height: 8rem;
  max-height: 12rem;
  overflow: auto;
}

.ProseMirror-prompt {
  z-index: var(--z-index-highest);
  background: var(--white);
  box-shadow: var(--shadow-large);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  min-width: 40rem;
}

.is-private {
  .prosemirror-mention-node {
    font-weight: var(--font-weight-medium);
    background: var(--s-50);
    color: var(--s-900);
    padding: 0 var(--space-smaller);
  }
}

.editor-wrap {
  margin-bottom: var(--space-normal);
}

.message-editor {
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  padding: 0 var(--space-slab);
  margin-bottom: 0;
}

.editor_warning {
  border: 1px solid var(--r-400);
}

.editor-warning__message {
  color: var(--r-400);
  font-weight: var(--font-weight-normal);
  padding: var(--space-smaller) 0 0 0;
}
</style>
