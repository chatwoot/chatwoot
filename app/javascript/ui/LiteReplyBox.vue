<script>
import { useTemplateRef } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

import ReplyBottomPanel from 'dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview.vue';
import ReplyTopPanel from 'dashboard/components/widgets/WootWriter/ReplyTopPanel.vue';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import inboxMixin from 'shared/mixins/inboxMixin';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

export default {
  components: {
    AttachmentPreview,
    ReplyTopPanel,
    ReplyBottomPanel,
    WootMessageEditor,
  },
  mixins: [inboxMixin, fileUploadMixin, keyboardEventListenerMixins],
  setup() {
    const replyEditor = useTemplateRef('replyEditor');

    return { replyEditor };
  },
  data() {
    return {
      message: '',
      isFocused: false,
      attachedFiles: [],
      isUploading: false,
      replyType: REPLY_EDITOR_MODES.REPLY,
      hasSlashCommand: false,
      doAutoSaveDraft: () => {},
      updateEditorSelectionWith: '',
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      messageSignature: 'getMessageSignature',
    }),
    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.currentChat.meta.sender.id
      );
    },
    showRichContentEditor() {
      return true;
    },
    isPrivate() {
      // if the current chat is not loaded, assume we can reply
      // this avoids rendering the editor with is-private yellow bg
      // optimisitaclly defaulting to reply editor
      if (!this.currentChat || !Object.keys(this.currentChat).length) {
        return false;
      }

      if (this.currentChat.can_reply) {
        return this.isOnPrivateNote;
      }

      return true;
    },
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    messagePlaceHolder() {
      return this.isPrivate
        ? this.$t('CONVERSATION.FOOTER.PRIVATE_MSG_INPUT')
        : this.$t('CONVERSATION.FOOTER.MSG_INPUT');
    },
    isMessageLengthReachingThreshold() {
      return this.message.length > this.maxLength - 50;
    },
    charactersRemaining() {
      return this.maxLength - this.message.length;
    },
    isReplyButtonDisabled() {
      if (this.hasAttachments || this.hasRecordedAudio) return false;

      return (
        this.isMessageEmpty ||
        this.message.length === 0 ||
        this.message.length > this.maxLength
      );
    },
    sender() {
      return {
        name: this.currentUser.name,
        thumbnail: this.currentUser.avatar_url,
      };
    },
    conversationType() {
      const { additional_attributes: additionalAttributes } = this.currentChat;
      const type = additionalAttributes ? additionalAttributes.type : '';
      return type || '';
    },
    maxLength() {
      return MESSAGE_MAX_LENGTH.GENERAL;
    },
    isEditorDisabled() {
      // eslint-disable-next-line no-underscore-dangle
      return window.__DISABLE_EDITOR__;
    },
    allowFileUpload() {
      // eslint-disable-next-line no-underscore-dangle
      return window.__EDITOR_DISABLE_UPLOAD__ !== true;
    },
    replyButtonLabel() {
      if (this.isPrivate) {
        return this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      return this.$t('CONVERSATION.REPLYBOX.SEND');
    },
    replyBoxClass() {
      return {
        'is-private': this.isPrivate,
        'is-focused': this.isFocused || this.hasAttachments,
        'pointer-events-none grayscale opacity-70': this.isEditorDisabled,
      };
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    isOnPrivateNote() {
      return this.replyType === REPLY_EDITOR_MODES.NOTE;
    },
    isOnExpandedLayout() {
      return false;
    },
    isMessageEmpty() {
      if (!this.message) {
        return true;
      }
      return !this.message.trim().replace(/\n/g, '').length;
    },
    showReplyHead() {
      return !this.isOnPrivateNote;
    },
    enableMultipleFileUpload() {
      return true;
    },
    editorMessageKey() {
      const { editor_message_key: isEnabled } = this.uiSettings;
      return isEnabled;
    },
    conversationId() {
      return this.currentChat.id;
    },
    editorStateId() {
      return `draft-${this.conversationId}-${this.replyType}`;
    },
    signatureToApply() {
      return this.showRichContentEditor
        ? this.messageSignature
        : extractTextFromMarkdown(this.messageSignature);
    },
  },
  mounted() {
    document.addEventListener('paste', this.onPaste);
    document.addEventListener('keydown', this.handleKeyEvents);

    // // A hacky fix to solve the drag and drop
    // // Is showing on top of new conversation modal drag and drop
    // // TODO need to find a better solution
    // emitter.on(
    //   BUS_EVENTS.NEW_CONVERSATION_MODAL,
    //   this.onNewConversationModalActive
    // );
    // emitter.on(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, this.addIntoEditor);
  },
  unmounted() {
    document.removeEventListener('paste', this.onPaste);
    document.removeEventListener('keydown', this.handleKeyEvents);
  },
  methods: {
    getElementToBind() {
      return this.replyEditor;
    },
    onPaste(e) {
      const data = e.clipboardData.files;
      if (!this.showRichContentEditor && data.length !== 0) {
        this.$refs.messageInput.$el.blur();
      }
      if (!data.length || !data[0]) {
        return;
      }
      data.forEach(file => {
        const { name, type, size } = file;
        this.onFileUpload({ name, type, size, file: file });
      });
    },
    confirmOnSendReply() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showMentions) {
        const messagePayload = this.getMessagePayload(this.message);
        this.sendMessage(messagePayload);
        this.clearMessage();
      }
    },
    async onSendReply() {
      this.confirmOnSendReply();
    },
    async sendMessage(messagePayload) {
      try {
        await this.$store.dispatch(
          'createPendingMessageAndSend',
          messagePayload
        );
        // emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        // emitter.emit(BUS_EVENTS.MESSAGE_SENT);
      } catch (error) {
        const errorMessage =
          error?.response?.data?.error || this.$t('CONVERSATION.MESSAGE_ERROR');
        useAlert(errorMessage);
      }
    },
    setReplyMode(mode = REPLY_EDITOR_MODES.REPLY) {
      const { can_reply: canReply } = this.currentChat;
      this.$store.dispatch('draftMessages/setReplyEditorMode', {
        mode,
      });
      if (canReply) this.replyType = mode;

      this.$nextTick(() => {
        // This block addresses a scrolling issue on iOS Safari when the virtual
        // keyboard opens and can obscure the focused ProseMirror editor.
        // This behavior is primarily an iOS Safari quirk related to how it handles
        // the viewport with the virtual keyboard. It's not something we
        //  directly control or can easily fix at the component levels.
        //
        // `this.$nextTick()`: Ensures this code runs after Vue has finished its
        // DOM update cycle. This is crucial if the editor's visibility or focus
        // was just programmatically changed, guaranteeing we operate on the
        // finalized DOM.
        //
        // `setTimeout(() => { ... }, 300)`: A delay is necessary because iOS
        // Safari needs time for the virtual keyboard to fully animate into view
        // and for the page layout to adjust. Attempting to scroll immediately
        // (even after $nextTick) often fails as the keyboard isn't yet fully
        // present or the viewport dimensions haven't updated. The 300ms is a
        // common heuristic.
        //
        // The `scrollIntoView()` method then attempts to bring the editor
        // into the visible part of the viewport. This manual scroll is a
        // pragmatic workaround for this specific iOS Safari behavior.
        setTimeout(() => {
          document.querySelector('.ProseMirror')?.scrollIntoView();
        }, 300);
      });

      if (this.showRichContentEditor) {
        if (this.isRecordingAudio) {
          this.toggleAudioRecorder();
        }
        return;
      }
      this.$nextTick(() => this.$refs.messageInput.focus());
    },
    clearEditorSelection() {
      this.updateEditorSelectionWith = '';
    },
    insertIntoTextEditor(text, selectionStart, selectionEnd) {
      const { message } = this;
      const newMessage =
        message.slice(0, selectionStart) +
        text +
        message.slice(selectionEnd, message.length);
      this.message = newMessage;
    },
    addIntoEditor(content) {
      if (this.showRichContentEditor) {
        this.updateEditorSelectionWith = content;
        this.onFocus();
      }
      if (!this.showRichContentEditor) {
        const { selectionStart, selectionEnd } = this.$refs.messageInput.$el;
        this.insertIntoTextEditor(content, selectionStart, selectionEnd);
      }
    },
    clearMessage() {
      this.message = '';
      this.attachedFiles = [];
      this.isRecordingAudio = false;
    },
    onTypingOn() {
      this.toggleTyping('on');
    },
    onTypingOff() {
      this.toggleTyping('off');
    },
    onBlur() {
      this.isFocused = false;
    },
    onFocus() {
      this.isFocused = true;
    },
    toggleTyping(status) {
      const conversationId = this.currentChat.id;
      const isPrivate = this.isPrivate;

      if (!conversationId) {
        return;
      }

      this.$store.dispatch('conversationTypingStatus/toggleTyping', {
        status,
        conversationId,
        isPrivate,
      });
    },
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          currentChatId: this.currentChat.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
          isRecordedAudio: file?.isRecordedAudio || false,
        });
      };
    },
    removeAttachment(attachments) {
      this.attachedFiles = attachments;
    },
    setReplyToInPayload(payload) {
      if (this.inReplyTo?.id) {
        return {
          ...payload,
          contentAttributes: {
            ...payload.contentAttributes,
            in_reply_to: this.inReplyTo.id,
          },
        };
      }

      return payload;
    },
    getMessagePayload(message) {
      let messagePayload = {
        conversationId: this.currentChat.id,
        message,
        private: this.isPrivate,
        sender: this.sender,
      };
      messagePayload = this.setReplyToInPayload(messagePayload);

      if (this.attachedFiles && this.attachedFiles.length) {
        messagePayload.files = [];
        this.attachedFiles.forEach(attachment => {
          if (this.globalConfig.directUploadsEnabled) {
            messagePayload.files.push(attachment.blobSignedId);
          } else {
            messagePayload.files.push(attachment.resource.file);
          }
        });
      }
      return messagePayload;
    },
    getKeyboardEvents() {
      return {
        '$mod+Enter': {
          action: this.onSendReply,
          allowOnFocusedInput: true,
        },
      };
    },
  },
};
</script>

