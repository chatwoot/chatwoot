<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    LoadingState,
    SettingsSection,
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedAgentBotId: null,
      selectedSurveyId: null,
    };
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
      surveys: 'surveys/getSurveys',
      isFetchingSurveys: 'surveys/getUIFlags',
    }),
    activeInbox() {
      return this.inbox;
    },
    activeAgentBot() {
      return this.$store.getters['agentBots/getActiveAgentBot'](this.inbox.id);
    },
    activeSurvey() {
      return this.$store.getters['surveys/getSurvey'](
        this.activeInbox?.survey_id
      );
    },
  },
  watch: {
    activeAgentBot() {
      this.selectedAgentBotId = this.activeAgentBot?.id || null;
    },
    'activeInbox.survey_id': {
      immediate: true,
      handler(surveyId) {
        if (surveyId) {
          this.selectedSurveyId = surveyId;
        }
      },
    },
  },
  mounted() {
    this.$store.dispatch('agentBots/get');
    this.$store.dispatch('agentBots/fetchAgentBotInbox', this.inbox.id);
    this.fetchSurveys();
  },

  methods: {
    async fetchSurveys() {
      try {
        await this.$store.dispatch('surveys/get');
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE'));
      }
    },
    async updateActiveAgentBot() {
      try {
        await this.$store.dispatch('agentBots/setAgentBotInbox', {
          inboxId: this.inbox.id,
          botId: this.selectedAgentBotId || undefined,
        });

        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE'));
      }
    },
    async updateSurveyAssignment() {
      try {
        await this.$store.dispatch('inboxes/setSurvey', {
          inboxId: this.inbox.id,
          surveyId: this.selectedSurveyId,
        });
        useAlert(this.$t('AGENT_BOTS.SURVEY.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.SURVEY.ERROR_MESSAGE'));
      }
    },
    async disconnectBot() {
      try {
        await this.$store.dispatch('agentBots/disconnectBot', {
          inboxId: this.inbox.id,
        });
        useAlert(
          this.$t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECTED_SUCCESS_MESSAGE')
        );
      } catch (error) {
        useAlert(
          error?.message ||
            this.$t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECTED_ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <LoadingState
      v-if="
        uiFlags.isFetching ||
        uiFlags.isFetchingAgentBot ||
        isFetchingSurveys.isFetching
      "
    />
    <form
      v-else
      class="flex flex-wrap mx-0"
      @submit.prevent="updateActiveAgentBot"
    >
      <!-- Bot Assignment Section -->
      <SettingsSection
        :title="$t('AGENT_BOTS.BOT_CONFIGURATION.TITLE')"
        :sub-title="$t('AGENT_BOTS.BOT_CONFIGURATION.DESC')"
      >
        <div>
          <label>
            <select v-model="selectedAgentBotId">
              <option value="" disabled selected>
                {{ $t('AGENT_BOTS.BOT_CONFIGURATION.SELECT_PLACEHOLDER') }}
              </option>
              <option
                v-for="agentBot in agentBots"
                :key="agentBot.id"
                :value="agentBot.id"
              >
                {{ agentBot.name }}
              </option>
            </select>
          </label>
        </div>
      </SettingsSection>

      <!-- Survey Assignment Section -->
      <SettingsSection
        :title="$t('AGENT_BOTS.SURVEY.TITLE')"
        :sub-title="$t('AGENT_BOTS.SURVEY.DESC')"
      >
        <div class="space-y-2">
          <select
            v-model="selectedSurveyId"
            class="w-full rounded border-slate-200 focus:border-woot-500 focus:ring-0"
            @change="updateSurveyAssignment"
          >
            <option :value="null">
              {{ $t('AGENT_BOTS.SURVEY.SELECT_PLACEHOLDER') }}
            </option>
            <option
              v-for="survey in surveys"
              :key="survey.id"
              :value="survey.id"
            >
              {{ survey.name }}
            </option>
          </select>
        </div>
      </SettingsSection>

      <div class="button-container space-x-2">
        <NextButton
          type="submit"
          :label="$t('AGENT_BOTS.BOT_CONFIGURATION.SUBMIT')"
          :is-loading="uiFlags.isSettingAgentBot"
        />
        <NextButton
          v-if="selectedAgentBotId"
          type="button"
          :disabled="!selectedAgentBotId"
          :is-loading="uiFlags.isDisconnecting"
          faded
          ruby
          @click="disconnectBot"
        >
          {{ $t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECT') }}
        </NextButton>
      </div>
    </form>
  </div>
</template>
