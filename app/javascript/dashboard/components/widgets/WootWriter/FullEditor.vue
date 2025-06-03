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
import imagePastePlugin from '@chatwoot/prosemirror-schema/src/plugins/image';
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

let editorView = null;
let state;

export default {
  mixins: [keyboardEventListenerMixins],
  props: {
    modelValue: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    enabledMenuOptions: { type: Array, default: () => [] },
    autofocus: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['blur', 'input', 'update:modelValue', 'keyup', 'focus', 'keydown'],
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      plugins: [imagePastePlugin(this.handleImageUpload)],
      isTextSelected: false, // Tracks text selection and prevents unnecessary re-renders on mouse selection
    };
  },
  watch: {
    modelValue(newValue = '') {
      if (newValue !== this.contentFromEditor()) {
        this.reloadState();
      }
    },
    editorId() {
      this.reloadState();
    },
  },

  created() {
    state = createState(
      this.modelValue,
      this.placeholder,
      this.plugins,
      { onImageUpload: this.openFileBrowser },
      this.enabledMenuOptions
    );
  },
  mounted() {
    this.createEditorView();

    editorView.updateState(state);
    if (this.autofocus) {
      this.focusEditorInputField();
    }
  },
  methods: {
    contentFromEditor() {
      if (editorView) {
        return ArticleMarkdownSerializer.serialize(editorView.state.doc);
      }
      return '';
    },
    openFileBrowser() {
      this.$refs.imageUploadInput.click();
    },
    async handleImageUpload(url) {
      try {
        const fileUrl = await this.$store.dispatch(
          'articles/uploadExternalImage',
          {
            portalSlug: this.$route.params.portalSlug,
            url,
          }
        );

        return fileUrl;
      } catch (error) {
        useAlert(
          this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.UN_AUTHORIZED_ERROR')
        );
        return '';
      }
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
      const { selection } = editorView.state;
      const from = selection.from;
      const node = editorView.state.schema.nodes.image.create({
        src: fileUrl,
      });
      const paragraphNode = editorView.state.schema.node('paragraph');
      if (node) {
        // Insert the image and the caption wrapped inside a paragraph
        const tr = editorView.state.tr
          .replaceSelectionWith(paragraphNode)
          .insert(from + 1, node);

        editorView.dispatch(tr.scrollIntoView());
        this.focusEditorInputField();
      }
    },
    reloadState() {
      state = createState(
        this.modelValue,
        this.placeholder,
        this.plugins,
        { onImageUpload: this.openFileBrowser },
        this.enabledMenuOptions
      );
      editorView.updateState(state);
      this.focusEditorInputField();
    },
    createEditorView() {
      editorView = new EditorView(this.$refs.editor, {
        state: state,
        dispatchTransaction: tx => {
          state = state.apply(tx);
          editorView.updateState(state);
          if (tx.docChanged) {
            this.emitOnChange();
          }
          this.checkSelection(state);
        },
        handleDOMEvents: {
          keyup: this.onKeyup,
          focus: this.onFocus,
          blur: this.onBlur,
          keydown: this.onKeydown,
          paste: (view, event) => {
            const data = event.clipboardData.files;
            if (data.length > 0) {
              data.forEach(file => {
                // Check if the file is an image
                if (file.type.includes('image')) {
                  this.uploadImageToStorage(file);
                }
              });
              event.preventDefault();
            }
          },
        },
      });
    },
    handleKeyEvents() {},
    focusEditorInputField() {
      const { tr } = editorView.state;
      const selection = Selection.atEnd(tr.doc);

      editorView.dispatch(tr.setSelection(selection));
      editorView.focus();
    },
    emitOnChange() {
      this.$emit('update:modelValue', this.contentFromEditor());
      this.$emit('input', this.contentFromEditor());
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
    checkSelection(editorState) {
      const { from, to } = editorState.selection;
      // Check if there's a selection (from and to are different)
      const hasSelection = from !== to;
      // If the selection state is the same as the previous state, do nothing
      if (hasSelection === this.isTextSelected) return;
      // Update the selection state
      this.isTextSelected = hasSelection;

      const { editor } = this.$refs;

      // Toggle the 'has-selection' class based on whether there's a selection
      editor.classList.toggle('has-selection', hasSelection);
      // If there's a selection, update the menubar position
      if (hasSelection) this.setMenubarPosition(editorState);
    },
    setMenubarPosition(editorState) {
      if (!editorState.selection) return;

      // Get the start and end positions of the selection
      const { from, to } = editorState.selection;
      const { editor } = this.$refs;
      // Get the editor's position relative to the viewport
      const { left: editorLeft, top: editorTop } =
        editor.getBoundingClientRect();

      // Get the editor's width
      const editorWidth = editor.offsetWidth;
      const menubarWidth = 480; // Menubar width (adjust as needed (px))

      // Get the end position of the selection
      const { bottom: endBottom, right: endRight } = editorView.coordsAtPos(to);
      // Get the start position of the selection
      const { left: startLeft } = editorView.coordsAtPos(from);

      // Calculate the top position for the menubar (10px below the selection)
      const top = endBottom - editorTop + 10;
      // Calculate the left position for the menubar
      // This centers the menubar on the selection while keeping it within the editor's bounds
      const left = Math.max(
        0,
        Math.min(
          (startLeft + endRight) / 2 - editorLeft,
          editorWidth - menubarWidth
        )
      );
      // Set the CSS custom properties for positioning the menubar
      editor.style.setProperty('--selection-top', `${top}px`);
      editor.style.setProperty('--selection-left', `${left}px`);
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
@import '@chatwoot/prosemirror-schema/src/styles/article.scss';

.ProseMirror-menubar-wrapper {
  display: flex;
  flex-direction: column;

  > .ProseMirror {
    padding: 0;
    word-break: break-word;
  }
}

.editor-root {
  position: relative;
  width: 100%;
}

.ProseMirror-woot-style {
  min-height: 5rem;
  max-height: 7.5rem;
  overflow: auto;
}

.ProseMirror-prompt {
  @apply z-[9999] bg-n-alpha-3 min-w-80 backdrop-blur-[100px] border border-n-strong p-6 shadow-xl rounded-xl;

  h5 {
    @apply text-n-slate-12 mb-1.5;
  }

  .ProseMirror-prompt-buttons {
    button {
      @apply h-8 px-3;

      &[type='submit'] {
        @apply bg-n-brand text-white hover:bg-n-brand/90;
      }

      &[type='button'] {
        @apply bg-n-slate-9/10 text-n-slate-12 hover:bg-n-slate-9/20;
      }
    }
  }
}
</style>
