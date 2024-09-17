<script>
import {
  messageSchema,
  buildEditor,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';
import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import TagAgents from '../conversation/TagAgents.vue';
import CannedResponse from '../conversation/CannedResponse.vue';
import VariableList from '../conversation/VariableList.vue';
import KeyboardEmojiSelector from './keyboardEmojiSelector.vue';

import {
  appendSignature,
  removeSignature,
  insertAtCursor,
  scrollCursorIntoView,
  findNodeToInsertImage,
  setURLWithQueryAndSize,
  getContentNode,
} from 'dashboard/helper/editorHelper';

const TYPING_INDICATOR_IDLE_TIME = 4000;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
} from 'shared/helpers/KeyboardHelpers';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import { useUISettings } from 'dashboard/composables/useUISettings';

import { createTypingIndicator } from '@chatwoot/utils';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { useAlert } from 'dashboard/composables';
import {
  MESSAGE_EDITOR_MENU_OPTIONS,
  MESSAGE_EDITOR_IMAGE_RESIZES,
} from 'dashboard/constants/editor';

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
    doc: new MessageMarkdownTransformer(messageSchema).parse(content),
    plugins: buildEditor({
      schema: messageSchema,
      placeholder,
      methods,
      plugins,
      enabledMenuOptions,
    }),
  });
};

