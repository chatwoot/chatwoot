<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <br />
    <h1>{{ $t('CHATBOT_SETTINGS.CHATBOT_INBOX_CONNECT') }}</h1>
    <br />
    <template v-if="isHamburgerMenuOpen">
      <back-button class="absolute top-[17px] left-[420px]" />
    </template>
    <template v-else>
      <back-button class="absolute top-[17px] left-[240px]" />
    </template>
    <div class="inbox-dropdown-container">
      <div class="custom-select">
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
        <div class="arrow-down" />
      </div>
    </div>
    <woot-button
      :is-disabled="!isButtonActive"
      class-names="button--fixed-top"
      @click="createChatbot()"
    >
      {{ $t('CHATBOT_SETTINGS.FORM.SUBMIT_CREATE') }}
    </woot-button>
    <div v-if="showToast" class="toast">{{ toastMessage }}</div>
    <banner
      v-if="!userDismissedBlueBanner && showBlueBanner"
      color-scheme="primary"
      :banner-message="blueBannerMessage"
      has-close-button
      class="fixed top-0 left-0 w-full z-50"
      @close="dismissUpdateBanner"
    />
    <banner
      v-if="!userDismissedRedBanner && showRedBanner"
      color-scheme="alert"
      :banner-message="redBannerMessage"
      has-close-button
      class="fixed top-0 left-0 w-full z-50"
      @close="dismissUpdateBanner"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import BackButton from '../../../../../components/widgets/BackButton.vue';
import ChatbotAPI from '../../../../../api/chatbot';
import Banner from 'dashboard/components/ui/Banner.vue';

export default {
  components: {
    BackButton,
    Banner,
  },
  data() {
    return {
      selectedInbox: null,
      website_token: '',
      isButtonActive: false,
      showToast: false,
      toastMessage: '',
      inbox_id: '',
      inbox_name: '',
      showBlueBanner: false,
      showRedBanner: false,
      userDismissedBlueBanner: false,
      userDismissedRedBanner: false,
      chatbot_id: '',
      isHamburgerMenuOpen: true,
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
    blueBannerMessage() {
      return this.$t('GENERAL_SETTINGS.BANNER_CHATBOT_CREATION');
    },
    redBannerMessage() {
      return this.$t('GENERAL_SETTINGS.BANNER_CHATBOT_FAIL');
    },
  },
  watch: {
    'uiSettings.show_secondary_sidebar': function (newVal) {
      this.isHamburgerMenuOpen = newVal;
    },
  },
  created() {
    this.isHamburgerMenuOpen = this.uiSettings.show_secondary_sidebar;
  },
  methods: {
    ...mapActions('chatbot', [
      'addBotUrl',
      'setBotText',
      'addBotFiles',
      'deleteBotFile',
      'deleteBotUrl',
    ]),
    async createChatbot() {
      try {
        this.showBlueBanner = true;
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
        this.showBlueBanner = false;
        await this.$router.push({
          name: 'chatbot_index', // Name of the route to redirect to
          params: { accountId: this.currentAccountId }, // Parameters to pass to the route if any
        });
        window.location.reload();
      } catch (error) {
        this.showBlueBanner = false;
        await ChatbotAPI.deleteChatbotWithChatbotId(this.chatbot_id);
        this.showRedBanner = true;
        // this.showToastMessage('Chatbot creation failed !');
      }
    },
    dismissUpdateBanner() {
      this.userDismissedBlueBanner = true;
      this.userDismissedRedBanner = true;
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
    // showToastMessage(message) {
    //   this.toastMessage = message;
    //   this.showToast = true;
    //   setTimeout(() => {
    //     this.showToast = false;
    //   }, 5000); // 5 seconds
    // },
  },
};
</script>

<style scoped>
h1 {
  font-size: x-large;
}

.inbox-dropdown-container {
  margin-bottom: 100%; /* Adjust the margin as needed */
  max-height: 35vh; /* Limit the maximum height of the container */
  overflow-y: auto; /* Enable vertical scrolling if content overflows */
}

.custom-select {
  position: relative;
  width: 100%;
}

.inbox-dropdown {
  width: 100%;
  padding: 8px;
  border-radius: 5px;
  border: 1px solid #ccc;
}

.arrow-down {
  position: absolute;
  top: calc(50% - 10px);
  right: 10px;
  width: 0;
  height: 0;
  border-left: 4px solid transparent;
  border-right: 4px solid transparent;
  border-top: 6px solid #777;
}

.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 9999;
  display: flex;
  justify-content: center;
  align-items: center;
}

.spinner-container {
  display: flex;
  justify-content: center;
  align-items: center;
}

.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background-color: rgba(255, 0, 0, 0.8);
  color: white;
  padding: 10px 20px;
  border-radius: 5px;
  z-index: 9999;
}
.banner {
  position: fixed;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  max-width: 24%;
  width: auto;
  z-index: 9999;
  border-radius: 5px;
}
</style>