<template>
  <div ref="replyEditor" class="reply-box" :class="replyBoxClass">
    <ReplyTopPanel
      :mode="replyType"
      disable-popout
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
      @set-reply-mode="setReplyMode"
    />
    <div class="reply-box__top">
      <WootMessageEditor
        v-model="message"
        :editor-id="editorStateId"
        :disabled="isEditorDisabled"
        class="input"
        :is-private="isOnPrivateNote"
        :placeholder="messagePlaceHolder"
        :update-selection-with="updateEditorSelectionWith"
        :min-height="4"
        enable-variables
        :variables="messageVariables"
        :signature="signatureToApply"
        allow-signature
        :channel-type="channelType"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
        @toggle-user-mention="toggleUserMention"
        @toggle-canned-menu="toggleCannedMenu"
        @toggle-variables-menu="toggleVariablesMenu"
        @clear-selection="clearEditorSelection"
      />
    </div>
    <div
      v-if="hasAttachments && !showAudioRecorderEditor"
      class="attachment-preview-box"
      @paste="onPaste"
    >
      <AttachmentPreview
        class="flex-col mt-4"
        :attachments="attachedFiles"
        @remove-attachment="removeAttachment"
      />
    </div>
    <ReplyBottomPanel
      :conversation-id="conversationId"
      :inbox="inbox"
      :is-on-private-note="isOnPrivateNote"
      :is-send-disabled="isReplyButtonDisabled"
      :mode="replyType"
      :on-file-upload="onFileUpload"
      :on-send="onSendReply"
      :conversation-type="conversationType"
      :send-button-text="replyButtonLabel"
      :show-audio-recorder="showAudioRecorder"
      :show-editor-toggle="isAPIInbox && !isOnPrivateNote"
      :show-emoji-picker="false"
      :show-file-upload="allowFileUpload"
      :message="message"
      :enable-multiple-file-upload="allowFileUpload"
      :allow-file-upload="allowFileUpload"
      allow-signature
    />
  </div>