export default {
  name: 'WootMessageEditor',
  components: {
    TagAgents,
    CannedResponse,
    VariableList,
    KeyboardEmojiSelector,
  },
  mixins: [keyboardEventListenerMixins],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    isPrivate: { type: Boolean, default: false },
    enableSuggestions: { type: Boolean, default: true },
    overrideLineBreaks: { type: Boolean, default: false },
    updateSelectionWith: { type: String, default: '' },
    enableVariables: { type: Boolean, default: false },
    enableCannedResponses: { type: Boolean, default: true },
    variables: { type: Object, default: () => ({}) },
    enabledMenuOptions: { type: Array, default: () => [] },
    signature: { type: String, default: '' },
    // allowSignature is a kill switch, ensuring no signature methods
    // are triggered except when this flag is true
    allowSignature: { type: Boolean, default: false },
    channelType: { type: String, default: '' },
    showImageResizeToolbar: { type: Boolean, default: false }, // A kill switch to show or hide the image toolbar
    focusOnMount: { type: Boolean, default: true },
  },
  setup() {
    const {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
    } = useUISettings();

    return {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
    };
  },
  data() {
    return {
      typingIndicator: createTypingIndicator(
        () => {
          this.$emit('typingOn');
        },
        () => {
          this.$emit('typingOff');
        },
        TYPING_INDICATOR_IDLE_TIME
      ),
      showUserMentions: false,
      showCannedMenu: false,
      showVariables: false,
      showEmojiMenu: false,
      mentionSearchKey: '',
      cannedSearchTerm: '',
      variableSearchTerm: '',
      emojiSearchTerm: '',
      editorView: null,
      range: null,
      state: undefined,
      isImageNodeSelected: false,
      toolbarPosition: { top: 0, left: 0 },
      sizes: MESSAGE_EDITOR_IMAGE_RESIZES,
      selectedImageNode: null,
    };
  },
  computed: {
    editorRoot() {
      return this.$refs.editorRoot;
    },
    contentFromEditor() {
      return MessageMarkdownSerializer.serialize(this.editorView.state.doc);
    },
    shouldShowVariables() {
      return this.enableVariables && this.showVariables && !this.isPrivate;
    },
    shouldShowCannedResponses() {
      return (
        this.enableCannedResponses && this.showCannedMenu && !this.isPrivate
      );
    },
    editorMenuOptions() {
      return this.enabledMenuOptions.length
        ? this.enabledMenuOptions
        : MESSAGE_EDITOR_MENU_OPTIONS;
    },
    plugins() {
      if (!this.enableSuggestions) {
        return [];
      }

      return [
        suggestionsPlugin({
          matcher: triggerCharacters('@'),
          onEnter: args => {
            this.showUserMentions = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.mentionSearchKey = args.text;

            return false;
          },
          onExit: () => {
            this.mentionSearchKey = '';
            this.showUserMentions = false;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showUserMentions;
          },
        }),
        suggestionsPlugin({
          matcher: triggerCharacters('/'),
          suggestionClass: '',
          onEnter: args => {
            if (this.isPrivate) {
              return false;
            }
            this.showCannedMenu = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.cannedSearchTerm = args.text;
            return false;
          },
          onExit: () => {
            this.cannedSearchTerm = '';
            this.showCannedMenu = false;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showCannedMenu;
          },
        }),
        suggestionsPlugin({
          matcher: triggerCharacters('{{'),
          suggestionClass: '',
          onEnter: args => {
            if (this.isPrivate) {
              return false;
            }
            this.showVariables = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.variableSearchTerm = args.text;
            return false;
          },
          onExit: () => {
            this.variableSearchTerm = '';
            this.showVariables = false;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showVariables;
          },
        }),
        suggestionsPlugin({
          matcher: triggerCharacters(':', 2), // Trigger after ':' and at least 2 characters
          suggestionClass: '',
          onEnter: args => {
            this.showEmojiMenu = true;
            this.emojiSearchTerm = args.text || '';
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;
            this.emojiSearchTerm = args.text;
            return false;
          },
          onExit: () => {
            this.emojiSearchTerm = '';
            this.showEmojiMenu = false;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showEmojiMenu;
          },
        }),
      ];
    },
    sendWithSignature() {
      // this is considered the source of truth, we watch this property
      // on change, we toggle the signature in the editor
      if (this.allowSignature && !this.isPrivate && this.channelType) {
        return this.fetchSignatureFlagFromUISettings(this.channelType);
      }

      return false;
    },
  },
  watch: {
    showUserMentions(updatedValue) {
      this.$emit('toggleUserMention', this.isPrivate && updatedValue);
    },
    showCannedMenu(updatedValue) {
      this.$emit('toggleCannedMenu', !this.isPrivate && updatedValue);
    },
    showVariables(updatedValue) {
      this.$emit('toggleVariablesMenu', !this.isPrivate && updatedValue);
    },
    value(newVal = '') {
      if (newVal !== this.contentFromEditor) {
        this.reloadState(newVal);
      }
    },
    editorId() {
      this.showCannedMenu = false;
      this.showEmojiMenu = false;
      this.showVariables = false;
      this.cannedSearchTerm = '';
      this.reloadState(this.value);
    },
    isPrivate() {
      this.reloadState(this.value);
    },
    updateSelectionWith(newValue, oldValue) {
      if (!this.editorView) {
        return null;
      }
      if (newValue !== oldValue) {
        if (this.updateSelectionWith !== '') {
          const node = this.editorView.state.schema.text(
            this.updateSelectionWith
          );
          const tr = this.editorView.state.tr.replaceSelectionWith(node);
          this.editorView.focus();
          this.state = this.editorView.state.apply(tr);
          this.editorView.updateState(this.state);
          this.emitOnChange();
          this.$emit('clearSelection');
        }
      }
      return null;
    },
    sendWithSignature(newValue) {
      // see if the allowSignature flag is true
      if (this.allowSignature) {
        this.toggleSignatureInEditor(newValue);
      }
    },
  },
  created() {
    this.state = createState(
      this.value,
      this.placeholder,
      this.plugins,
      { onImageUpload: this.openFileBrowser },
      this.editorMenuOptions
    );
  },
  mounted() {
    this.createEditorView();
    this.editorView.updateState(this.state);
    if (this.focusOnMount) {
      this.focusEditorInputField();
    }

    // BUS Event to insert text or markdown into the editor at the
    // current cursor position.
    // Components using this
    // 1. SearchPopover.vue

    this.$emitter.on(
      BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
      this.insertContentIntoEditor
    );
  },
  beforeDestroy() {
    this.$emitter.off(
      BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
      this.insertContentIntoEditor
    );
  },
  methods: {
    reloadState(content = this.value) {
      this.state = createState(
        content,
        this.placeholder,
        this.plugins,
        { onImageUpload: this.openFileBrowser },
        this.editorMenuOptions
      );
      this.editorView.updateState(this.state);

      this.focusEditor(content);
    },
    focusEditor(content) {
      if (this.isBodyEmpty(content) && this.sendWithSignature) {
        // reload state can be called when switching between conversations, or when drafts is loaded
        // these drafts can also have a signature, so we need to check if the body is empty
        // and handle things accordingly
        this.handleEmptyBodyWithSignature();
      } else if (this.focusOnMount) {
        // this is in the else block, handleEmptyBodyWithSignature also has a call to the focus method
        // the position is set to start, because the signature is added at the end of the body
        this.focusEditorInputField('end');
      }
    },
    toggleSignatureInEditor(signatureEnabled) {
      // The toggleSignatureInEditor gets the new value from the
      // watcher, this means that if the value is true, the signature
      // is supposed to be added, else we remove it.
      if (signatureEnabled) {
        this.addSignature();
      } else {
        this.removeSignature();
      }
    },
    addSignature() {
      let content = this.value;
      // see if the content is empty, if it is before appending the signature
      // we need to add a paragraph node and move the cursor at the start of the editor
      const contentWasEmpty = this.isBodyEmpty(content);
      content = appendSignature(content, this.signature);
      // need to reload first, ensuring that the editorView is updated
      this.reloadState(content);

      if (contentWasEmpty) {
        this.handleEmptyBodyWithSignature();
      }
    },
    removeSignature() {
      if (!this.signature) return;
      let content = this.value;
      content = removeSignature(content, this.signature);
      // reload the state, ensuring that the editorView is updated
      this.reloadState(content);
    },
    isBodyEmpty(content) {
      // if content is undefined, we assume that the body is empty
      if (!content) return true;

      // if the signature is present, we need to remove it before checking
      // note that we don't update the editorView, so this is safe
      const bodyWithoutSignature = this.signature
        ? removeSignature(content, this.signature)
        : content;

      // trimming should remove all the whitespaces, so we can check the length
      return bodyWithoutSignature.trim().length === 0;
    },
    handleEmptyBodyWithSignature() {
      const { schema, tr } = this.state;

      // create a paragraph node and
      // start a transaction to append it at the end
      const paragraph = schema.nodes.paragraph.create();
      const paragraphTransaction = tr.insert(0, paragraph);
      this.editorView.dispatch(paragraphTransaction);

      // Set the focus at the start of the input field
      this.focusEditorInputField('start');
    },
    createEditorView() {
      this.editorView = new EditorView(this.$refs.editor, {
        state: this.state,
        dispatchTransaction: tx => {
          this.state = this.state.apply(tx);
          this.editorView.updateState(this.state);
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
          click: () => {
            this.isEditorMouseFocusedOnAnImage();
          },
          blur: () => {
            this.onBlur();
          },
          paste: (view, event) => {
            const data = event.clipboardData.files;
            if (data.length > 0) {
              event.preventDefault();
            }
          },
        },
      });
    },
    isEditorMouseFocusedOnAnImage() {
      if (!this.showImageResizeToolbar) {
        return;
      }
      this.selectedImageNode = document.querySelector(
        'img.ProseMirror-selectednode'
      );
      if (this.selectedImageNode) {
        this.isImageNodeSelected = !!this.selectedImageNode;
        // Get the position of the selected node
        this.setToolbarPosition();
      } else {
        this.isImageNodeSelected = false;
      }
    },
    setToolbarPosition() {
      const editorRect = this.editorRoot.getBoundingClientRect();
      const rect = this.selectedImageNode.getBoundingClientRect();
      this.toolbarPosition = {
        top: `${rect.top - editorRect.top - 30}px`,
        left: `${rect.left - editorRect.left - 4}px`,
      };
    },
    setURLWithQueryAndImageSize(size) {
      if (!this.showImageResizeToolbar) {
        return;
      }
      setURLWithQueryAndSize(this.selectedImageNode, size, this.editorView);
      this.isImageNodeSelected = false;
    },
    updateImgToolbarOnDelete() {
      // check if the selected node is present or not on keyup
      // this is needed because the user can select an image and then delete it
      // in that case, the selected node will be null and we need to hide the toolbar
      // otherwise, the toolbar will be visible even when the image is deleted and cause some errors
      if (this.selectedImageNode) {
        const hasImgSelectedNode = document.querySelector(
          'img.ProseMirror-selectednode'
        );
        if (!hasImgSelectedNode) {
          this.isImageNodeSelected = false;
        }
      }
    },
    isEnterToSendEnabled() {
      return this.isEditorHotKeyEnabled('enter');
    },
    isCmdPlusEnterToSendEnabled() {
      return this.isEditorHotKeyEnabled('cmd_enter');
    },
    getKeyboardEvents() {
      return {
        'Alt+KeyP': {
          action: () => {
            this.focusEditorInputField();
          },
          allowOnFocusedInput: true,
        },
        'Alt+KeyL': {
          action: () => {
            this.focusEditorInputField();
          },
          allowOnFocusedInput: true,
        },
      };
    },
    focusEditorInputField(pos = 'end') {
      const { tr } = this.editorView.state;

      const selection =
        pos === 'end' ? Selection.atEnd(tr.doc) : Selection.atStart(tr.doc);

      this.editorView.dispatch(tr.setSelection(selection));
      this.editorView.focus();
    },
    /**
     * Inserts special content (mention, canned response, variable, emoji) into the editor.
     * @param {string} type - The type of special content to insert. Possible values: 'mention', 'canned_response', 'variable', 'emoji'.
     * @param {Object|string} content - The content to insert, depending on the type.
     */
    insertSpecialContent(type, content) {
      if (!this.editorView) {
        return;
      }

      let { node, from, to } = getContentNode(
        this.editorView,
        type,
        content,
        this.range,
        this.variables
      );

      if (!node) return;

      this.insertNodeIntoEditor(node, from, to);

      const event_map = {
        mention: CONVERSATION_EVENTS.USED_MENTIONS,
        cannedResponse: CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE,
        variable: CONVERSATION_EVENTS.INSERTED_A_VARIABLE,
        emoji: CONVERSATION_EVENTS.INSERTED_AN_EMOJI,
      };

      this.$track(event_map[type]);
    },
    openFileBrowser() {
      this.$refs.imageUpload.click();
    },
    onFileChange() {
      const file = this.$refs.imageUpload.files[0];
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.uploadImageToStorage(file);
      } else {
        useAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
            {
              size: MAXIMUM_FILE_UPLOAD_SIZE,
            }
          )
        );
      }

      this.$refs.imageUpload.value = '';
    },
    async uploadImageToStorage(file) {
      try {
        const { fileUrl } = await uploadFile(file);
        if (fileUrl) {
          this.onImageInsertInEditor(fileUrl);
        }
        useAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SUCCESS'
          )
        );
      } catch (error) {
        useAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_ERROR'
          )
        );
      }
    },
    onImageInsertInEditor(fileUrl) {
      const { tr } = this.editorView.state;

      const insertData = findNodeToInsertImage(this.editorView.state, fileUrl);

      if (insertData) {
        this.editorView.dispatch(
          tr.insert(insertData.pos, insertData.node).scrollIntoView()
        );
        this.focusEditorInputField();
      }
    },

    emitOnChange() {
      this.$emit('input', this.contentFromEditor);
    },

    hideMentions() {
      this.showUserMentions = false;
    },
    handleLineBreakWhenEnterToSendEnabled(event) {
      if (
        hasPressedEnterAndNotCmdOrShift(event) &&
        this.isEnterToSendEnabled() &&
        !this.overrideLineBreaks
      ) {
        event.preventDefault();
      }
    },
    handleLineBreakWhenCmdAndEnterToSendEnabled(event) {
      if (
        hasPressedCommandAndEnter(event) &&
        this.isCmdPlusEnterToSendEnabled() &&
        !this.overrideLineBreaks
      ) {
        event.preventDefault();
      }
    },
    onKeyup() {
      this.typingIndicator.start();
      this.updateImgToolbarOnDelete();
    },
    onKeydown(event) {
      if (this.isEnterToSendEnabled()) {
        this.handleLineBreakWhenEnterToSendEnabled(event);
      }
      if (this.isCmdPlusEnterToSendEnabled()) {
        this.handleLineBreakWhenCmdAndEnterToSendEnabled(event);
      }
    },
    onBlur() {
      this.typingIndicator.stop();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
    insertContentIntoEditor(content, defaultFrom = 0) {
      const from = defaultFrom || this.editorView.state.selection.from || 0;
      let node = new MessageMarkdownTransformer(messageSchema).parse(content);

      this.insertNodeIntoEditor(node, from, undefined);
    },
    insertNodeIntoEditor(node, from = 0, to = 0) {
      this.state = insertAtCursor(this.editorView, node, from, to);
      this.emitOnChange();
      this.$nextTick(() => {
        scrollCursorIntoView(this.editorView);
      });
    },
  },
};
</script>

