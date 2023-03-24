<template>
  <div class="context-menu">
    <woot-modal
      v-if="isCannedResponseModalOpen && showCannedResponseOption"
      :show.sync="isCannedResponseModalOpen"
      :on-close="hideCannedResponseModal"
    >
      <add-canned-modal
        :response-content="plainTextContent"
        :on-close="hideCannedResponseModal"
      />
    </woot-modal>
    <woot-button
      icon="more-vertical"
      color-scheme="secondary"
      variant="clear"
      size="small"
      @click="handleOpen"
    />

    <woot-context-menu
      v-if="isOpen && !isCannedResponseModalOpen"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="handleClose"
    >
      <div class="menu-container">
        <menu-item
          :option="{
            icon: 'clipboard',
            label: this.$t('CONVERSATION.CONTEXT_MENU.COPY'),
          }"
          variant="icon"
          @click="handleCopy"
        />
        <menu-item
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
          :option="{
            icon: 'comment-add',
            label: this.$t(
              'CONVERSATION.CONTEXT_MENU.CREATE_A_CANNED_RESPONSE'
            ),
          }"
          variant="icon"
          @click="showCannedResponseModal"
        />
        <hr />

        <menu-item
          v-if="showDelete"
          :option="{
            icon: 'delete',
            label: this.$t('CONVERSATION.CONTEXT_MENU.DELETE'),
          }"
          variant="icon"
          @click="handleDelete"
        />
      </div>
    </woot-context-menu>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import { mixin as clickaway } from 'vue-clickaway';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

import AddCannedModal from 'dashboard/routes/dashboard/settings/canned/AddCanned';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';
import { mapGetters } from 'vuex';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import MenuItem from '../../../components/widgets/conversation/contextMenu/menuItem.vue';

export default {
  components: {
    AddCannedModal,
    MenuItem,
  },
  mixins: [alertMixin, clickaway, messageFormatterMixin],
  props: {
    messageContent: {
      type: String,
      default: '',
    },
    isOpen: {
      type: Boolean,
      default: false,
    },
    showCopy: {
      type: Boolean,
      default: false,
    },
    contextMenu: {
      type: Object,
      default: () => ({}),
    },
    showDelete: {
      type: Boolean,
      default: false,
    },
    menuPosition: {
      type: String,
      default: 'left',
    },
    showCannedResponseOption: {
      type: Boolean,
      default: true,
    },
    conversationId: {
      type: Number,
      required: true,
    },
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return { isCannedResponseModalOpen: false };
  },
  computed: {
    ...mapGetters({ currentAccountId: 'getCurrentAccountId' }),
    plainTextContent() {
      return this.getPlainText(this.messageContent);
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
      await copyTextToClipboard(`${fullConversationURL}?messageId=${this.id}`);
      this.showAlert(this.$t('CONVERSATION.LINK_COPIED'));
      this.handleClose();
    },
    async handleCopy() {
      await copyTextToClipboard(this.plainTextContent);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
      this.handleClose();
    },
    handleDelete() {
      this.$emit('delete');
      this.handleClose();
    },
    hideCannedResponseModal() {
      this.isCannedResponseModalOpen = false;
    },
    showCannedResponseModal() {
      this.$track(ACCOUNT_EVENTS.ADDED_TO_CANNED_RESPONSE);
      this.isCannedResponseModalOpen = true;
    },
    handleTranslate() {
      this.$emit('translate');
      this.handleClose();
    },
    handleClose(e) {
      this.$emit('close', e);
    },
    handleOpen(e) {
      this.$emit('open', e);
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

  hr {
    border-bottom: 1px solid var(--color-border-light);
    margin: var(--space-smaller);
  }
}
</style>
