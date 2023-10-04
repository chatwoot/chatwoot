<template>
  <div class="editor-root relative">
    <tag-agents
      v-if="showUserMentions && isPrivate"
      :search-key="mentionSearchKey"
      @click="insertMentionNode"
    />
    <canned-response
      v-if="shouldShowCannedResponses"
      :search-key="cannedSearchTerm"
      @click="insertCannedResponse"
    />
    <variable-list
      v-if="shouldShowVariables"
      :search-key="variableSearchTerm"
      @click="insertVariable"
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
      v-show="isImageSelected && showImageToolbar"
      class="image-toolbar absolute shadow-md rounded-[4px] flex gap-1 py-1 px-1 bg-slate-50 dark:bg-slate-700 text-slate-800 dark:text-slate-50"
      :style="{
        top: toolbarPosition.top,
        left: toolbarPosition.left,
      }"
    >
      <button
        v-for="size in sizes"
        :key="size.name"
        class="text-xs font-medium rounded-[4px] border border-solid border-slate-200 dark:border-slate-600 px-1.5 py-0.5 hover:bg-slate-100 dark:hover:bg-slate-800"
        @click="setURLWithQueryAndSize(size)"
      >
        {{ size.name }}
      </button>
    </div>
    <slot name="footer" />
  </div>
</template>

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

import TagAgents from '../conversation/TagAgents.vue';
import CannedResponse from '../conversation/CannedResponse.vue';
import VariableList from '../conversation/VariableList.vue';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';

const TYPING_INDICATOR_IDLE_TIME = 4000;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
  hasPressedAltAndPKey,
  hasPressedAltAndLKey,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { isEditorHotKeyEnabled } from 'dashboard/mixins/uiSettings';