<template>
  <div ref="editorRoot" class="relative editor-root">
    <TagAgents
      v-if="showUserMentions && isPrivate"
      :search-key="mentionSearchKey"
      @click="content => insertSpecialContent('mention', content)"
    />
    <CannedResponse
      v-if="shouldShowCannedResponses"
      :search-key="cannedSearchTerm"
      @click="content => insertSpecialContent('cannedResponse', content)"
    />
    <VariableList
      v-if="shouldShowVariables"
      :search-key="variableSearchTerm"
      @click="content => insertSpecialContent('variable', content)"
    />
    <KeyboardEmojiSelector
      v-if="showEmojiMenu"
      :search-key="emojiSearchTerm"
      @click="emoji => insertSpecialContent('emoji', emoji)"
    />
    <input
      ref="imageUpload"
      type="file"
      accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
      hidden
      @change="onFileChange"
    />
    <div ref="editor" />
    <div
      v-show="isImageNodeSelected && showImageResizeToolbar"
      class="absolute shadow-md rounded-[4px] flex gap-1 py-1 px-1 bg-slate-50 dark:bg-slate-700 text-slate-800 dark:text-slate-50"
      :style="{
        top: toolbarPosition.top,
        left: toolbarPosition.left,
      }"
    >
      <button
        v-for="size in sizes"
        :key="size.name"
        class="text-xs font-medium rounded-[4px] border border-solid border-slate-200 dark:border-slate-600 px-1.5 py-0.5 hover:bg-slate-100 dark:hover:bg-slate-800"
        @click="setURLWithQueryAndImageSize(size)"
      >
        {{ size.name }}
      </button>
    </div>
    <slot name="footer" />
  </div>
