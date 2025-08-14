<template>
  <form class="conversation--form w-full" @submit.prevent="onFormSubmit">
    <div
      v-if="showNoInboxAlert"
      class="relative mx-0 mt-0 mb-2.5 p-2 rounded-none text-sm border border-solid border-yellow-500 dark:border-yellow-700 bg-yellow-200/60 dark:bg-yellow-200/20 text-slate-700 dark:text-yellow-400"
    >
      <p class="mb-0">
        {{
          "Couldn't find an Meta inbox to initiate a DM conversation with this contact."
        }}
      </p>
    </div>
    <div>
      <div class="gap-2 flex flex-row">
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
                :username="displayName"
                :status="contact.availability_status"
              />
              <h4
                class="m-0 ml-2 mr-2 text-slate-700 dark:text-slate-100 text-sm"
              >
                {{ displayName }}
              </h4>
            </div>
          </label>
        </div>
      </div>
      <div v-if="targetInbox && targetInbox.id" class="editor-wrap">
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
            <div class="mb-3 mt-px">
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

    <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
      <button class="button clear" @click.prevent="onCancel">
        {{ $t('NEW_CONVERSATION.FORM.CANCEL') }}
      </button>
      <woot-button type="submit" :is-disabled="!targetInbox || $v.$invalid">
        {{ $t('NEW_CONVERSATION.FORM.SUBMIT') }}
      </woot-button>
    </div>
  </form>
</template>

<script>
import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import MessageSignatureMissingAlert from 'dashboard/components/widgets/conversation/MessageSignatureMissingAlert';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';
import { getInboxSource } from 'dashboard/helper/inbox';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import alertMixin from 'shared/mixins/alertMixin';
import inboxMixin, { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import { required } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import conversationsApi from '../../../../api/conversations';
import { getContactDisplayName } from 'shared/helpers/contactHelper';

export default {
  components: {
    Thumbnail,
    WootMessageEditor,
    InboxDropdownItem,
    MessageSignatureMissingAlert,
  },
  mixins: [alertMixin, uiSettingsMixin, inboxMixin, fileUploadMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    commentId: {
      type: String,
      default: '',
    },
    messageId: {
      type: Number,
      default: NaN,
    },
  },
  data() {
    return {
      message: '',
      showCannedResponseMenu: false,
      cannedResponseSearchKey: '',
      targetInbox: {},
    };
  },
  validations: {
    message: {
      required,
    },
    targetInbox: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      uiFlags: 'contacts/getUIFlags',
      currentUser: 'getCurrentUser',
      messageSignature: 'getMessageSignature',
      inboxesList: 'inboxes/getInboxes',
    }),
    sendWithSignature() {
      return this.fetchSignatureFlagFromUiSettings(this.channelType);
    },
    signatureToApply() {
      return this.messageSignature;
    },
    editorStateId() {
      return `draft-${this.conversationIdByRoute}-${this.replyType}`;
    },
    newMessagePayload() {
      const payload = new FormData();
      const params = {
        inboxId: this.targetInbox.id,
        sourceId: this.targetInbox.sourceId,
        contactId: this.contact.id,
        message: { content: this.message },
        assigneeId: this.currentUser.id,
        commentId: this.commentId,
      };

      payload.append('inbox_id', params.inboxId);
      payload.append('source_id', params.sourceId);
      payload.append('contact_id', params.contactId);
      payload.append('message[content]', params.message.content);
      payload.append('assignee_id', params.assigneeId);
      payload.append('comment_id', params.commentId);
      payload.append('conversation_id', this.currentChat.id);
      payload.append('message_id', this.messageId);

      return payload;
    },
    selectedInbox: {
      get() {
        return (
          this.inboxesList.find(inbox => {
            return inbox?.id && inbox?.id === this.targetInbox?.id;
          }) || {
            inbox: {},
          }
        );
      },
      set(value) {
        this.targetInbox = value;
      },
    },
    showNoInboxAlert() {
      if (!this.inboxes) {
        return false;
      }
      return this.inboxes.length === 0 && !this.uiFlags.isFetchingInboxes;
    },
    isSignatureEnabledForInbox() {
      return !this.isPrivate && this.sendWithSignature;
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    inboxes() {
      return this.inboxesList
        .filter(inbox => inbox.channel_type === INBOX_TYPES.FB)
        .map(inbox => ({
          ...inbox,
          sourceId: inbox.source_id,
        }));
    },
    inbox() {
      return this.targetInbox;
    },
    displayName() {
      return getContactDisplayName(this.contact);
    },
  },
  watch: {
    message(value) {
      this.hasSlashCommand = value[0] === '/';
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
    onFormSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.createConversation({
        payload: this.newMessagePayload,
      });
    },
    async createConversation({ payload }) {
      try {
        await conversationsApi.createInstagramDmConversation(payload);
        this.showAlert('Instagram DM conversation Created');
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(
            error.response.data.error ??
              this.$t('NEW_CONVERSATION.FORM.ERROR_MESSAGE')
          );
        }
      } finally {
        this.onSuccess();
      }
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
