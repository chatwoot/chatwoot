<template>
  <div>
    <div class="editor-root editor--article">
      <div ref="editor" />
    </div>
  </div>
</template>

<script>
import {
  fullSchema,
  wootArticleWriterSetup,
  EditorView,
  ArticleMarkdownSerializer,
  ArticleMarkdownTransformer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';

import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

const createState = (content, placeholder, plugins = []) => {
  return EditorState.create({
    doc: new ArticleMarkdownTransformer(fullSchema).parse(content),
    plugins: wootArticleWriterSetup({
      schema: fullSchema,
      placeholder,
      plugins,
    }),
  });
};

export default {
  mixins: [eventListenerMixins, uiSettingsMixin],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
  },
  data() {
    return {
      editorView: null,
      state: undefined,
      plugins: [],
    };
  },
  computed: {
    contentFromEditor() {
      if (this.editorView) {
        return ArticleMarkdownSerializer.serialize(this.editorView.state.doc);
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

    onKeyup() {
      this.$emit('keyup');
    },
    onKeydown() {
      this.$emit('keydown');
    },
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
@import '~@chatwoot/prosemirror-schema/src/styles/article.scss';

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
</style>
