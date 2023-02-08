<template>
  <div>
    <div class="editor-root editor--article">
      <input ref="imageUploadInput" type="file" hidden @change="onFileChange" />
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

const createState = (
  content,
  placeholder,
  plugins = [],
  onImageUpload = () => {}
) => {
  return EditorState.create({
    doc: new ArticleMarkdownTransformer(fullSchema).parse(content),
    plugins: wootArticleWriterSetup({
      schema: fullSchema,
      placeholder,
      plugins,
      onImageUpload,
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
    this.state = createState(
      this.value,
      this.placeholder,
      this.plugins,
      this.openFileBrowser
    );
  },
  mounted() {
    this.createEditorView();

    this.editorView.updateState(this.state);
    this.focusEditorInputField();
  },
  methods: {
    openFileBrowser() {
      this.$refs.imageUploadInput.click();
    },
    onFileChange() {
      const file = this.$refs.imageUploadInput.files[0];
      this.uploadImageToStorage(file);

      this.$refs.imageUploadInput.value = '';
    },
    async uploadImageToStorage(file) {
      try {
        const fileUrl = await this.$store.dispatch('articles/attachImage', {
          portalSlug: this.$route.params.portalSlug,
          file,
        });

        if (fileUrl) {
          this.onImageUploadStart(fileUrl);
        }
        // this.showAlert(this.$t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        // eslint-disable-next-line no-console
        console.log(error);
        // this.showAlert(this.$t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
      }
    },
    onImageUploadStart(fileUrl) {
      const { selection } = this.editorView.state;
      const from = selection.from;
      const node = this.editorView.state.schema.nodes.image.create({
        src: fileUrl,
      });

      if (node) {
        const tr = this.editorView.state.tr
          .replaceSelectionWith(node)
          .insert(from, this.editorView.state.schema.node('paragraph'));
        this.editorView.dispatch(tr.scrollIntoView());
      }
      this.$emit('image-upload-start');
    },
    onImageUploadStop() {
      // append the image to the editor
    },
    reloadState() {
      this.state = createState(
        this.value,
        this.placeholder,
        this.plugins,
        this.openFileBrowser
      );
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
