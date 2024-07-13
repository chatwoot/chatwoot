<template>
  <div class="flex-1 overflow-auto">
    <router-link
      :to="addAccountScoping(`settings/chatbots/create`)"
      class="button success button--fixed-top button success button--fixed-top px-3.5 py-1 rounded-[5px] flex gap-2"
    >
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ $t('CHATBOTS.NEW_BOT') }}
      </span>
    </router-link>
    <div class="flex flex-row gap-4 p-8">
      <div class="w-full lg:w-3/5">
        <div v-if="!chatbots.length" class="p-3">
          <p class="flex h-full items-center flex-col justify-center">
            {{ $t('CHATBOTS.LIST.404') }}
          </p>
        </div>
        <table v-if="chatbots.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t('CHATBOTS.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <chatbot-table-row
              v-for="(chatbot, index) in chatbots"
              :key="index"
              :chatbot="chatbot"
              @delete="openDeletePopup(chatbot, index)"
            />
          </tbody>
        </table>
      </div>
      <div class="hidden lg:block w-1/3">
        <span v-dompurify-html="$t('CHATBOTS.SIDEBAR_TXT')" />
      </div>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CHATBOTS.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('CHATBOTS.DELETE.CONFIRM.YES')"
      :reject-text="$t('CHATBOTS.DELETE.CONFIRM.NO')"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import alertMixin from 'shared/mixins/alertMixin';
import ChatbotAPI from '../../../../api/chatbots';
import ChatbotTableRow from './ChatbotTableRow.vue';

export default {
  components: {
    ChatbotTableRow,
  },
  mixins: [adminMixin, accountMixin, alertMixin],
  data() {
    return {
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      loading: {},
      chatbots: [],
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentAccountId: 'getCurrentAccountId',
    }),
    deleteMessage() {
      return ` ${this.selectedResponse.name}?`;
    },
  },
  mounted() {
    this.fetchChatbots();
  },
  methods: {
    async fetchChatbots() {
      ChatbotAPI.getChatbots(this.currentAccountId).then(response => {
        this.chatbots = response.data;
      });
    },
    async deleteChatbot(id) {
      try {
        ChatbotAPI.deleteChatbot(id).then(() => {
          this.showAlert(this.$t('CHATBOTS.DELETE.API.SUCCESS_MESSAGE'));
          this.loading[this.selectedResponse.id] = false;
        });
      } catch (error) {
        this.showAlert(this.$t('CHATBOTS.DELETE.API.ERROR_MESSAGE'));
      }
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteChatbot(this.selectedResponse.id);
    },
  },
};
</script>

<style lang="scss" scoped>
.button-wrapper {
  min-width: unset;
  justify-content: flex-end;
  padding-right: var(--space-large);
}
.chatbot-id {
  text-transform: none;
}
</style>
../../../../api/chatbots