import { replaceVariablesInMessage } from '@chatwoot/utils';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import alertMixin from 'shared/mixins/alertMixin';
import { findNodeToInsertImage } from 'dashboard/helper/messageEditorHelper';
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
  components: { TagAgents, CannedResponse, VariableList },
  mixins: [eventListenerMixins, uiSettingsMixin, alertMixin],
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
    showImageToolbar: { type: Boolean, default: false }, // A kill switch to show the image toolbar
  },
  data() {
    return {
      showUserMentions: false,
      showCannedMenu: false,
      showVariables: false,
      mentionSearchKey: '',
      cannedSearchTerm: '',
      variableSearchTerm: '',
      editorView: null,
      range: null,
      state: undefined,
      isImageSelected: false,
      toolbarPosition: { top: 0, left: 0 },
      sizes: MESSAGE_EDITOR_IMAGE_RESIZES,
    };
  },
  computed: {
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

            this.mentionSearchKey = args.text.replace('@', '');

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

            this.cannedSearchTerm = args.text.replace('/', '');
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

            this.variableSearchTerm = args.text.replace('{{', '');
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
      ];
    },
    sendWithSignature() {
      // this is considered the source of truth, we watch this property
      // on change, we toggle the signature in the editor
      const { send_with_signature: isEnabled } = this.uiSettings;
      return isEnabled && this.allowSignature && !this.isPrivate;
    },
  },
  watch: {
    showUserMentions(updatedValue) {
      this.$emit('toggle-user-mention', this.isPrivate && updatedValue);
    },
    showCannedMenu(updatedValue) {
      this.$emit('toggle-canned-menu', !this.isPrivate && updatedValue);
    },
    showVariables(updatedValue) {
      this.$emit('toggle-variables-menu', !this.isPrivate && updatedValue);
    },
    value(newVal = '') {
      if (newVal !== this.contentFromEditor) {
        this.reloadState(newVal);
      }
    },
    editorId() {
      this.showCannedMenu = false;
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
          this.emitOnChange();
          this.$emit('clear-selection');
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
    this.focusEditor(this.value);
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
      } else {
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
      const selectedNode = document.querySelector(
        'img.ProseMirror-selectednode'
      );
      if (selectedNode) {
        this.selectedNode = selectedNode;
        this.isImageSelected = !!selectedNode;
        // Get the position of the selected node
        this.setToolbarPosition();
      } else {
        this.isImageSelected = false;
      }
    },
    setToolbarPosition() {
      const editorRoot = document.querySelector('.editor-root');
      const editorRect = editorRoot.getBoundingClientRect();
      const rect = this.selectedNode.getBoundingClientRect();
      this.toolbarPosition = {
        top: `${rect.top - editorRect.top - 30}px`,
        left: `${rect.left - editorRect.left - 4}px`,
      };
    },
    setURLWithQueryAndSize(size) {
      if (this.selectedNode) {
        // Update the URL query "cw_image_height"
        const url = new URL(this.selectedNode.src);
        // Set the new URL with the updated query with the height
        url.searchParams.set('cw_image_height', size.height);
        this.selectedNode.src = url.href;
        this.selectedNode.style.height = size.height;

        // Create and apply the transaction
        const tr = this.editorView.state.tr.setNodeMarkup(
          this.editorView.state.selection.from,
          null,
          {
            src: url.href,
            height: size.height,
          }
        );
        this.isImageSelected = false;
        if (tr.docChanged) {
          this.editorView.dispatch(tr);
        }
      }
    },
    isEnterToSendEnabled() {
      return isEditorHotKeyEnabled(this.uiSettings, 'enter');
    },
    isCmdPlusEnterToSendEnabled() {
      return isEditorHotKeyEnabled(this.uiSettings, 'cmd_enter');
    },
    handleKeyEvents(e) {
      if (hasPressedAltAndPKey(e)) {
        this.focusEditorInputField();
      }
      if (hasPressedAltAndLKey(e)) {
        this.focusEditorInputField();
      }
    },
    focusEditorInputField(pos = 'end') {
      const { tr } = this.editorView.state;

      const selection =
        pos === 'end' ? Selection.atEnd(tr.doc) : Selection.atStart(tr.doc);

      this.editorView.dispatch(tr.setSelection(selection));
      this.editorView.focus();
    },
    insertMentionNode(mentionItem) {
      if (!this.editorView) {
        return null;
      }
      const node = this.editorView.state.schema.nodes.mention.create({
        userId: mentionItem.id,
        userFullName: mentionItem.name,
      });

      const tr = this.editorView.state.tr
        .replaceWith(this.range.from, this.range.to, node)
        .insertText(` `);
      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();
      this.$track(CONVERSATION_EVENTS.USED_MENTIONS);

      return false;
    },
    insertCannedResponse(cannedItem) {
      const updatedMessage = replaceVariablesInMessage({
        message: cannedItem,
        variables: this.variables,
      });
      if (!this.editorView) {
        return null;
      }

      let from = this.range.from - 1;
      let node = new MessageMarkdownTransformer(messageSchema).parse(
        updatedMessage
      );

      if (node.textContent === updatedMessage) {
        node = this.editorView.state.schema.text(updatedMessage);
        from = this.range.from;
      }

      const tr = this.editorView.state.tr.replaceWith(
        from,
        this.range.to,
        node
      );

      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();

      tr.scrollIntoView();
      this.$track(CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE);
      return false;
    },
    insertVariable(variable) {
      if (!this.editorView) {
        return null;
      }
      let node = this.editorView.state.schema.text(`{{${variable}}}`);
      const from = this.range.from;

      const tr = this.editorView.state.tr.replaceWith(
        from,
        this.range.to,
        node
      );

      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();

      // The `{{ }}` are added to the message, but the cursor is placed
      // and onExit of suggestionsPlugin is not called. So we need to manually hide
      this.showVariables = false;
      this.$track(CONVERSATION_EVENTS.INSERTED_A_VARIABLE);
      tr.scrollIntoView();
      return false;
    },
    openFileBrowser() {
      this.$refs.imageUpload.click();
    },
    onFileChange() {
      const file = this.$refs.imageUpload.files[0];
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.uploadImageToStorage(file);
      } else {
        this.showAlert(
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
        this.showAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SUCCESS'
          )
        );
      } catch (error) {
        this.showAlert(
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
      this.editorView.updateState(this.state);

      this.$emit('input', this.contentFromEditor);
    },

    hideMentions() {
      this.showUserMentions = false;
    },
    resetTyping() {
      this.$emit('typing-off');
      this.idleTimer = null;
    },
    turnOffIdleTimer() {
      if (this.idleTimer) {
        clearTimeout(this.idleTimer);
      }
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
      if (!this.idleTimer) {
        this.$emit('typing-on');
      }
      this.turnOffIdleTimer();
      this.idleTimer = setTimeout(
        () => this.resetTyping(),
        TYPING_INDICATOR_IDLE_TIME
      );
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
      this.turnOffIdleTimer();
      this.resetTyping();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
  },
};
</script>

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
  @apply z-50 bg-slate-25 dark:bg-slate-700 rounded-md border border-solid border-slate-75 dark:border-slate-800;

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
  @apply text-red-400 dark:text-red-400 text-sm font-normal pt-1 pb-0 px-0;
}
</style>