</template>

<style lang="scss" scoped>
.send-button {
  @apply mb-0;
}

.banner--self-assign {
  @apply py-2;
}

.attachment-preview-box {
  @apply bg-transparent py-0 px-4;
}

.reply-box {
  transition: height 2s cubic-bezier(0.37, 0, 0.63, 1);

  @apply relative mb-2 mx-2 border border-n-weak rounded-xl bg-n-solid-1;

  &.is-private {
    @apply bg-n-solid-amber dark:border-n-amber-3/10 border-n-amber-12/5;
  }
}

/* in safari the list marker is truncated */
/* We could add, the following, but in Safari, it behaves weirdly with the curosr */
/* ::v-deep .ProseMirror li {
  list-style-position: inside !important;
} */

@supports (-webkit-hyphens: none) {
  ::v-deep .ProseMirror ul {
    margin-left: 2ch !important;
  }

  ::v-deep .ProseMirror ol {
    margin-left: 2ch !important;
  }
}

.send-button {
  @apply mb-0;
}

.reply-box__top {
  @apply relative py-0 px-4 -mt-px;

  textarea {
    @apply shadow-none outline-none border-transparent bg-transparent m-0 max-h-60 min-h-[3rem] pt-4 pb-0 px-0 resize-none;
  }
}

.emoji-dialog {
  @apply top-[unset] -bottom-10 -left-80 right-[unset];

  &::before {
    transform: rotate(270deg);
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
    @apply -right-4 bottom-2 rtl:right-0 rtl:-left-4;
  }
}

.emoji-dialog--rtl {
  @apply left-[unset] -right-80;

  &::before {
    transform: rotate(90deg);
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
  }
}

.emoji-dialog--expanded {
  @apply left-[unset] bottom-0 absolute z-[100];

  &::before {
    transform: rotate(0deg);
    @apply left-1 -bottom-2;
  }
}

.normal-editor__canned-box {
  width: calc(100% - 2 * var(--space-normal));
  left: var(--space-normal);
}
</style>
