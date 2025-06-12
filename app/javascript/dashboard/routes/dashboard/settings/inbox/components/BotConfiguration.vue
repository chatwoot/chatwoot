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
        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE'));
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
    <LoadingState v-if="uiFlags.isFetching || uiFlags.isFetchingAgentBot" />
    <form
      v-else
      class="flex flex-wrap mx-0"
      @submit.prevent="updateActiveAgentBot"
    >
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
          <div class="button-container space-x-2">
            <NextButton
              type="submit"
              :label="$t('AGENT_BOTS.BOT_CONFIGURATION.SUBMIT')"
              :is-loading="uiFlags.isSettingAgentBot"
            />
            <NextButton
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
        </div>
      </SettingsSection>
    </form>
  </div>
</template>
