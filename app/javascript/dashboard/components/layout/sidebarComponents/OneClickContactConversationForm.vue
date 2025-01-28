<template>
  <div>
    <div class="pt-4 pb-4 px-8">
      <div
        class="mb-2 flex flex-col gap-1 bg-slate-50 dark:bg-slate-700 rounded-md px-4 py-5 max-h-72 overflow-y-scroll relative"
      >
        <div
          v-for="(contact, index) in contacts"
          :key="index"
          class="flex justify-center items-center gap-4 py-4 border-b border-b-slate-100"
        >
          <!-- Contact Icon -->
          <div
            class="flex items-center justify-center w-8 h-8 bg-slate-200 dark:bg-slate-700 rounded-full"
          >
            <fluent-icon icon="person" class="text-gray-500" />
          </div>

          <!-- Inputs or Saved Contact -->
          <div v-if="contact.editing" class="flex flex-1 gap-4 h-8">
            <!-- Email Input -->
            <div class="relative flex-1">
              <input
                v-model="contact.email"
                type="email"
                :placeholder="emailPlaceholder"
                class="border border-gray-300 rounded !px-2 !py-0.5 !mb-0 !text-sm !h-8"
                :class="{ '!border-red-500': contact.errors.email }"
              />
              <span
                v-if="contact.errors.email"
                class="absolute -bottom-4 right-0 left-0 text-red-500 text-xs pl-1"
              >
                {{ contact.errors.email }}
              </span>
            </div>
            <!-- Phone Input -->
            <div class="relative flex-1">
              <phone-input
                v-model="contact.phone_number"
                :placeholder="phoneNoPlaceHolder"
                :error="!!contact.errors.phone_number"
                :value="contact.phone_number"
                @input="
                  (value, activeDialCode) =>
                    onPhoneNumberInputChange(value, activeDialCode, index)
                "
                @setCode="code => setPhoneCode(code, index)"
              />
              <!-- <input
                v-model="contact.phone_number"
                type="text"
                :placeholder="phoneNoPlaceHolder"
                class="border border-gray-300 rounded !px-2 !py-0.5 !mb-0 !text-sm !h-8"
                :class="{ '!border-red-500': contact.errors.phone_number }"
              /> -->
              <span
                v-if="contact.errors.phone_number"
                class="absolute -bottom-4 right-0 left-0 text-red-500 text-xs pl-1"
              >
                {{ contact.errors.phone_number }}
              </span>
            </div>
            <!-- Name Input -->
            <div class="relative flex-1">
              <input
                v-model="contact.name"
                type="text"
                placeholder="Name (Optional)"
                class="border border-gray-300 rounded !px-2 !py-0.5 !mb-0 !text-sm !h-8"
                :class="{ '!border-red-500': contact.errors.name }"
              />
              <span
                v-if="contact.errors.name"
                class="absolute -bottom-4 right-0 left-0 text-red-500 text-xs pl-1"
              >
                {{ contact.errors.name }}
              </span>
            </div>
          </div>

          <!-- Saved Contact -->
          <div v-else class="flex flex-1 items-center gap-4 h-8">
            <p class="flex-1 !mb-0">{{ contact.email || '-' }}</p>
            <p class="flex-1 !mb-0">{{ contact.phone_number || '-' }}</p>
            <p class="flex-1 !mb-0">{{ contact.name || '-' }}</p>
          </div>

          <!-- Action Buttons -->
          <div class="flex items-center gap-2">
            <woot-button
              v-if="contact.editing"
              variant="smooth"
              class="p-1 h-7 w-7 flex justify-center items-center text-white rounded"
              @click="saveContact(index)"
            >
              <fluent-icon icon="checkmark" class="text-gray-500" />
            </woot-button>
            <button
              v-if="contact.editing"
              class="p-1 h-7 w-7 flex justify-center items-center bg-red-100 text-red-800 rounded hover:bg-red-300"
              @click="cancelEdit(index)"
            >
              <fluent-icon icon="dismiss" class="text-gray-500" />
            </button>
            <woot-button
              v-else
              variant="smooth"
              class="p-1 h-7 w-7 flex justify-center items-center text-white rounded"
              @click="editContact(index)"
            >
              <fluent-icon icon="edit" class="text-gray-500" />
            </woot-button>
            <button
              v-if="!contact.editing"
              class="p-1 h-7 w-7 flex justify-center items-center bg-red-100 text-red-800 rounded hover:bg-red-300"
              @click="removeContact(index)"
            >
              <fluent-icon icon="delete" class="text-gray-500" />
            </button>
          </div>
        </div>
      </div>
      <woot-button
        variant="smooth"
        icon="add"
        class="w-full flex justify-center items-center border border-slate-100 dark:border-slate-700 border-dashed px-4 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
        @click="addNewContact"
      >
        Add New Contact
      </woot-button>
    </div>
    <div class="conversation--form w-full">
      <div
        v-if="showNoInboxAlert"
        class="relative mx-0 mt-0 mb-2.5 p-2 rounded-none text-sm border border-solid border-yellow-500 dark:border-yellow-700 bg-yellow-200/60 dark:bg-yellow-200/20 text-slate-700 dark:text-yellow-400"
      >
        <p class="mb-0">
          {{ $t('NEW_CONVERSATION.NO_INBOX') }}
        </p>
      </div>
      <div
        v-if="showNoEmailInboxAlert"
        class="relative mx-0 mt-0 mb-2.5 p-2 rounded-none text-sm border border-solid border-yellow-500 dark:border-yellow-700 bg-yellow-200/60 dark:bg-yellow-200/20 text-slate-700 dark:text-yellow-400"
      >
        <p class="mb-0">
          {{
            'No email inbox found. Please create an email inbox before creating an email conversation.'
          }}
        </p>
      </div>
      <div v-else>
        <div v-if="isAnEmailInbox" class="w-full">
          <div class="w-full">
            <label :class="{ error: $v.subject.$error }">
              {{ $t('NEW_CONVERSATION.FORM.SUBJECT.LABEL') }}
              <input
                v-model="subject"
                type="text"
                :placeholder="$t('NEW_CONVERSATION.FORM.SUBJECT.PLACEHOLDER')"
                class="!mt-1"
                @input="$v.subject.$touch"
              />
              <span v-if="$v.subject.$error" class="message">
                {{ $t('NEW_CONVERSATION.FORM.SUBJECT.ERROR') }}
              </span>
            </label>
          </div>
        </div>
        <div class="w-full">
          <div
            class="w-full"
            :class="{
              'flex flex-col-reverse': hasWhatsappTemplates,
              'gap-3': hasWhatsappTemplates && !hasAttachments,
            }"
          >
            <div class="relative">
              <canned-response
                v-if="showCannedResponseMenu && hasSlashCommand"
                :search-key="cannedResponseSearchKey"
                @click="replaceTextWithCannedResponse"
              />
            </div>
            <div v-if="isEmailOrWebWidgetInbox" class="mb-2">
              <label>
                {{ $t('NEW_CONVERSATION.FORM.MESSAGE.LABEL') }}
              </label>
              <div
                class="bg-white dark:bg-slate-900 px-3 py-1 border border-solid border-slate-200 dark:border-slate-600 mt-1"
              >
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
                    :placeholder="
                      $t('NEW_CONVERSATION.FORM.MESSAGE.PLACEHOLDER')
                    "
                    :min-height="4"
                    @toggle-canned-menu="toggleCannedMenu"
                    @blur="$v.message.$touch"
                  >
                    <template #footer>
                      <message-signature-missing-alert
                        v-if="isSignatureEnabledForInbox && !messageSignature"
                        class="!mx-0 mb-1"
                      />
                      <div v-if="isAnEmailInbox" class="flex mb-3 mt-px gap-3">
                        <woot-button
                          v-tooltip.top-end="signatureToggleTooltip"
                          icon="signature"
                          color-scheme="secondary"
                          variant="smooth"
                          size="small"
                          :title="signatureToggleTooltip"
                          @click="toggleMessageSignature"
                        />
                        <file-upload
                          ref="uploadAttachment"
                          v-tooltip.top-end="
                            $t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')
                          "
                          input-id="newConversationAttachment"
                          :size="4096 * 4096"
                          :accept="allowedFileTypes"
                          :multiple="true"
                          :drop="true"
                          :drop-directory="false"
                          :data="{
                            direct_upload_url:
                              '/rails/active_storage/direct_uploads',
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
                      </div>
                    </template>
                  </woot-message-editor>
                  <span
                    v-if="$v.message.$error"
                    class="editor-warning__message"
                  >
                    {{ $t('NEW_CONVERSATION.FORM.MESSAGE.ERROR') }}
                  </span>
                </div>
                <div
                  v-if="hasAttachments"
                  class="max-h-20 overflow-y-auto mb-4 mt-1.5"
                >
                  <div class="flex overflow-auto max-h-[12.5rem]">
                    <div
                      v-for="(attachment, index) in attachedFiles"
                      :key="attachment.id"
                      class="preview-item flex items-center p-1 bg-slate-50 dark:bg-slate-800 gap-1 rounded-md w-[15rem] mb-1"
                    >
                      <div
                        class="max-w-[4rem] flex-shrink-0 w-6 flex items-center"
                      >
                        <img
                          v-if="isTypeImage(attachment.resource)"
                          class="object-cover w-6 h-6 rounded-sm"
                          :src="attachment.thumb"
                        />
                        <span
                          v-else
                          class="relative w-6 h-6 text-lg text-left -top-px"
                        >
                          📄
                        </span>
                      </div>
                      <div
                        class="max-w-3/5 min-w-[50%] overflow-hidden text-ellipsis"
                      >
                        <span
                          class="h-4 overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap"
                        >
                          {{ fileName(attachment.resource) }}
                        </span>
                      </div>
                      <div class="w-[30%] justify-center">
                        <span
                          class="overflow-hidden text-xs text-ellipsis whitespace-nowrap"
                        >
                          {{ formatFileSize(attachment.resource) }}
                        </span>
                      </div>
                      <div class="flex items-center justify-center">
                        <woot-button
                          class="!w-6 !h-6 text-sm rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 clear secondary"
                          icon="dismiss"
                          @click="handleRemoveAttachment(index)"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <whatsapp-templates
              v-else-if="hasWhatsappTemplates"
              :inbox-id="selectedInbox.id"
              :remove-overflow="true"
              :validate-all-field="true"
              @on-select-template="toggleWaTemplate"
              @on-send="onSendWhatsAppReply"
            />
            <!-- <div v-if="isAnEmailInbox" class="flex flex-col">
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
                  class="text-slate-500 ltr:ml-1 rtl:mr-1 font-medium text-xs dark:text-slate-400"
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
            </div> -->
          </div>
        </div>
      </div>

      <div
        v-if="!hasWhatsappTemplates"
        class="flex flex-row justify-end gap-2 py-2 px-0 w-full"
      >
        <button class="button clear" @click="onCancel">
          {{ $t('NEW_CONVERSATION.FORM.CANCEL') }}
        </button>
        <woot-button
          :is-disabled="isAPIInbox"
          :is-loading="conversationsUiFlags.isCreating"
          @click="onFormSubmit"
        >
          {{ isAPIInbox ? 'Create Conversation' : 'Send Email' }}
        </woot-button>
      </div>

      <transition name="modal-fade">
        <div
          v-show="$refs.uploadAttachment && $refs.uploadAttachment.dropActive"
          class="flex top-0 bottom-0 z-30 gap-2 right-0 left-0 items-center justify-center flex-col absolute w-full h-full bg-white/80 dark:bg-slate-700/80"
        >
          <fluent-icon icon="cloud-backup" size="40" />
          <h4 class="text-2xl break-words text-slate-600 dark:text-slate-200">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
    </div>
  </div>
