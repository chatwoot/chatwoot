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
      if (this.currentChat.can_reply || this.isAWhatsAppChannel) {
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
    showFileUpload() {
      return true;
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
      this.resetReplyToMessage();
      this.resetAudioRecorderInput();
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
      enable-multiple-file-upload
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
      :show-file-upload="showFileUpload"
      :message="message"
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
