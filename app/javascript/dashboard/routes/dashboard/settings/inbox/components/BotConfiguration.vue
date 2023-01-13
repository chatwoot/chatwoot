<template>
  <div class="settings--content">
    <loading-state v-if="uiFlags.isFetching || uiFlags.isFetchingAgentBot" />
    <form v-else class="row" @submit.prevent="updateActiveAgentBot">
      <settings-section
        :title="$t('AGENT_BOTS.BOT_CONFIGURATION.TITLE')"
        :sub-title="$t('AGENT_BOTS.BOT_CONFIGURATION.DESC')"
      >
        <div class="medium-7 columns">
          <label>
            <select v-model="selectedAgentBotId">
              <option value="" disabled selected>{{
                $t('AGENT_BOTS.BOT_CONFIGURATION.SELECT_PLACEHOLDER')
              }}</option>
              <option
                v-for="agentBot in agentBots"
                :key="agentBot.id"
                :value="agentBot.id"
              >
                {{ agentBot.name }}
              </option>
            </select>
          </label>
          <div class="button-container">
            <woot-submit-button
              :button-text="$t('AGENT_BOTS.BOT_CONFIGURATION.SUBMIT')"
              :loading="uiFlags.isSettingAgentBot"
            />
            <woot-button
              type="button"
              :disabled="!selectedAgentBotId"
              :loading="uiFlags.isDisconnecting"
              variant="smooth"
              color-scheme="alert"
              class="button--disconnect"
              @click="disconnectBot"
            >
              {{ $t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECT') }}
            </woot-button>
          </div>
        </div>
      </settings-section>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import SettingsSection from 'dashboard/components/SettingsSection';
import LoadingState from 'dashboard/components/widgets/LoadingState';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    LoadingState,
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedAgentBotId: null,
    };
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    activeAgentBot() {
      return this.$store.getters['agentBots/getActiveAgentBot'](this.inbox.id);
    },
  },
  watch: {
    activeAgentBot() {
      this.selectedAgentBotId = this.activeAgentBot.id;
    },
  },
  mounted() {
    this.$store.dispatch('agentBots/get');
    this.$store.dispatch('agentBots/fetchAgentBotInbox', this.inbox.id);
  },

  methods: {
    async updateActiveAgentBot() {
      try {
        await this.$store.dispatch('agentBots/setAgentBotInbox', {
          inboxId: this.inbox.id,
          // Added this to make sure that empty values are not sent to the API
          botId: this.selectedAgentBotId ? this.selectedAgentBotId : undefined,
        });
        this.showAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE'));
      }
    },
    async disconnectBot() {
      try {
        await this.$store.dispatch('agentBots/disconnectBot', {
          inboxId: this.inbox.id,
        });
        this.showAlert(
          this.$t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECTED_SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
          error?.message ||
            this.$t('AGENT_BOTS.BOT_CONFIGURATION.DISCONNECTED_ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<style scoped lang="scss">
.button--disconnect {
  margin-left: var(--space-small);
}
</style>
