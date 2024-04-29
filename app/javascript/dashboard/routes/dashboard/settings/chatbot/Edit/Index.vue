<template>
  <div class="overflow-auto p-4 max-w-full my-auto flex flex-wrap h-full">
    <div class="mx-0 flex flex-wrap">
      <template v-if="isHamburgerMenuOpen">
        <back-button class="absolute top-[17px] left-[420px]" />
      </template>
      <template v-else>
        <back-button class="absolute top-[17px] left-[240px]" />
      </template>
      <div class="flex-shrink-0 flex-grow-0 w-[65%]">
        <form class="mx-0 flex flex-wrap" @submit.prevent="handleSubmit">
          <woot-input
            v-model.trim="title"
            :class="{ error: $v.title.$error }"
            class="w-full"
            :label="$t('CHATBOT_SETTINGS.FORM.NAME.LABEL')"
            :placeholder="$t('CHATBOT_SETTINGS.FORM.NAME.PLACEHOLDER')"
            @input="$v.title.$touch"
          />
          <!-- Display the dropdown for selecting inboxes -->
          <div
            v-if="filteredInboxes.length > 0"
            class="inbox-dropdown-container w-full"
          >
            <span class="bold-dark-text">{{
              $t('CHATBOT_SETTINGS.CONNECT_INBOX')
            }}</span>
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
          <div class="flex flex-wrap">
            <div class="w-full">
              <h6>{{ $t('CHATBOT_SETTINGS.CHATBOT_ID') }} {{ chatbot_id }}</h6>
            </div>
            <div class="w-full">
              <h6>
                {{ $t('CHATBOT_SETTINGS.LAST_TRAINED_AT') }}
                {{ last_trained_at }}
              </h6>
            </div>
            <div class="w-full">
              <h6>
                {{ $t('CHATBOT_SETTINGS.CONNECTED_INBOX') }}
                {{ connectedInbox }}
              </h6>
            </div>
          </div>
          <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
            <div class="w-full">
              <button
                class="btn btn-primary"
                class-names="button--fixed-top"
                style="
                  background-color: #4d9cf7;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 4px;
                  cursor: pointer;
                "
                @click="updateInfo()"
              >
                {{ $t('CHATBOT_SETTINGS.UPDATE') }}
              </button>
              <button
                class="btn"
                style="
                  background-color: #fc2634;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 4px;
                  cursor: pointer;
                "
                :disabled="isDisconnectButtonDisabled"
                @click="disconnectBot()"
              >
                {{ $t('CHATBOT_SETTINGS.DISCONNECT') }}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
    <div v-if="submitInProgress" class="spinner-container">
      <spinner size="large" color-scheme="primary" />
    </div>
    <!-- Toaster Notification -->
    <div v-if="showToast" class="toast">{{ toastMessage }}</div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import BackButton from '../../../../../components/widgets/BackButton.vue';
import validations from '../helpers/validations';
import ChatbotAPI from '../../../../../api/chatbot';
import Spinner from '../../../../../../shared/components/Spinner.vue';