</template>

<style lang="scss">
@import '~@chatwoot/prosemirror-schema/src/styles/base.scss';

.ProseMirror-menubar-wrapper {
  @apply flex flex-col;
  .ProseMirror-menubar {
    min-height: var(--space-two) !important;
    @apply -ml-2.5 pb-0 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-100;

    .ProseMirror-menu-active {
      @apply bg-slate-75 dark:bg-slate-800;
    }
  }
  > .ProseMirror {
    @apply p-0 break-words text-slate-800 dark:text-slate-100;

    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p {
      @apply text-slate-800 dark:text-slate-100;
    }

    blockquote {
      @apply border-slate-400 dark:border-slate-500;

      p {
        @apply text-slate-600 dark:text-slate-400;
      }
    }

    ol li {
      @apply list-item list-decimal;
    }
  }
}

.editor-root {
  @apply w-full relative;
}

.ProseMirror-woot-style {
  @apply overflow-auto min-h-[5rem] max-h-[7.5rem];
}

.ProseMirror-prompt {
  @apply z-[9999] bg-slate-25 dark:bg-slate-700 rounded-md border border-solid border-slate-75 dark:border-slate-800 shadow-lg;

  h5 {
    @apply dark:text-slate-25 text-slate-800;
  }
}

.is-private {
  .prosemirror-mention-node {
    @apply font-medium bg-yellow-100 dark:bg-yellow-800 text-slate-900 dark:text-slate-25 py-0 px-1;
  }

  .ProseMirror-menubar-wrapper {
    .ProseMirror-menubar {
      @apply bg-yellow-100 dark:bg-yellow-800 text-slate-700 dark:text-slate-25;
    }

    > .ProseMirror {
      @apply text-slate-800 dark:text-slate-25;

      p {
        @apply text-slate-800 dark:text-slate-25;
      }
    }
  }
}

.editor-wrap {
  @apply mb-4;
}

.message-editor {
  @apply border border-solid border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-900 rounded-md py-0 px-1 mb-0;
}

.editor_warning {
  @apply border border-solid border-red-400 dark:border-red-400;
}

.editor-warning__message {
  @apply text-red-400 dark:text-red-400 font-normal text-sm pt-1 pb-0 px-0;
}
</style>
