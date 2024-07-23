<template>
  <form class="w-full conversation--form" @submit.prevent="onFormSubmit">
    <div
      v-if="showNoInboxAlert"
      class="relative mx-0 mt-0 mb-2.5 p-2 rounded-none text-sm border border-solid border-yellow-500 dark:border-yellow-700 bg-yellow-200/60 dark:bg-yellow-200/20 text-slate-700 dark:text-yellow-400"
    >
      <p class="mb-0">
        {{ $t('NEW_CONVERSATION.NO_INBOX') }}
      </p>
    </div>
    <div v-else>
      <div class="flex flex-row gap-2">
        <div class="w-[50%]">
          <label>
            {{ $t('NEW_CONVERSATION.FORM.INBOX.LABEL') }}
          </label>
          <div
            class="multiselect-wrap--small"
            :class="{ 'has-multi-select-error': $v.targetInbox.$error }"
          >
            <multiselect
              v-model="targetInbox"
              track-by="id"
              label="name"
              :placeholder="$t('FORMS.MULTISELECT.SELECT')"
              selected-label=""
              select-label=""
              deselect-label=""
              :max-height="160"
              :close-on-select="true"
              :options="[...inboxes]"
            >
              <template slot="singleLabel" slot-scope="{ option }">
                <inbox-dropdown-item
                  v-if="option.name"
                  :name="option.name"
                  :inbox-identifier="computedInboxSource(option)"
                  :channel-type="option.channel_type"
                />
                <span v-else>
                  {{ $t('NEW_CONVERSATION.FORM.INBOX.PLACEHOLDER') }}
                </span>
              </template>
              <template slot="option" slot-scope="{ option }">
                <inbox-dropdown-item
                  :name="option.name"
                  :inbox-identifier="computedInboxSource(option)"
                  :channel-type="option.channel_type"
                />
              </template>
            </multiselect>
          </div>
          <label :class="{ error: $v.targetInbox.$error }">
            <span v-if="$v.targetInbox.$error" class="message">
              {{ $t('NEW_CONVERSATION.FORM.INBOX.ERROR') }}
            </span>
          </label>
        </div>
        <div class="w-[50%]">
          <label>
            {{ $t('NEW_CONVERSATION.FORM.TO.LABEL') }}
            <div
              class="flex items-center h-[2.4735rem] rounded-sm py-1 px-2 bg-slate-25 dark:bg-slate-900 border border-solid border-slate-75 dark:border-slate-600"
            >
              <thumbnail
                :src="contact.thumbnail"
                size="24px"
                :username="contact.name"
                :status="contact.availability_status"
              />
              <h4
                class="m-0 ml-2 mr-2 text-sm text-slate-700 dark:text-slate-100"
              >
                {{ contact.name }}
              </h4>
            </div>
          </label>
        </div>
      </div>
      <div v-if="isAnEmailInbox" class="w-full">
        <div class="w-full">
          <label :class="{ error: $v.subject.$error }">
            {{ $t('NEW_CONVERSATION.FORM.SUBJECT.LABEL') }}
            <input
              v-model="subject"
              type="text"
              :placeholder="$t('NEW_CONVERSATION.FORM.SUBJECT.PLACEHOLDER')"
              @input="$v.subject.$touch"
            />
            <span v-if="$v.subject.$error" class="message">
              {{ $t('NEW_CONVERSATION.FORM.SUBJECT.ERROR') }}
            </span>
          </label>
        </div>
      </div>
      <div class="w-full">
        <div class="w-full">
          <div class="relative">
            <canned-response
              v-if="showCannedResponseMenu && hasSlashCommand"
              :search-key="cannedResponseSearchKey"
              @click="replaceTextWithCannedResponse"
            />
          </div>
          <div v-if="isEmailOrWebWidgetInbox">
            <label>
              {{ $t('NEW_CONVERSATION.FORM.MESSAGE.LABEL') }}
            </label>
            <reply-email-head
              v-if="isAnEmailInbox"
              :cc-emails.sync="ccEmails"
              :bcc-emails.sync="bccEmails"
            />
            <div class="editor-wrap">
              <woot-message-editor
                v-model="message"
                class="message-editor"
                :class="{ editor_warning: $v.message.$error }"
                :enable-variables="true"
                :signature="signatureToApply"
                :allow-signature="true"
                :placeholder="$t('NEW_CONVERSATION.FORM.MESSAGE.PLACEHOLDER')"
                @toggle-canned-menu="toggleCannedMenu"
                @blur="$v.message.$touch"
              >
                <template #footer>
                  <message-signature-missing-alert
                    v-if="isSignatureEnabledForInbox && !messageSignature"
                    class="!mx-0 mb-1"
                  />
                  <div v-if="isAnEmailInbox" class="mt-px mb-3">
                    <woot-button
                      v-tooltip.top-end="signatureToggleTooltip"
                      icon="signature"
                      color-scheme="secondary"
                      variant="smooth"
                      size="small"
                      :title="signatureToggleTooltip"
                      @click.prevent="toggleMessageSignature"
                    />
                  </div>
                </template>
              </woot-message-editor>
              <span v-if="$v.message.$error" class="editor-warning__message">
                {{ $t('NEW_CONVERSATION.FORM.MESSAGE.ERROR') }}
              </span>
            </div>
          </div>
          <whatsapp-templates
            v-else-if="hasWhatsappTemplates"
            :inbox-id="selectedInbox.inbox.id"
            @on-select-template="toggleWaTemplate"
            @on-send="onSendWhatsAppReply"
          />
          <label v-else :class="{ error: $v.message.$error }">
            {{ $t('NEW_CONVERSATION.FORM.MESSAGE.LABEL') }}
            <textarea
              v-model="message"
              class="min-h-[5rem]"
              type="text"
              :placeholder="$t('NEW_CONVERSATION.FORM.MESSAGE.PLACEHOLDER')"
              @input="$v.message.$touch"
            />
            <span v-if="$v.message.$error" class="message">
              {{ $t('NEW_CONVERSATION.FORM.MESSAGE.ERROR') }}
            </span>
          </label>
          <div v-if="isEmailOrWebWidgetInbox" class="flex flex-col">
            <file-upload
              ref="uploadAttachment"
              input-id="newConversationAttachment"
              :size="4096 * 4096"
              :accept="allowedFileTypes"
              :multiple="true"
              :drop="true"
              :drop-directory="false"
              :data="{
                direct_upload_url: '/rails/active_storage/direct_uploads',
                direct_upload: true,
              }"
              @input-file="onFileUpload"
            >
              <woot-button
                class-names="button--upload"
                icon="attach"
                emoji="📎"
                color-scheme="secondary"
                variant="smooth"
                size="small"
              >
                {{ $t('NEW_CONVERSATION.FORM.ATTACHMENTS.SELECT') }}
              </woot-button>
              <span
                class="text-xs font-medium text-slate-500 ltr:ml-1 rtl:mr-1 dark:text-slate-400"
              >
                {{ $t('NEW_CONVERSATION.FORM.ATTACHMENTS.HELP_TEXT') }}
              </span>
            </file-upload>
            <div
              v-if="hasAttachments"
              class="max-h-20 overflow-y-auto mb-4 mt-1.5"
            >
              <attachment-preview
                class="[&>.preview-item]:dark:bg-slate-700 flex-row flex-wrap gap-x-3 gap-y-1"
                :attachments="attachedFiles"
                :remove-attachment="removeAttachment"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="!hasWhatsappTemplates"
      class="flex flex-row justify-end w-full gap-2 px-0 py-2"
    >
      <button class="button clear" @click.prevent="onCancel">
        {{ $t('NEW_CONVERSATION.FORM.CANCEL') }}
      </button>
      <woot-button type="submit" :is-loading="conversationsUiFlags.isCreating">
        {{ $t('NEW_CONVERSATION.FORM.SUBMIT') }}
      </woot-button>
    </div>

    <transition v-if="isEmailOrWebWidgetInbox" name="modal-fade">
      <div
        v-show="$refs.uploadAttachment && $refs.uploadAttachment.dropActive"
        class="absolute top-0 bottom-0 left-0 right-0 z-30 flex flex-col items-center justify-center w-full h-full gap-2 bg-white/80 dark:bg-slate-700/80"
      >
        <fluent-icon icon="cloud-backup" size="40" />
        <h4 class="text-2xl break-words text-slate-600 dark:text-slate-200">
          {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
        </h4>
      </div>
    </transition>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ReplyEmailHead from 'dashboard/components/widgets/conversation/ReplyEmailHead.vue';
import CannedResponse from 'dashboard/components/widgets/conversation/CannedResponse.vue';
import MessageSignatureMissingAlert from 'dashboard/components/widgets/conversation/MessageSignatureMissingAlert';
import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';
import WhatsappTemplates from './WhatsappTemplates.vue';
import { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { getInboxSource } from 'dashboard/helper/inbox';
import { required, requiredIf } from 'vuelidate/lib/validators';
import inboxMixin from 'shared/mixins/inboxMixin';
import FileUpload from 'vue-upload-component';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';

export default {
  components: {
    Thumbnail,
    WootMessageEditor,
    ReplyEmailHead,
    CannedResponse,
    WhatsappTemplates,
    InboxDropdownItem,
    FileUpload,
    AttachmentPreview,
    MessageSignatureMissingAlert,
  },
  mixins: [inboxMixin, fileUploadMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
    channelType: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { fetchSignatureFlagFromUISettings, setSignatureFlagForInbox } =
      useUISettings();

    return {
      fetchSignatureFlagFromUISettings,
      setSignatureFlagForInbox,
    };
  },
  data() {
    return {
      name: '',
      subject: '',
      message: '',
      showCannedResponseMenu: false,
      cannedResponseSearchKey: '',
      bccEmails: '',
      ccEmails: '',
      targetInbox: {},
      whatsappTemplateSelected: false,
      attachedFiles: [],
    };
  },
  validations: {
    subject: {
      required: requiredIf('isAnEmailInbox'),
    },
    message: {
      required,
    },
    targetInbox: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      conversationsUiFlags: 'contactConversations/getUIFlags',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      messageSignature: 'getMessageSignature',
    }),
    sendWithSignature() {
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    signatureToApply() {
      return this.messageSignature;
    },
    newMessagePayload() {
      const payload = {
        inboxId: this.targetInbox.id,
        sourceId: this.targetInbox.sourceId,
        contactId: this.contact.id,
        message: { content: this.message },
        mailSubject: this.subject,
        assigneeId: this.currentUser.id,
      };

      if (this.attachedFiles && this.attachedFiles.length) {
        payload.files = [];
        this.setAttachmentPayload(payload);
      }

      if (this.ccEmails) {
        payload.message.cc_emails = this.ccEmails;
      }

      if (this.bccEmails) {
        payload.message.bcc_emails = this.bccEmails;
      }
      return payload;
    },
    selectedInbox: {
      get() {
        const inboxList = this.contact.contactableInboxes || [];
        return (
          inboxList.find(inbox => {
            return inbox.inbox?.id && inbox.inbox?.id === this.targetInbox?.id;
          }) || {
            inbox: {},
          }
        );
      },
      set(value) {
        this.targetInbox = value.inbox;
      },
    },
    showNoInboxAlert() {
      if (!this.contact.contactableInboxes) {
        return false;
      }
      return this.inboxes.length === 0 && !this.uiFlags.isFetchingInboxes;
    },
    isSignatureEnabledForInbox() {
      return this.isAnEmailInbox && this.sendWithSignature;
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    inboxes() {
      const inboxList = this.contact.contactableInboxes || [];
      return inboxList.map(inbox => ({
        ...inbox.inbox,
        sourceId: inbox.source_id,
      }));
    },
    isAnEmailInbox() {
      return (
        this.selectedInbox &&
        this.selectedInbox.inbox.channel_type === INBOX_TYPES.EMAIL
      );
    },
    isAnWebWidgetInbox() {
      return (
        this.selectedInbox &&
        this.selectedInbox.inbox.channel_type === INBOX_TYPES.WEB
      );
    },
    isEmailOrWebWidgetInbox() {
      return this.isAnEmailInbox || this.isAnWebWidgetInbox;
    },
    hasWhatsappTemplates() {
      return !!this.selectedInbox.inbox?.message_templates;
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    inbox() {
      return this.targetInbox;
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
  },
  watch: {
    message(value) {
      this.hasSlashCommand = value[0] === '/' && !this.isEmailOrWebWidgetInbox;
      const hasNextWord = value.includes(' ');
      const isShortCodeActive = this.hasSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.cannedResponseSearchKey = value.substring(1);
        this.showCannedResponseMenu = true;
      } else {
        this.cannedResponseSearchKey = '';
        this.showCannedResponseMenu = false;
      }
    },
    targetInbox() {
      this.setSignature();
    },
  },
  mounted() {
    this.setSignature();
  },
  methods: {
    setSignature() {
      if (this.messageSignature) {
        if (this.isSignatureEnabledForInbox) {
          this.message = appendSignature(this.message, this.signatureToApply);
        } else {
          this.message = removeSignature(this.message, this.signatureToApply);
        }
      }
    },
    setAttachmentPayload(payload) {
      this.attachedFiles.forEach(attachment => {
        if (this.globalConfig.directUploadsEnabled) {
          payload.files.push(attachment.blobSignedId);
        } else {
          payload.files.push(attachment.resource.file);
        }
      });
    },
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          currentChatId: this.contact.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
        });
      };
    },
    removeAttachment(itemIndex) {
      this.attachedFiles = this.attachedFiles.filter(
        (item, index) => itemIndex !== index
      );
    },
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    replaceTextWithCannedResponse(message) {
      this.message = message;
    },
    toggleCannedMenu(value) {
      this.showCannedMenu = value;
    },
    prepareWhatsAppMessagePayload({ message: content, templateParams }) {
      const payload = {
        inboxId: this.targetInbox.id,
        sourceId: this.targetInbox.sourceId,
        contactId: this.contact.id,
        message: { content, template_params: templateParams },
        assigneeId: this.currentUser.id,
      };
      return payload;
    },
    onFormSubmit() {
      const isFromWhatsApp = false;
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.createConversation({
        payload: this.newMessagePayload,
        isFromWhatsApp,
      });
    },
    async createConversation({ payload, isFromWhatsApp }) {
      try {
        const data = await this.onSubmit(payload, isFromWhatsApp);
        const action = {
          type: 'link',
          to: `/app/accounts/${data.account_id}/conversations/${data.id}`,
          message: this.$t('NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
        };
        this.onSuccess();
        useAlert(this.$t('NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'), action);
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(this.$t('NEW_CONVERSATION.FORM.ERROR_MESSAGE'));
        }
      }
    },

    toggleWaTemplate(val) {
      this.whatsappTemplateSelected = val;
    },
    async onSendWhatsAppReply(messagePayload) {
      const isFromWhatsApp = true;
      const payload = this.prepareWhatsAppMessagePayload(messagePayload);
      await this.createConversation({ payload, isFromWhatsApp });
    },
    inboxReadableIdentifier(inbox) {
      return `${inbox.name} (${inbox.channel_type})`;
    },
    computedInboxSource(inbox) {
      if (!inbox.channel_type) return '';
      const classByType = getInboxSource(
        inbox.channel_type,
        inbox.phone_number,
        inbox
      );
      return classByType;
    },
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
      this.setSignature();
    },
  },
};
</script>

<style scoped lang="scss">
.conversation--form {
  @apply pt-4 px-8 pb-8;
}

.message-editor {
  @apply px-3;

  ::v-deep {
    .ProseMirror-menubar {
      @apply rounded-tl-[4px];
    }
  }
}

.file-uploads {
  @apply text-start;
}
.multiselect-wrap--small.has-multi-select-error {
  ::v-deep {
    .multiselect__tags {
      @apply border-red-500;
    }
  }
}

::v-deep {
  .mention--box {
    @apply left-0 m-auto right-0 top-auto h-fit;
  }
  .multiselect .multiselect__content .multiselect__option span {
    @apply inline-flex w-6 text-slate-600 dark:text-slate-400;
  }
  .multiselect .multiselect__content .multiselect__option {
    @apply py-0.5 px-1;
  }
}
</style>
