<script>
import {
  fullSchema,
  buildEditor,
  EditorView,
  ArticleMarkdownSerializer,
  ArticleMarkdownTransformer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB
const createState = (
  content,
  placeholder,
  // eslint-disable-next-line default-param-last
  plugins = [],
  // eslint-disable-next-line default-param-last
  methods = {},
  enabledMenuOptions
) => {
  return EditorState.create({
    doc: new ArticleMarkdownTransformer(fullSchema).parse(content),
    plugins: buildEditor({
      schema: fullSchema,
      placeholder,
      methods,
      plugins,
      enabledMenuOptions,
    }),
  });
};

export default {
  mixins: [keyboardEventListenerMixins],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    enabledMenuOptions: { type: Array, default: () => [] },
  },
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
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
      { onImageUpload: this.openFileBrowser },
      this.enabledMenuOptions
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

      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.uploadImageToStorage(file);
      } else {
        useAlert(
          this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR_FILE_SIZE', {
            size: MAXIMUM_FILE_UPLOAD_SIZE,
          })
        );
      }

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
      } catch (error) {
        useAlert(this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR'));
      }
    },
    onImageUploadStart(fileUrl) {
      const { selection } = this.editorView.state;
      const from = selection.from;
      const node = this.editorView.state.schema.nodes.image.create({
        src: fileUrl,
      });
      const paragraphNode = this.editorView.state.schema.node('paragraph');
      if (node) {
        // Insert the image and the caption wrapped inside a paragraph
        const tr = this.editorView.state.tr
          .replaceSelectionWith(paragraphNode)
          .insert(from + 1, node);

        this.editorView.dispatch(tr.scrollIntoView());
        this.focusEditorInputField();
      }
    },
    reloadState() {
      this.state = createState(
        this.value,
        this.placeholder,
        this.plugins,
        { onImageUpload: this.openFileBrowser },
        this.enabledMenuOptions
      );
      this.editorView.updateState(this.state);
      this.focusEditorInputField();
    },
    insertImage(src, alt = '') {
      const { selection } = this.editorView.state;
      const from = selection.from;
      const node = this.editorView.state.schema.nodes.image.create({
        src,
        alt,
      });
      const paragraphNode = this.editorView.state.schema.node('paragraph');

      if (node) {
        const tr = this.editorView.state.tr
          .replaceSelectionWith(paragraphNode)
          .insert(from + 1, node);

        this.editorView.dispatch(tr.scrollIntoView());
        this.focusEditorInputField();
      }
    },
    handlePastedText(text, view) {
      const markdownImageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;
      let match;
      let lastIndex = 0;
      while ((match = markdownImageRegex.exec(text)) !== null) {
        // Insert text before the image
        if (match.index > lastIndex) {
          const textBefore = text.slice(lastIndex, match.index);
          view.dispatch(view.state.tr.insertText(textBefore));
        }
        // // Insert the image
        const [, alt, src] = match;
        this.insertImage(src, alt);
        lastIndex = markdownImageRegex.lastIndex;
      }
      // Insert any remaining text after the last image
      if (lastIndex < text.length) {
        const remainingText = text.slice(lastIndex);
        view.dispatch(view.state.tr.insertText(remainingText));
      }
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
          paste: (view, event) => {
            const clipboardData = event.clipboardData;
            const pastedText = clipboardData.getData('text/plain');
            const files = clipboardData.files;

            if (files.length > 0) {
              // Handle direct image file paste
              files.forEach(file => this.uploadImageToStorage(file));
              event.preventDefault();
            } else if (pastedText) {
              // Handle potential markdown image links
              this.handlePastedText(pastedText, view);
              event.preventDefault();
            }
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

<template>
  <div>
    <div class="editor-root editor--article">
      <input
        ref="imageUploadInput"
        type="file"
        accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
        hidden
        @change="onFileChange"
      />
      <div ref="editor" />
    </div>
  </div>
</template>

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
  min-height: 5rem;
  max-height: 7.5rem;
  overflow: auto;
}

.ProseMirror-prompt {
  z-index: var(--z-index-highest);
  background: var(--white);
  box-shadow: var(--shadow-large);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  min-width: 25rem;
}
</style>
