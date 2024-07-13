<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <woot-button
      class-names="button--fixed-top"
      color-scheme="primary"
      @click="createChatbot"
    >
      {{ $t('CHATBOTS.FORM.SUBMIT_CREATE') }}
    </woot-button>
    <page-header
      :header-title="$t('CHATBOTS.CREATE_FLOW.CONNECT.TITLE')"
      :header-content="$t('CHATBOTS.CREATE_FLOW.CONNECT.DESC')"
    />
    <div class="flex flex-wrap">
      <div class="mt-2 flex-grow-0 flex-shrink-0 flex-[80%]">
        <label>
          {{ $t('CHATBOTS.FORM.TITLE') }}
          <select
            v-model="selectedInbox"
            class="inbox-dropdown"
            @change="allotWebsiteToken"
          >
            <option
              v-for="inbox in filteredInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
        </label>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ChatbotAPI from '../../../../../api/chatbots';
import PageHeader from '../../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      selectedInbox: null,
      website_token: '',
      isButtonActive: false,
      inbox_id: '',
      inbox_name: '',
      showBotCreatingBanner: false,
      showBotCreationFailureBanner: false,
    };
  },
  computed: {
    ...mapGetters({
      inboxesList: 'inboxes/getInboxes',
      currentAccountId: 'getCurrentAccountId',
      botFiles: 'chatbots/getBotFiles',
      botText: 'chatbots/getBotText',
      botUrls: 'chatbots/getBotUrls',
    }),
    ...mapGetters({ uiSettings: 'getUISettings' }),
    filteredInboxes() {
      return this.inboxesList.filter(
        inbox => inbox.channel_type === 'Channel::WebWidget'
      );
    },
  },
  methods: {
    async createChatbot() {
      const payload = {
        accountId: this.currentAccountId,
        website_token: this.website_token,
        inbox_id: this.inbox_id,
        inbox_name: this.inbox_name,
        bot_files: this.botFiles,
        bot_text: this.botText,
        bot_urls: this.botUrls,
      };
      await ChatbotAPI.createChatbot(payload);
      this.$router.push({
        name: 'chatbots_index',
        params: { accountId: this.currentAccountId },
      });
    },
    allotWebsiteToken() {
      if (this.selectedInbox) {
        const selectedInboxData = this.filteredInboxes.find(
          inbox => inbox.id === this.selectedInbox
        );
        this.isButtonActive = true;
        this.inbox_name = selectedInboxData.name;
        this.website_token = selectedInboxData.website_token;
        this.inbox_id = selectedInboxData.id;
      } else {
        this.isButtonActive = false;
      }
    },
  },
};
</script>