export default {
  components: {
    BackButton,
    Spinner,
  },
  beforeRouteLeave(to, from, next) {
    // Reset component data before navigating away
    this.resetData();
    next();
  },
  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    formData: {
      type: Object,
      default: () => {},
    },
    submitButtonText: {
      type: String,
      default: '',
    },
    chatbotId: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      title: '',
      last_trained_at: '',
      chatbot_id: '',
      submitInProgress: false,
      website_token: '',
      selectedInbox: null,
      isButtonActive: false,
      showToast: false,
      toastMessage: '',
      inbox_id: null,
      connectedInbox: null,
      updatedInboxName: '',
      isHamburgerMenuOpen: true,
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
      inboxesList: 'inboxes/getInboxes',
    }),
    ...mapGetters({ uiSettings: 'getUISettings' }),
    filteredInboxes() {
      return this.inboxesList.filter(
        inbox => inbox.channel_type === 'Channel::WebWidget'
      );
    },
    isDisconnectButtonDisabled() {
      return this.inbox_id === null;
    },
  },
  validations,
  watch: {
    $route(to) {
      this.fetchChatbotData(to.params.chatbotId);
      this.connectedInbox = this.getChatbotInboxName(this.chatbot_id);
    },
    'uiSettings.show_secondary_sidebar': function (newVal) {
      this.isHamburgerMenuOpen = newVal;
    },
  },
  created() {
    this.isHamburgerMenuOpen = this.uiSettings.show_secondary_sidebar;
  },
  async mounted() {
    this.fetchChatbotData(this.$route.params.chatbotId);
    this.connectedInbox = this.getChatbotInboxName(this.chatbot_id);
  },
  methods: {
    async disconnectBot() {
      const res = await ChatbotAPI.disconnectChatbot(this.chatbot_id);
      if (res.status === 200) {
        window.location.reload();
      }
    },
    async getChatbotInboxName(chatbot_id) {
      const res = await ChatbotAPI.ChatbotIdToChatbotName(chatbot_id);
      this.connectedInbox = res.data.name;
      this.inbox_id = res.data.id;
    },
    fetchChatbotData(data) {
      if (data) {
        const [chatbotID, lastTrainedAt] = data.split('@');
        this.chatbot_id = chatbotID;
        if (lastTrainedAt) {
          const lastTrainedAtUTC = new Date(lastTrainedAt);
          const lastTrainedAtLocal = new Date(
            lastTrainedAtUTC.getTime() +
              lastTrainedAtUTC.getTimezoneOffset() * 60000
          );
          const year = lastTrainedAtLocal.getFullYear();
          const month = String(lastTrainedAtLocal.getMonth() + 1).padStart(
            2,
            '0'
          );
          const day = String(lastTrainedAtLocal.getDate()).padStart(2, '0');
          const hours = String(lastTrainedAtLocal.getHours()).padStart(2, '0');
          const minutes = String(lastTrainedAtLocal.getMinutes()).padStart(
            2,
            '0'
          );
          const seconds = String(lastTrainedAtLocal.getSeconds()).padStart(
            2,
            '0'
          );
          this.last_trained_at = `${year}/${month}/${day}, ${hours}:${minutes}:${seconds}`;
        } else {
          this.last_trained_at = '';
        }
      } else {
        this.resetData();
      }
    },
    allotWebsiteToken() {
      if (this.selectedInbox) {
        const selectedInboxData = this.inboxesList.find(
          inbox => inbox.id === this.selectedInbox
        );
        this.isButtonActive = true;
        this.website_token = selectedInboxData.website_token;
        this.inbox_id = selectedInboxData.id;
        this.updatedInboxName = selectedInboxData.name;
      }
    },
    resetData() {
      this.chatbot_id = '';
      this.last_trained_at = '';
    },
    async handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.onSubmit({
        name: this.title,
      });
    },

    async updateInfo() {
      if (this.title.length > 20) return;
      if (this.title !== '' || this.selectedInbox !== null) {
        this.isButtonActive = true;
        const new_bot_name = this.title;
        const payload = new FormData();
        payload.append('chatbot_id', this.chatbot_id);
        payload.append('new_bot_name', new_bot_name);
        payload.append('website_token', this.website_token);
        payload.append('inbox_id', this.inbox_id);
        payload.append('inbox_name', this.updatedInboxName);
        this.submitInProgress = true;
        try {
          const res = await ChatbotAPI.editBotInfo(payload);
          if (res.status === 200 || res.status === 201) {
            await this.$router.push({
              name: 'chatbot_index', // Name of the route to redirect to
              params: { accountId: this.currentAccountId }, // Parameters to pass to the route if any
            });
            this.submitInProgress = false;
            window.location.reload();
          } else {
            this.showToastMessage('Update failed');
          }
        } catch (error) {
          this.showToastMessage('Update failed');
        } finally {
          // Set submitInProgress back to false when the API call is complete (whether successful or not)
          this.submitInProgress = false;
        }
      } else {
        await this.$router.push({
          name: 'chatbot_index', // Name of the route to redirect to
          params: { accountId: this.currentAccountId }, // Parameters to pass to the route if any
        });
      }
    },
    showToastMessage(message) {
      this.toastMessage = message;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 5000); // 5 seconds
    },
  },
};
</script>

<style scoped>
.spinner-container {
  display: flex;
  justify-content: center;
  align-items: center;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(255, 255, 255, 0.5);
}
.bold-dark-text {
  color: #000000;
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
</style>
