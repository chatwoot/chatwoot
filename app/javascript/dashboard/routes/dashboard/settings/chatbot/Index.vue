<template>
  <div class="flex-1 overflow-auto p-4">
    <!-- <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto"> -->
    <router-link :to="addAccountScoping(`settings/chatbot/create`)">
      <woot-button
        class-names="button--fixed-top"
        color-scheme="success"
        icon="add-circle"
        :button-text="$t('CHATBOT_SETTINGS.NEW_BOT')"
      >
        {{ $t('CHATBOT_SETTINGS.NEW_BOT') }}
      </woot-button>
    </router-link>
    <!-- </div> -->
    <div class="flex flex-row gap-4">
      <div class="w-[60%]">
        <p
          v-if="!chatbotsList.length"
          class="flex h-full items-center flex-col justify-center"
        >
          {{ $t('CHATBOT_SETTINGS.LIST.404') }}
          <router-link
            v-if="isAdmin"
            :to="addAccountScoping('settings/chatbot/create')"
          >
            {{ $t('CHATBOT_SETTINGS.NEW_BOT') }}
          </router-link>
        </p>

        <table v-if="chatbotsList.length" class="woot-table">
          <tbody>
            <tr v-for="chatbot in chatbotsList" :key="chatbot.chatbot_id">
              <td>
                <span class="agent-name">
                  <template
                    v-if="
                      chatbot.chatbot_name === null ||
                      chatbot.chatbot_name === ''
                    "
                  >
                    <span class="chatbot-id">
                      {{ $t('CHATBOT_SETTINGS.CHATBOT') }} -
                      {{ chatbot.chatbot_id.slice(-4) }}
                    </span>
                  </template>
                  <template v-else>
                    {{ chatbot.chatbot_name }}
                  </template>
                </span>
              </td>

              <td>
                <div class="button-wrapper">
                  <router-link
                    :to="
                      addAccountScoping(
                        `settings/chatbot/edit/${chatbot.chatbot_id}@${chatbot.last_trained_at}`
                      )
                    "
                  >
                    <woot-button
                      v-if="isAdmin"
                      v-tooltip.top="$t('CHATBOT_SETTINGS.LIST.EDIT_BOT')"
                      variant="smooth"
                      size="tiny"
                      color-scheme="secondary"
                      class-names="grey-btn"
                      icon="settings"
                    />
                  </router-link>
                  <woot-button
                    v-if="isAdmin"
                    v-tooltip.top="$t('CHATBOT_SETTINGS.DELETE.BUTTON_TEXT')"
                    variant="smooth"
                    color-scheme="alert"
                    size="tiny"
                    icon="dismiss-circle"
                    class-names="grey-btn"
                    :is-loading="loading[chatbot.chatbot_id]"
                    @click="openDeleteModal(chatbot)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="w-[34%]">
        <span
          v-dompurify-html="
            $t('CHATBOT_SETTINGS.SIDEBAR_TXT', {
              installationName: globalConfig.installationName,
            })
          "
        />
      </div>
    </div>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('CHATBOT_SETTINGS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="
        selectedChatbot.chatbot_name || selectedChatbot.chatbot_id
      "
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDeleteModal"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import alertMixin from 'shared/mixins/alertMixin';
import ChatbotAPI from '../../../../api/chatbot';

export default {
  mixins: [adminMixin, accountMixin, alertMixin],
  data() {
    return {
      loading: {},
      showDeletePopup: false,
      selectedChatbot: {},
      chatbotsList: [],
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentAccountId: 'getCurrentAccountId',
    }),
    formattedLastTrainedAt() {
      return lastTrainedAt => {
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
          return `${year}/${month}/${day}, ${hours}:${minutes}:${seconds}`;
        }
        return lastTrainedAt;
      };
    },
    deleteConfirmText() {
      return `${this.$t('CHATBOT_SETTINGS.DELETE.CONFIRM.YES')} ${
        this.selectedChatbot.chatbot_name || this.selectedChatbot.chatbot_id
      }`;
    },
    deleteRejectText() {
      return this.$t('CHATBOT_SETTINGS.DELETE.CONFIRM.NO');
    },
    confirmDeleteTitle() {
      return this.$t('CHATBOT_SETTINGS.DELETE.CONFIRM.TITLE', {
        name:
          this.selectedChatbot.chatbot_name || this.selectedChatbot.chatbot_id,
      });
    },
    confirmPlaceHolderText() {
      return `${this.$t('CHATBOT_SETTINGS.DELETE.CONFIRM.PLACE_HOLDER', {
        name:
          this.selectedChatbot.chatbot_name || this.selectedChatbot.chatbot_id,
      })}`;
    },
  },
  async created() {
    const res = await ChatbotAPI.fetchChatbotsWithAccountId(
      this.currentAccountId
    );
    this.chatbotsList = res.data;
  },
  methods: {
    openDeleteModal(chatbot) {
      this.selectedChatbot = chatbot;
      this.showDeletePopup = true;
    },
    closeDeleteModal() {
      this.selectedChatbot = {};
      this.showDeletePopup = false;
    },
    confirmDeletion() {
      const chatbotId = this.selectedChatbot.chatbot_id;
      ChatbotAPI.deleteChatbotWithChatbotId(chatbotId);
      this.closeDeleteModal();
      window.location.reload();
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
