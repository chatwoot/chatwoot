<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <woot-button
      class-names="button--fixed-top"
      color-scheme="primary"
      @click="createChatbot"
    >
      {{ $t('CHATBOT_SETTINGS.FORM.SUBMIT_CREATE') }}
    </woot-button>
    <page-header
      :header-title="$t('CHATBOT_SETTINGS.CREATE_FLOW.CONNECT.TITLE')"
      :header-content="$t('CHATBOT_SETTINGS.CREATE_FLOW.CONNECT.DESC')"
    />
    <div class="flex flex-wrap">
      <div class="mt-2 flex-grow-0 flex-shrink-0 flex-[80%]">
        <label>
          {{ $t('CHATBOT_SETTINGS.FORM.TITLE') }}
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
    <banner
      v-if="!userDismissedBotCreatingMessage && showBotCreatingMessage"
      color-scheme="primary"
      :banner-message="botCreatingMessage"
      has-close-button
      class="fixed top-0 left-0 w-full z-50"
      @close="dismissUpdateBanner"
    />
    <banner
      v-if="!userDismissedBotCreatedMessage && showBotCreatedMessage"
      color-scheme="primary"
      :banner-message="botCreatedMessage"
      has-close-button
      class="fixed top-0 left-0 w-full z-50"
      @close="dismissUpdateBanner"
    />
    <banner
      v-if="
        !userDismissedBotCreationFailureMessage && showBotCreationFailureMessage
      "
      color-scheme="alert"
      :banner-message="botCreationFailureMessage"
      has-close-button
      class="fixed top-0 left-0 w-full z-50"
      @close="dismissUpdateBanner"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import ChatbotAPI from '../../../../../api/chatbot';
import PageHeader from '../../SettingsSubPageHeader.vue';
import Banner from '../../../../../../dashboard/components/ui/Banner.vue';

export default {
  components: {
    PageHeader,
    Banner,
  },
  data() {
    return {
      selectedInbox: null,
      website_token: '',
      isButtonActive: false,
      inbox_id: '',
      inbox_name: '',
      showBotCreatingMessage: false,
      showBotCreatedMessage: false,
      showBotCreationFailureMessage: false,
      userDismissedBotCreatingMessage: false,
      userDismissedBotCreatedMessage: false,
      userDismissedBotCreationFailureMessage: false,
      chatbot_id: '',
    };
  },
  computed: {
    ...mapGetters({
      inboxesList: 'inboxes/getInboxes',
      currentAccountId: 'getCurrentAccountId',
      botFiles: 'chatbot/getBotFiles',
      botText: 'chatbot/getBotText',
      botUrls: 'chatbot/getBotUrls',
    }),
    ...mapGetters({ uiSettings: 'getUISettings' }),
    filteredInboxes() {
      return this.inboxesList.filter(
        inbox => inbox.channel_type === 'Channel::WebWidget'
      );
    },
    botCreatingMessage() {
      return this.$t('CHATBOT_SETTINGS.BANNER.CREATING');
    },
    botCreatedMessage() {
      return this.$t('CHATBOT_SETTINGS.BANNER.CREATED');
    },
    botCreationFailureMessage() {
      return this.$t('CHATBOT_SETTINGS.BANNER.FAIL');
    },
  },
  methods: {
    async createChatbot() {
      try {
        this.showBotCreatingMessage = true;
        const payload = new FormData();
        payload.append('accountId', this.currentAccountId);
        payload.append('website_token', this.website_token);
        payload.append('inbox_id', this.inbox_id);
        payload.append('inbox_name', this.inbox_name);
        const res = await ChatbotAPI.storeToDb(payload);
        const formData = new FormData();
        formData.append('bot_text', this.botText);
        formData.append('chatbot_id', res.chatbot_id);
        this.chatbot_id = res.chatbot_id;
        formData.append('temperature', 0.1);
        for (let i = 0; i < this.botFiles.length; i += 1) {
          formData.append('bot_files', this.botFiles[i]);
        }
        for (let i = 0; i < this.botUrls.length; i += 1) {
          formData.append('bot_urls', this.botUrls[i]);
        }
        await ChatbotAPI.createChatbot(formData);
        this.showBotCreatingMessage = false;
        this.showBotCreatedMessage = true;
        await this.$router.push({
          name: 'chatbot_index', // Name of the route to redirect to
          params: { accountId: this.currentAccountId }, // Parameters to pass to the route if any
        });
      } catch (error) {
        this.showBotCreatingMessage = false;
        await ChatbotAPI.deleteChatbotWithChatbotId(this.chatbot_id);
        this.showBotCreationFailureMessage = true;
      }
    },
    dismissUpdateBanner() {
      this.userDismissedBotCreatingMessage = true;
      this.userDismissedBotCreatedMessage = true;
      this.userDismissedBotCreationFailureMessage = true;
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