</template>

<script>
// import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import CannedResponse from 'dashboard/components/widgets/conversation/CannedResponse.vue';
import MessageSignatureMissingAlert from 'dashboard/components/widgets/conversation/MessageSignatureMissingAlert';
import ReplyEmailHead from 'dashboard/components/widgets/conversation/ReplyEmailHead.vue';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import alertMixin from 'shared/mixins/alertMixin';
import inboxMixin, { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import FileUpload from 'vue-upload-component';
import { required, requiredIf } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import WhatsappTemplates from '../../../routes/dashboard/conversation/contact/WhatsappTemplates.vue';
import AccountAPI from 'dashboard/api/account';
import parsePhoneNumber from 'libphonenumber-js';
import PhoneInput from './PhoneInput.vue';
import { formatBytes } from 'shared/helpers/FileHelper';
import { createMessagePayload } from '../../../store/modules/contactConversations';

export default {
  components: {
    WootMessageEditor,
    ReplyEmailHead,
    CannedResponse,
    WhatsappTemplates,
    FileUpload,
    // AttachmentPreview,
    MessageSignatureMissingAlert,
    PhoneInput,
  },
  mixins: [alertMixin, uiSettingsMixin, inboxMixin, fileUploadMixin],
  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    channelToCompare: {
      type: String,
      default: '',
    },
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
      whatsappTemplateSelected: false,
      attachedFiles: [],
      contacts: [
        {
          email: '',
          phone_number: '',
          name: '',
          editing: true,
          activeDialCode: '',
          errors: { email: '', phone_number: '', name: '' },
        },
      ],
    };
  },
  validations: {
    subject: {
      required: requiredIf('isAnEmailInbox'),
    },
    message: {
      required: requiredIf('!isAPIInbox'),
    },
    selectedInbox: {
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
      inboxesList: 'inboxes/getInboxes',
    }),
    emailPlaceholder() {
      return this.channelToCompare === INBOX_TYPES.EMAIL
        ? 'Email'
        : 'Email (Optional)';
    },
    phoneNoPlaceHolder() {
      return this.channelToCompare === INBOX_TYPES.API
        ? 'Phone'
        : 'Phone (Optional)';
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUiSettings(this.channelType);
    },
    signatureToApply() {
      return this.messageSignature;
    },
    newMessagePayload() {
      const payload = new FormData();
      const params = {
        inboxId: this.selectedInbox.id,
        message: {
          content: this.message,
          cc_emails: this.ccEmails,
          bcc_emails: this.bccEmails,
        },
        mailSubject: this.subject,
        contacts: this.contacts,
      };

      payload.append('inbox_id', params.inboxId);
      payload.append('mail_subject', params.mailSubject);
      payload.append('contacts', JSON.stringify(params.contacts));
      if (params.message.content) {
        createMessagePayload(payload, params.message);
      }

      if (this.attachedFiles && this.attachedFiles.length > 0) {
        this.setAttachmentPayload(payload);
      }

      return payload;
    },
    selectedInbox() {
      if (this.channelToCompare === INBOX_TYPES.API) {
        return (
          this.inboxesList.find(inbox => {
            return (
              inbox.channel_type === this.channelToCompare &&
              !!inbox?.additional_attributes?.message_templates
            );
          }) || {
            inbox: {},
          }
        );
      }
      return (
        this.inboxesList.find(inbox => {
          return inbox.channel_type === this.channelToCompare;
        }) || {
          inbox: {},
        }
      );
    },
    showNoInboxAlert() {
      return this.inboxes.length === 0 && !this.uiFlags.isFetchingInboxes;
    },
    showNoEmailInboxAlert() {
      return (
        this.inboxes.filter(inbox => inbox.channel_type === INBOX_TYPES.EMAIL)
          .length === 0 && this.channelToCompare === INBOX_TYPES.EMAIL
      );
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
      return this.inboxesList.map(inbox => ({
        ...inbox,
        sourceId: inbox.source_id,
      }));
    },
    isAnEmailInbox() {
      return (
        this.selectedInbox &&
        this.selectedInbox.channel_type === INBOX_TYPES.EMAIL
      );
    },
    isAPIInbox() {
      return (
        this.selectedInbox &&
        this.selectedInbox.channel_type === INBOX_TYPES.API
      );
    },
    isAnWebWidgetInbox() {
      return (
        this.selectedInbox &&
        this.selectedInbox.channel_type === INBOX_TYPES.WEB
      );
    },
    isEmailOrWebWidgetInbox() {
      return this.isAnEmailInbox || this.isAnWebWidgetInbox;
    },
    hasWhatsappTemplates() {
      return !!this.selectedInbox?.additional_attributes?.message_templates;
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    inbox() {
      return this.selectedInbox;
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
  },
  mounted() {
    this.setSignature();
    document.addEventListener('paste', this.onPaste);
  },
  destroyed() {
    document.removeEventListener('paste', this.onPaste);
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
    onPaste(e) {
      const data = e.clipboardData.files;
      if (!data.length || !data[0]) {
        return;
      }
      data.forEach(file => {
        const { name, type, size } = file;
        this.onFileUpload({ name, type, size, file: file });
      });
    },
    setAttachmentPayload(payload) {
      this.attachedFiles.forEach(attachment => {
        if (this.globalConfig.directUploadsEnabled) {
          payload.append('message[attachments][]', attachment.blobSignedId);
        } else {
          payload.append('message[attachments][]', attachment.resource.file);
        }
      });
    },
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
        });
      };
    },
    handleRemoveAttachment(itemIndex) {
      this.attachedFiles = this.attachedFiles.filter(
        (_, index) => index !== itemIndex
      );
    },
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    onPhoneNumberInputChange(value, code, index) {
      const contact = this.contacts[index];
      contact.activeDialCode = code;
    },
    parsePhoneNumber(phone_number) {
      return parsePhoneNumber(phone_number);
    },
    formatFileSize(file) {
      const size = file.byte_size || file.size;
      return formatBytes(size, 0);
    },
    isTypeImage(file) {
      const type = file.content_type || file.type;
      return type.includes('image');
    },
    fileName(file) {
      return file.filename || file.name;
    },
    setPhoneCode(code, index) {
      const contact = this.contacts[index];
      const parsedPhoneNumber = this.parsePhoneNumber(contact.phone_number);
      if (contact.phone_number !== '' && parsedPhoneNumber) {
        const dialCode = parsedPhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        contact.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = contact.phone_number.replace(
          `+${dialCode}`,
          `${code}`
        );
        contact.phone_number = newPhoneNumber;
      } else {
        contact.activeDialCode = code;
      }
    },
    replaceTextWithCannedResponse(message) {
      this.message = message;
    },
    toggleCannedMenu(value) {
      this.showCannedMenu = value;
    },
    prepareWhatsAppMessagePayload({ message: content, templateParams }) {
      const payload = new FormData();
      const params = {
        inboxId: this.selectedInbox.id,
        sourceId: this.selectedInbox.sourceId,
        message: {
          content,
          template_params: templateParams,
        },
        assigneeId: this.currentUser.id,
        contacts: this.contacts,
      };

      payload.append('inbox_id', params.inboxId);
      payload.append('source_id', params.sourceId);
      payload.append('message[content]', params.message.content);
      payload.append(
        'message[template_params]',
        JSON.stringify(params.message.template_params)
      );
      payload.append('contacts', JSON.stringify(params.contacts));
      payload.append('assignee_id', params.assigneeId);

      return payload;
    },
    validateContacts() {
      if (this.contacts.length === 0) {
        const message = this.isAnEmailInbox
          ? 'Please add at least one contact with an email and name.'
          : 'Please add at least one contact with a phone number and name.';
        this.showAlert(message);
        return false;
      }
      const inValidContact = this.contacts.find(contact => contact.editing);
      if (inValidContact) {
        this.showAlert('Save contact before sending the message.');
        return false;
      }
      return true;
    },
    onFormSubmit() {
      const isFromWhatsApp = false;
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      if (!this.validateContacts()) {
        return;
      }

      const payload = this.newMessagePayload;
      payload.append('isFromWhatsApp', isFromWhatsApp);
      this.createConversation(payload);
    },
    toggleWaTemplate(val) {
      this.whatsappTemplateSelected = val;
    },
    async onSendWhatsAppReply(messagePayload) {
      const isFromWhatsApp = true;
      if (!this.validateContacts()) {
        return;
      }

      const payload = this.prepareWhatsAppMessagePayload(messagePayload);
      payload.append('isFromWhatsApp', isFromWhatsApp);
      await this.createConversation(payload);
    },
    async createConversation(payload) {
      try {
        AccountAPI.createOneClickConversations(payload);
        this.onSuccess();
        this.showAlert('Conversation Created');
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('NEW_CONVERSATION.FORM.ERROR_MESSAGE'));
        }
      }
    },
    inboxReadableIdentifier(inbox) {
      return `${inbox.name} (${inbox.channel_type})`;
    },
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
      this.setSignature();
    },
    addNewContact() {
      this.contacts.push({
        email: '',
        phone_number: '',
        name: '',
        editing: true,
        activeDialCode: '',
        errors: { email: '', phone_number: '', name: '' },
      });
    },
    saveContact(index) {
      const contact = this.contacts[index];
      const errors = contact.errors;
      let isValid = true;

      // Reset errors
      errors.email = '';
      errors.phone_number = '';
      errors.name = '';

      // // Helper function for validating name
      // const validateName = () => {
      //   if (!contact.name || contact.name.trim() === '') {
      //     errors.name = contact.name
      //       ? 'Name cannot be empty.'
      //       : 'Name is required.';
      //     return false;
      //   }
      //   return true;
      // };

      if (this.channelToCompare === INBOX_TYPES.EMAIL) {
        if (!contact.email) {
          errors.email = 'Email is required.';
          isValid = false;
        } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(contact.email)) {
          errors.email = 'Enter a valid email.';
          isValid = false;
        }

        if (contact.phone_number) {
          const isValidPhoneNumber = /^\+?\d{7,15}$/.test(contact.phone_number);

          if (!isValidPhoneNumber) {
            if (!contact.activeDialCode) {
              errors.phone_number = 'Select a valid country code';
            } else {
              errors.phone_number = 'Enter a valid phone number.';
            }
            isValid = false;
          }
        }
      } else if (this.channelToCompare === INBOX_TYPES.API) {
        if (!contact.phone_number) {
          errors.phone_number = 'Phone is required.';
          isValid = false;
        } else if (!/^\+?\d{7,15}$/.test(contact.phone_number)) {
          errors.phone_number = 'Enter a valid phone number.';
          isValid = false;
        }

        if (contact.activeDialCode === '') {
          errors.phone_number = 'Enter a valid phone number.';
          isValid = false;
        }

        if (
          contact.email &&
          !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(contact.email)
        ) {
          errors.email = 'Enter a valid email.';
          isValid = false;
        }
      }

      if (isValid) {
        contact.editing = false;
        contact.phone_number = `${contact.activeDialCode}${contact.phone_number}`;
      }
    },
    cancelEdit(index) {
      if (this.contacts[index].email === '') {
        this.contacts.splice(index, 1); // Remove if canceling a new contact
      } else {
        this.contacts[index].editing = false; // Revert to saved state
      }
    },
    editContact(index) {
      const contact = this.contacts[index];
      contact.editing = true;
      contact.phone_number = contact.phone_number?.replace(
        `${contact.activeDialCode}`,
        ''
      );
      this.contacts[index] = contact;
    },
    removeContact(index) {
      this.contacts.splice(index, 1);
    },
  },
};
</script>

<style scoped lang="scss">
.conversation--form {
  @apply pt-4 px-8 pb-8;
}

.message-editor {
  @apply border-none;

  ::v-deep {
    .ProseMirror-menubar {
      @apply rounded-tl-[4px];
    }
  }
}

.message-input {
  min-height: 8rem;
}

.row.gutter-small {
  gap: var(--space-small);
}
.alert-text {
  color: #ff382d;
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
