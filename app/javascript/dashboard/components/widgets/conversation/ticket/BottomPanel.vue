<template>
  <div class="bottom-box" :class="wrapClass">
    <div class="left-wrap pb-2 pl-2" v-if="isPreleaseEnabled">
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :class="emojiDialogClassOnExpandedLayoutAndRTLView"
        :on-click="addIntoEditor"
      />
      <woot-button
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        :title="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        icon="emoji"
        emoji="😊"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        @click="toggleEmojiPicker"
      />

      <file-upload
        ref="uploadTicketAttachments"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
        input-id="ticketAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        :multiple="enableMultipleFileUpload"
        :drop="enableDragAndDrop"
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        @input-file="onFileUpload"
      >
        <woot-button
          class-names="button--upload"
          :title="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          icon="attach"
          emoji="📎"
          color-scheme="secondary"
          variant="smooth"
          size="small"
        />
      </file-upload>

      <woot-button
        v-if="showMessageSignatureButton"
        v-tooltip.top-end="signatureToggleTooltip"
        icon="signature"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        :title="signatureToggleTooltip"
        @click="toggleMessageSignature"
      />
      
    </div>
    <div class="float-right mt-5">
      <woot-button
        size="small"
        @click="createWithResponse"
      >
      {{ $t('TICKET.CREATE.WITH_RESPONSE') }}
      </woot-button>
      <woot-button
        size="small"
        color-scheme="success"
        @click="createAndSolve"
      >
        {{ $t('TICKET.CREATE.AND_SOLVE') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import FileUpload from 'vue-upload-component';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import { mapGetters } from 'vuex';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
const EmojiInput = () => import('shared/components/emoji/EmojiInput');
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export default {
  mixins: [fileUploadMixin, uiSettingsMixin],
  components: {
    EmojiInput,
    FileUpload,
  },
  props: {
    wrapClass: {
      type: String,
      default: '',
    },
    isPrivate: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showEmojiPicker: false,
      enableMultipleFileUpload: true,
      enableDragAndDrop: true,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentAccountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    isPreleaseEnabled() {
      return this.isFeatureEnabledonAccount(
        this.currentAccountId,
        FEATURE_FLAGS.PRE_RELEASE_FEATURE
      );
    },
    emojiDialogClassOnExpandedLayoutAndRTLView() {
      return 'emoji-dialog--expanded';
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUiSettings(this.channelType);
    },
    channelType() {
      return 'Channel::Email';
    },
    showMessageSignatureButton() {
      return !this.isPrivate;
    },
  },
  methods: {
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    hideEmojiPicker() {
      this.showEmojiPicker = false;
    },
    addIntoEditor(emoji) {
      this.$emit('add-emoji', emoji);
      this.hideEmojiPicker();
    },
    createAndSolve() {
      this.$emit('create-and-solve');
    },
    createWithResponse() {
      this.$emit('create-with-response');
    },
    attachFile({ file, blob}) {
      this.$emit('attach-file', { file, blob });
    },
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
      this.$emit('toggle-signature', !this.sendWithSignature);
    },
  },
};
</script>

<style scoped>
  .left-wrap{
    position: relative;
  }
  .emoji-dialog{
    bottom: 60px;
    left: 0;
    top: unset;
  }
  .file-uploads{
    overflow: inherit;
  }
  .file-uploads label{
    cursor: pointer;
  }
</style>