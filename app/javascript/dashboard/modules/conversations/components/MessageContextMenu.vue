<template>
  <div class="context-menu">
    <!-- Add To Canned Responses -->
    <woot-modal
      v-if="isCannedResponseModalOpen && enabledOptions['cannedResponse']"
      :show.sync="isCannedResponseModalOpen"
      :on-close="hideCannedResponseModal"
    >
      <add-canned-modal
        :response-content="plainTextContent"
        :on-close="hideCannedResponseModal"
      />
    </woot-modal>
    <!-- Translate Content -->
    <translate-modal
      v-if="showTranslateModal"
      :content="messageContent"
      :content-attributes="contentAttributes"
      @close="onCloseTranslateModal"
    />
    <!-- Confirm Deletion -->
    <woot-delete-modal
      v-if="showDeleteModal"
      class="context-menu--delete-modal"
      :show.sync="showDeleteModal"
      :on-close="closeDeleteModal"
      :on-confirm="confirmDeletion"
      :title="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.TITLE')"
      :message="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.MESSAGE')"
      :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
      :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')"
    />
    <woot-button
      icon="more-vertical"
      color-scheme="secondary"
      variant="clear"
      size="small"
      @click="handleOpen"
    />
    <woot-context-menu
      v-if="isOpen && !isCannedResponseModalOpen"
      :x="contextMenuPosition.x"
      :y="contextMenuPosition.y"
      @close="handleClose"
    >
      <div class="menu-container">
        <menu-item
          v-if="enabledOptions['copy']"
          :option="{
            icon: 'clipboard',
            label: this.$t('CONVERSATION.CONTEXT_MENU.COPY'),
          }"
          variant="icon"
          @click="handleCopy"
        />
        <menu-item
          v-if="enabledOptions['copy']"
          :option="{
            icon: 'translate',
            label: this.$t('CONVERSATION.CONTEXT_MENU.TRANSLATE'),
          }"
          variant="icon"
          @click="handleTranslate"
        />
        <hr />
        <menu-item
          :option="{
            icon: 'link',
            label: this.$t('CONVERSATION.CONTEXT_MENU.COPY_PERMALINK'),
          }"
          variant="icon"
          @click="copyLinkToMessage"
        />
        <menu-item
          v-if="enabledOptions['cannedResponse']"
          :option="{
            icon: 'comment-add',
            label: this.$t(
              'CONVERSATION.CONTEXT_MENU.CREATE_A_CANNED_RESPONSE'
            ),
          }"
          variant="icon"
          @click="showCannedResponseModal"
        />
        <hr v-if="enabledOptions['delete']" />
        <menu-item
          v-if="enabledOptions['delete']"
          :option="{
            icon: 'delete',
            label: this.$t('CONVERSATION.CONTEXT_MENU.DELETE'),
          }"
          variant="icon"
          @click="openDeleteModal"
        />
      </div>
    </woot-context-menu>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import AddCannedModal from 'dashboard/routes/dashboard/settings/canned/AddCanned';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import TranslateModal from 'dashboard/components/widgets/conversation/bubble/TranslateModal';
import MenuItem from '../../../components/widgets/conversation/contextMenu/menuItem.vue';

export default {
  components: {
    AddCannedModal,
    TranslateModal,
    MenuItem,
  },
  mixins: [alertMixin, clickaway, messageFormatterMixin],
  props: {
    message: {
      type: Object,
      required: true,
    },
    isOpen: {
      type: Boolean,
      default: false,
    },
    enabledOptions: {
      type: Object,
      default: () => ({}),
    },
    contextMenuPosition: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isCannedResponseModalOpen: false,
      showTranslateModal: false,
      showDeleteModal: false,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentAccountId: 'getCurrentAccountId',
    }),
    plainTextContent() {
      return this.getPlainText(this.messageContent);
    },
    conversationId() {
      return this.message.conversation_id;
    },
    messageId() {
      return this.message.id;
    },
    messageContent() {
      return this.message.content;
    },
    contentAttributes() {
      return this.message.content_attributes;
    },
  },
  methods: {
    async copyLinkToMessage() {
      const fullConversationURL =
        window.chatwootConfig.hostURL +
        frontendURL(
          conversationUrl({
            id: this.conversationId,
            accountId: this.currentAccountId,
          })
        );
      await copyTextToClipboard(
        `${fullConversationURL}?messageId=${this.messageId}`
      );
      this.showAlert(this.$t('CONVERSATION.CONTEXT_MENU.LINK_COPIED'));
      this.handleClose();
    },
    async handleCopy() {
      await copyTextToClipboard(this.plainTextContent);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
      this.handleClose();
    },
    showCannedResponseModal() {
      this.$track(ACCOUNT_EVENTS.ADDED_TO_CANNED_RESPONSE);
      this.isCannedResponseModalOpen = true;
    },
    hideCannedResponseModal() {
      this.isCannedResponseModalOpen = false;
      this.handleClose();
    },
    handleOpen(e) {
      this.$emit('open', e);
    },
    handleClose(e) {
      this.$emit('close', e);
    },
    handleTranslate() {
      const { locale } = this.getAccount(this.currentAccountId);
      this.$store.dispatch('translateMessage', {
        conversationId: this.conversationId,
        messageId: this.messageId,
        targetLanguage: locale || 'en',
      });
      this.handleClose();
      this.showTranslateModal = true;
    },
    onCloseTranslateModal() {
      this.showTranslateModal = false;
    },

    openDeleteModal() {
      this.handleClose();
      this.showDeleteModal = true;
    },
    async confirmDeletion() {
      try {
        await this.$store.dispatch('deleteMessage', {
          conversationId: this.conversationId,
          messageId: this.messageId,
        });
        this.showAlert(this.$t('CONVERSATION.SUCCESS_DELETE_MESSAGE'));
        this.handleClose();
      } catch (error) {
        this.showAlert(this.$t('CONVERSATION.FAIL_DELETE_MESSSAGE'));
      }
    },
    closeDeleteModal() {
      this.showDeleteModal = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.menu-container {
  padding: var(--space-smaller);
  background-color: var(--white);
  box-shadow: var(--shadow-context-menu);
  border-radius: var(--border-radius-normal);

  hr:first-child {
    display: none;
  }

  hr {
    border-bottom: 1px solid var(--color-border-light);
    margin: var(--space-smaller);
  }
}

.context-menu--delete-modal {
  ::v-deep {
    .modal-container {
      max-width: 48rem;

      h2 {
        font-weight: var(--font-weight-medium);
        font-size: var(--font-size-default);
      }
    }

    .modal-footer {
      padding: var(--space-normal) var(--space-large) var(--space-large);
    }
  }
}
</style>
