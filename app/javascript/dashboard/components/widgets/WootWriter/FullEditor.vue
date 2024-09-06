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

<script>
import {
  fullSchema,
  buildEditor,
  EditorView,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';

import { ArticleMarkdownSerializer } from './custom/articleSerializer';
import { ArticleMarkdownTransformer } from './custom/articleParser';

import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import alertMixin from 'shared/mixins/alertMixin';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

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
  mixins: [keyboardEventListenerMixins, uiSettingsMixin, alertMixin],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    enabledMenuOptions: { type: Array, default: () => [] },
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

    this.addClipBoard();
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
        this.showAlert(
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
        this.showAlert(
          this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.SUCCESS')
        );
      } catch (error) {
        this.showAlert(
          this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR')
        );
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
      this.addClipBoard();
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

    addClipBoard() {
      const menuItems = document.querySelectorAll('.ProseMirror-menuitem')
      const lastItem = menuItems[menuItems.length - 1]

      if (lastItem) {
        const copyToClipboard = lastItem.cloneNode(true);
        const container = copyToClipboard.children[0]

        if (container) {
          container.style.marginTop = '-10px';
          const img = document.createElement('img');
          container.title = 'Copy to clipboard';
          if (document.body.classList.contains('dark')) {
            img.src = '/assets/images/dashboard/editor/copy-dark.svg';
          } else {
            img.src = '/assets/images/dashboard/editor/copy.svg';
          }
          img.style.width = '20px';
          img.style.height = '20px';
          img.style.top = '-2px';
          img.style.position = 'relative';
          container.innerHTML = ''
          container.appendChild(img);
        }
        lastItem.insertAdjacentElement('afterend', copyToClipboard);

        copyToClipboard.addEventListener('click', () => {
          container.classList.add('ProseMirror-menu-active');

          setTimeout(() => {
            container.classList.remove('ProseMirror-menu-active');
          }, 1000);

          if (navigator.clipboard) {
            navigator.clipboard.writeText(document.getSelection().toString()).then(() => {
              this.showAlert('copied!');
            }).catch(err => {
              this.showAlert('Something went wrong');
            });
          } else {
            try {
              document.execCommand('copy');
              this.showAlert('copied!');
            } catch (err) {
              this.showAlert('Something went wrong');
            }
          }
        });
      }
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
