<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import SettingsSection from '../../../../components/SettingsSection.vue';
import Retrain from './retrainPage/Retrain.vue';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

export default {
  components: {
    SettingIntroBanner,
    SettingsSection,
    Retrain,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      selectedTabIndex: 0,
      selectedChatbotName: '',
      selectedChatbotReplyOnNoRelevantResult: '',
      selectedChatbotReplyOnConnectWithTeam: '',
      chatbotEnabled: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'chatbots/getUIFlags',
    }),
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    tabs() {
      let tabs = [
        {
          key: 'chatbot_settings',
          name: this.$t('CHATBOTS.TABS.SETTINGS'),
        },
        {
          key: 'retrain',
          name: this.$t('CHATBOTS.TABS.RETRAIN'),
        },
      ];
      return tabs;
    },
    currentChatbotId() {
      return this.$route.params.chatbotId;
    },
    chatbot() {
      return this.$store.getters['chatbots/getChatbot'](this.currentChatbotId);
    },
  },
  watch: {
    $route(to) {
      if (to.name === 'chatbots_setting') {
        this.fetchChatbot();
      }
    },
  },
  async mounted() {
    this.fetchChatbot();
  },
  validations: {
    selectedChatbotName: { required },
    selectedChatbotReplyOnNoRelevantResult: { required },
    selectedChatbotReplyOnConnectWithTeam: { required },
  },
  methods: {
    async fetchChatbot() {
      this.selectedTabIndex = 0;
      this.$store.dispatch('chatbots/get').then(() => {
        this.selectedChatbotName = this.chatbot.name;
        this.selectedChatbotReplyOnNoRelevantResult =
          this.chatbot.reply_on_no_relevant_result;
        this.selectedChatbotReplyOnConnectWithTeam =
          this.chatbot.reply_on_connect_with_team;
        this.chatbotEnabled = this.chatbot.status === 'Enabled';
      });
    },
    async updateChatbot() {
      try {
        const payload = {
          id: this.currentChatbotId,
          chatbotName: this.selectedChatbotName,
          chatbotReplyOnNoRelevantResult:
            this.selectedChatbotReplyOnNoRelevantResult,
          chatbotReplyOnConnectWithTeam:
            this.selectedChatbotReplyOnConnectWithTeam,
          chatbotStatus: this.chatbotEnabled,
        };
        await this.$store.dispatch('chatbots/update', payload);
        useAlert(this.$t('CHATBOTS.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('CHATBOTS.EDIT.API.ERROR_MESSAGE'));
      }
    },
    onTabChange(selectedTabIndex) {
      this.selectedTabIndex = selectedTabIndex;
    },
  },
};
</script>

<template>
  <div
    class="flex-grow flex-shrink w-full min-w-0 pl-0 pr-0 overflow-auto bg-white settings dark:bg-slate-800"
  >
    <SettingIntroBanner :header-title="selectedChatbotName">
      <woot-tabs
        class="settings--tabs"
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>
    </SettingIntroBanner>

    <div v-if="selectedTabKey === 'chatbot_settings'" class="mx-8">
      <SettingsSection
        :title="$t('CHATBOTS.SETTINGS_POPUP.CHATBOT_UPDATE_TITLE')"
        :sub-title="$t('CHATBOTS.SETTINGS_POPUP.CHATBOT_UPDATE_SUB_TEXT')"
        :show-border="false"
      >
        <woot-input
          v-model.trim="selectedChatbotName"
          class="w-3/4 pb-4"
          :label="$t('CHATBOTS.ADD.CHATBOT_NAME.LABEL')"
          :placeholder="$t('CHATBOTS.ADD.CHATBOT_NAME.PLACEHOLDER')"
        />
        <woot-input
          v-model.trim="selectedChatbotReplyOnNoRelevantResult"
          class="w-3/4 pb-4"
          :label="$t('CHATBOTS.ADD.CHATBOT_REPLY_ON_NO_RESULT.LABEL')"
          :placeholder="
            $t('CHATBOTS.ADD.CHATBOT_REPLY_ON_NO_RESULT.PLACEHOLDER')
          "
        />
        <woot-input
          v-model.trim="selectedChatbotReplyOnConnectWithTeam"
          class="w-3/4 pb-4"
          :label="$t('CHATBOTS.ADD.CHATBOT_REPLY_ON_CONNECT_WITH_TEAM.LABEL')"
          :placeholder="
            $t('CHATBOTS.ADD.CHATBOT_REPLY_ON_CONNECT_WITH_TEAM.PLACEHOLDER')
          "
        />
        <label class="w-3/4 pb-4">
          {{ $t('CHATBOTS.ADD.INBOX_TOGGLE.LABEL') }}
          <select v-model="chatbotEnabled">
            <option :value="true">
              {{ $t('CHATBOTS.ADD.INBOX_TOGGLE.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('CHATBOTS.ADD.INBOX_TOGGLE.DISABLED') }}
            </option>
          </select>
          <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
            {{ $t('CHATBOTS.ADD.INBOX_TOGGLE.HELP_TEXT') }}
          </p>
        </label>
      </SettingsSection>
      <SettingsSection :show-border="false">
        <woot-submit-button
          type="submit"
          :disabled="v$.$invalid"
          :button-text="$t('CHATBOTS.SETTINGS_POPUP.UPDATE')"
          :loading="uiFlags.isUpdating"
          @click="updateChatbot"
        />
      </SettingsSection>
    </div>
    <div v-if="selectedTabKey === 'retrain'" class="mx-8">
      <Retrain :chatbot="chatbot" />
    </div>
  </div>
</template>

<style scoped lang="scss">
.settings--tabs {
  ::v-deep .tabs {
    @apply p-0;
  }
}
</style>
