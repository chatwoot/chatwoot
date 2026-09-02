<script>
import {
  fullSchema,
  buildEditor,
  EditorView,
  ArticleMarkdownSerializer,
  ArticleMarkdownTransformer,
  EditorState,
  Selection,
  imageResizeView,
  imagePastePlugin,
  embedPreviewPlugin,
  insertImageFiles,
  insertFileUploads,
  hasActiveUploads,
  fileUploadPlugin,
  setUploadLabels,
  toggleMark,
  wrapInList,
} from '@chatwoot/prosemirror-schema';
import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';
import trailingParagraphPlugin from '@chatwoot/prosemirror-schema/src/plugins/trailingParagraph';
import { embeds as markdownEmbeds } from 'dashboard/helper/markdownEmbeds';
import { toggleBlockType } from '@chatwoot/prosemirror-schema/src/menu/common';
import {
  checkFileSizeLimit,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import { isEscape } from 'shared/helpers/KeyboardHelpers';
import { collapseSelection } from 'dashboard/helper/editorHelper';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import SlashCommandMenu from './SlashCommandMenu.vue';
import VideoEmbedInput from './VideoEmbedInput.vue';

const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB
// Drop and paste bypass the file input's accept filter, so bucketFor gates
// every entry point with the same allowlist the picker advertises.
const ALLOWED_IMAGE_TYPES = [
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
];
const ACCEPTED_FILE_TYPES = [...ALLOWED_IMAGE_TYPES, 'video/mp4'].join(', ');
const SLASH_MENU_OFFSET = 4;
// Longest a slow autosave response can realistically lag behind its request.
const STALE_ECHO_WINDOW = 30000; // in ms
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
  components: { SlashCommandMenu, VideoEmbedInput },
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
    const globalConfig = useMapGetter('globalConfig/get');

    return {
      uiSettings,
      updateUISettings,
      globalConfig,
    };
  },
  data() {
    return {
      plugins: [
        imagePastePlugin(this.handleImageUpload),
        fileUploadPlugin(),
        this.createSlashPlugin(),
        embedPreviewPlugin(markdownEmbeds),
        trailingParagraphPlugin(),
      ],
      emittedValues: [],
      pendingSync: null,
      isTextSelected: false, // Tracks text selection and prevents unnecessary re-renders on mouse selection
      showSlashMenu: false,
      slashSearchTerm: '',
      slashRange: null,
      slashMenuPosition: null,
      isSlashMenuInTable: false,
      showVideoInput: false,
      videoInputPosition: null,
      acceptedFileTypes: ACCEPTED_FILE_TYPES,
    };
  },
  computed: {
    maximumVideoUploadSize() {
      return resolveMaximumFileUploadSize(
        this.globalConfig?.maximumFileUploadSize
      );
    },
  },
  watch: {
    modelValue() {
      this.syncFromModel();
    },
    editorId() {
      this.reloadState();
    },
  },

  created() {
    setUploadLabels({
      uploading: this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.UPLOADING'),
      failed: this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.UPLOAD_FAILED'),
      rateLimited: this.$t(
        'HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.RATE_LIMITED'
      ),
      retry: this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.RETRY'),
      remove: this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.REMOVE'),
      cancel: this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.CANCEL'),
    });
    state = createState(
      this.modelValue || '',
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
  beforeUnmount() {
    clearTimeout(this.pendingSync);
    if (editorView) {
      editorView.destroy();
      editorView = null;
    }
  },
  methods: {
    createSlashPlugin() {
      return suggestionsPlugin({
        matcher: triggerCharacters('/', 0),
        suggestionClass: '',
        onEnter: args => {
          this.showSlashMenu = true;
          this.slashRange = args.range;
          this.slashSearchTerm = args.text || '';
          this.isSlashMenuInTable = this.isSelectionInsideTable();
          this.updateSlashMenuPosition(args.range.from);
          return false;
        },
        onChange: args => {
          this.slashRange = args.range;
          this.slashSearchTerm = args.text;
          return false;
        },
        onExit: () => {
          this.slashSearchTerm = '';
          this.showSlashMenu = false;
          this.slashMenuPosition = null;
          return false;
        },
        onKeyDown: ({ event }) =>
          this.$refs.slashMenu?.handleKeyDown(event) ?? false,
      });
    },
    isSelectionInsideTable() {
      const { $from } = editorView.state.selection;
      const { table } = editorView.state.schema.nodes;
      for (let depth = $from.depth; depth > 0; depth -= 1) {
        if ($from.node(depth).type === table) return true;
      }
      return false;
    },
    updateSlashMenuPosition(pos) {
      if (!editorView) return;
      const coords = editorView.coordsAtPos(pos);
      const editorRect = this.$refs.editor.getBoundingClientRect();
      const isRtl = getComputedStyle(this.$refs.editor).direction === 'rtl';
      this.slashMenuPosition = {
        top: coords.bottom - editorRect.top + SLASH_MENU_OFFSET,
        ...(isRtl
          ? { right: editorRect.right - coords.right }
          : { left: coords.left - editorRect.left }),
      };
    },
    removeSlashTriggerText() {
      if (!editorView || !this.slashRange) return;
      const { from, to } = this.slashRange;
      editorView.dispatch(editorView.state.tr.delete(from, to));
      state = editorView.state;
    },
    executeSlashCommand(actionKey) {
      if (!editorView) return;

      if (actionKey === 'video') {
        this.openVideoInput();
        return;
      }

      this.removeSlashTriggerText();

      const { schema } = editorView.state;
      const commandMap = {
        strong: () =>
          toggleMark(schema.marks.strong)(
            editorView.state,
            editorView.dispatch
          ),
        em: () =>
          toggleMark(schema.marks.em)(editorView.state, editorView.dispatch),
        strike: () =>
          toggleMark(schema.marks.strike)(
            editorView.state,
            editorView.dispatch
          ),
        code: () =>
          toggleMark(schema.marks.code)(editorView.state, editorView.dispatch),
        h1: () =>
          toggleBlockType(schema.nodes.heading, { level: 1 })(
            editorView.state,
            editorView.dispatch
          ),
        h2: () =>
          toggleBlockType(schema.nodes.heading, { level: 2 })(
            editorView.state,
            editorView.dispatch
          ),
        h3: () =>
          toggleBlockType(schema.nodes.heading, { level: 3 })(
            editorView.state,
            editorView.dispatch
          ),
        bulletList: () =>
          wrapInList(schema.nodes.bullet_list)(
            editorView.state,
            editorView.dispatch
          ),
        orderedList: () =>
          wrapInList(schema.nodes.ordered_list)(
            editorView.state,
            editorView.dispatch
          ),
        insertTable: () => {
          const { table, table_row, table_header, table_cell, paragraph } =
            schema.nodes;
          const headerCells = [0, 1, 2].map(() =>
            table_header.createAndFill(null, paragraph.create())
          );
          const dataCells = [0, 1, 2].map(() =>
            table_cell.createAndFill(null, paragraph.create())
          );
          const headerRow = table_row.create(null, headerCells);
          const dataRow = table_row.create(null, dataCells);
          const tableNode = table.create(null, [headerRow, dataRow]);
          const tr = editorView.state.tr.replaceSelectionWith(tableNode);
          editorView.dispatch(tr.scrollIntoView());
        },
        horizontalRule: () => {
          editorView.dispatch(
            editorView.state.tr
              .replaceSelectionWith(schema.nodes.horizontal_rule.create())
              .scrollIntoView()
          );
          const { doc, selection, tr } = editorView.state;
          editorView.dispatch(
            tr.setSelection(Selection.near(doc.resolve(selection.to), 1))
          );
        },
        imageUpload: () => this.openFileBrowser(),
      };

      const command = commandMap[actionKey];
      if (command) {
        command();
        state = editorView.state;
        this.emitOnChange();
        editorView.focus();
      }
    },
    openVideoInput() {
      // Capture the caret position before removing the trigger clears it.
      this.videoInputPosition = this.slashMenuPosition;
      this.removeSlashTriggerText();
      this.showVideoInput = true;
    },
    closeVideoInput() {
      this.showVideoInput = false;
      this.videoInputPosition = null;
    },
    insertVideoEmbed(url) {
      this.closeVideoInput();
      if (!editorView) return;

      const { schema } = editorView.state;
      const linkMark = schema.marks.link.create({ href: url });
      const paragraph = schema.nodes.paragraph.create(
        null,
        schema.text(url, [linkMark])
      );
      const tr = editorView.state.tr.replaceSelectionWith(paragraph);
      editorView.dispatch(tr.scrollIntoView());
      state = editorView.state;
      this.emitOnChange();
      editorView.focus();
    },
    cancelVideoInput() {
      this.closeVideoInput();
      editorView?.focus();
    },
    insertVideoFile(file) {
      this.closeVideoInput();
      this.handleFiles([file]);
    },
    contentFromEditor() {
      if (editorView) {
        return ArticleMarkdownSerializer.serialize(editorView.state.doc);
      }
      return '';
    },
    openFileBrowser() {
      this.$refs.imageUploadInput.click();
    },
    handleImageUpload(url, signal) {
      return this.$store.dispatch('articles/uploadExternalImage', {
        portalSlug: this.$route.params.portalSlug,
        url,
        signal,
      });
    },
    onFileChange() {
      this.handleFiles(Array.from(this.$refs.imageUploadInput.files));
      this.$refs.imageUploadInput.value = '';
    },
    // Returns the pipeline for a file that passes its size gate; alerts otherwise.
    bucketFor(file) {
      if (ALLOWED_IMAGE_TYPES.includes(file.type)) {
        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) return 'images';
        useAlert(
          this.$t('HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR_FILE_SIZE', {
            size: MAXIMUM_FILE_UPLOAD_SIZE,
          })
        );
      } else if (file.type === 'video/mp4') {
        if (checkFileSizeLimit(file, this.maximumVideoUploadSize)) {
          return 'videos';
        }
        useAlert(
          this.$t(
            'HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR_ATTACHMENT_FILE_SIZE',
            { size: this.maximumVideoUploadSize }
          )
        );
      } else {
        useAlert(
          this.$t(
            'HELP_CENTER.ARTICLE_EDITOR.IMAGE_UPLOAD.ERROR_UNSUPPORTED_TYPE'
          )
        );
      }
      return null;
    },
    handleFiles(files) {
      if (!editorView || !files.length) return;
      const buckets = { images: [], videos: [] };
      files.forEach(file => {
        const bucket = this.bucketFor(file);
        if (bucket) buckets[bucket].push(file);
      });
      const upload = this.uploadFileToStorage;
      const { images, videos } = buckets;
      if (images.length) insertImageFiles(editorView, images, { upload });
      if (videos.length) insertFileUploads(editorView, videos, { upload });
      if (images.length || videos.length) editorView.focus();
    },
    // In-flight uploads and failed cards: resolving a draft or navigating
    // away would drop them.
    hasPendingUploads() {
      if (!editorView) return false;
      return (
        hasActiveUploads(editorView) ||
        !!editorView.dom.querySelector(
          '.pm-upload-card[data-state="error"], .pm-upload-overlay[data-state="error"]'
        )
      );
    },
    uploadFileToStorage(file, onProgress, signal) {
      return this.$store.dispatch('articles/attachImage', {
        portalSlug: this.$route.params.portalSlug,
        file,
        onProgress,
        signal,
      });
    },
    reloadState() {
      clearTimeout(this.pendingSync);
      this.pendingSync = null;
      // Old emissions are history of a superseded document.
      this.emittedValues = [];
      state = createState(
        this.modelValue || '',
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
        nodeViews: {
          image: imageResizeView,
        },
        dispatchTransaction: tx => {
          state = state.apply(tx);
          editorView.updateState(state);
          if (tx.docChanged) {
            this.emitOnChange();
          }
          this.checkSelection(state);
        },
        handleDrop: (view, event, slice, moved) => {
          if (moved) return false;
          const files = Array.from(event.dataTransfer?.files || []);
          if (!files.length) return false;
          const coords = view.posAtCoords({
            left: event.clientX,
            top: event.clientY,
          });
          if (coords) {
            view.dispatch(
              view.state.tr.setSelection(
                Selection.near(view.state.doc.resolve(coords.pos))
              )
            );
          }
          this.handleFiles(files);
          event.preventDefault();
          return true;
        },
        handleDOMEvents: {
          keyup: this.onKeyup,
          focus: this.onFocus,
          blur: this.onBlur,
          keydown: this.onKeydown,
          paste: (view, event) => {
            const files = Array.from(event.clipboardData?.files || []);
            if (files.length > 0) {
              this.handleFiles(files);
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
    // A recent emission is our own autosave echo — re-check it once the
    // window passes. Anything else is a definitive reset: apply it now.
    syncFromModel() {
      clearTimeout(this.pendingSync);
      this.pendingSync = null;
      const value = this.modelValue || '';
      if (value === this.contentFromEditor()) return;
      if (this.recentlyEmitted(value)) {
        this.pendingSync = setTimeout(
          () => this.syncFromModel(),
          STALE_ECHO_WINDOW
        );
        return;
      }
      this.reloadState();
    },
    recentlyEmitted(value) {
      const now = Date.now();
      this.emittedValues = this.emittedValues.filter(
        entry => now - entry.at < STALE_ECHO_WINDOW
      );
      return this.emittedValues.some(entry => entry.value === value);
    },
    emitOnChange() {
      const content = this.contentFromEditor();
      this.emittedValues.push({ value: content, at: Date.now() });
      if (this.emittedValues.length > 20) this.emittedValues.shift();
      this.$emit('update:modelValue', content);
      this.$emit('input', content);
    },
    onKeyup() {
      this.$emit('keyup');
    },
    onKeydown(view, event) {
      this.$emit('keydown');
      if (isEscape(event)) {
        if (this.showSlashMenu) {
          this.showSlashMenu = false;
          this.slashSearchTerm = '';
          this.slashMenuPosition = null;
          return true;
        }
        collapseSelection(editorView);
        return true;
      }
      return false;
    },
    onBlur() {
      // ProseMirror keeps its selection on blur — clear the menu flag manually.
      this.isTextSelected = false;
      this.$refs.editor?.classList.remove('has-selection');
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
    checkSelection(editorState) {
      const { selection } = editorState;
      // Skip NodeSelection (from Esc -> selectParentNode); only text ranges count.
      const hasSelection = !selection.empty && !selection.node;
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
      const menubar = editor.querySelector('.ProseMirror-menubar');
      const menubarWidth = menubar ? menubar.scrollWidth : 480;

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
    <div class="editor-root editor--article relative">
      <SlashCommandMenu
        v-if="showSlashMenu"
        ref="slashMenu"
        :search-key="slashSearchTerm"
        :enabled-menu-options="enabledMenuOptions"
        :position="slashMenuPosition"
        :is-in-table="isSlashMenuInTable"
        @select-action="executeSlashCommand"
      />
      <VideoEmbedInput
        v-if="showVideoInput"
        :position="videoInputPosition"
        :max-upload-size="maximumVideoUploadSize"
        @submit="insertVideoEmbed"
        @upload="insertVideoFile"
        @cancel="cancelVideoInput"
      />
      <input
        ref="imageUploadInput"
        type="file"
        :accept="acceptedFileTypes"
        multiple
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

.ProseMirror .cw-embed-preview {
  max-width: 36rem;
  margin: 0.5rem 0 1rem;
}
</style>
