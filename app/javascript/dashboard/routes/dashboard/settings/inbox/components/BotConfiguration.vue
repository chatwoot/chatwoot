<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';

export default {
  components: {
    LoadingState,
    SettingsFieldSection,
    NextButton,
    SelectInput,
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
      selectedObserverBotId: null,
    };
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    currentInboxId() {
      return this.inbox?.id || this.$route.params.inboxId;
    },
    activeAgentBot() {
      return this.$store.getters['agentBots/getActiveAgentBot'](
        this.currentInboxId
      );
    },
    observerBots() {
      return this.$store.getters['agentBots/getObserverBots'](
        this.currentInboxId
      );
    },
    // The responder and the current observers are not offered again.
    observerCandidates() {
      const taken = new Set([
        this.activeAgentBot?.id,
        ...this.observerBots.map(bot => bot.id),
      ]);
      return this.agentBots
        .filter(bot => !taken.has(bot.id))
        .map(bot => ({ value: bot.id, label: bot.name }));
    },
  },
  watch: {
    activeAgentBot() {
      this.selectedAgentBotId = this.activeAgentBot.id;
    },
  },
  mounted() {
    this.fetchBotData();
  },

  methods: {
    fetchBotData() {
      this.$store.dispatch('agentBots/get');
      this.$store.dispatch('agentBots/fetchAgentBotInbox', this.currentInboxId);
      this.$store.dispatch(
        'agentBots/fetchAgentBotObservers',
        this.currentInboxId
      );
    },
    async updateActiveAgentBot() {
      try {
        await this.$store.dispatch('agentBots/setAgentBotInbox', {
          inboxId: this.inbox.id,
          // Added this to make sure that empty values are not sent to the API
          botId: this.selectedAgentBotId ? this.selectedAgentBotId : undefined,
        });
        useAlert(this.$t('AGENT_BOTS.BOT_CONFIGURATION.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message || this.$t('AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE')
        );
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
    async addObserver() {
      if (!this.selectedObserverBotId) return;
      try {
        await this.$store.dispatch('agentBots/addAgentBotObserver', {
          inboxId: this.inbox.id,
          botId: this.selectedObserverBotId,
        });
        this.selectedObserverBotId = null;
        useAlert(this.$t('AGENT_BOTS.OBSERVERS.ADD_SUCCESS'));
      } catch (error) {
        useAlert(error?.message || this.$t('AGENT_BOTS.OBSERVERS.ADD_ERROR'));
      }
    },
    async removeObserver(botId) {
      try {
        await this.$store.dispatch('agentBots/removeAgentBotObserver', {
          inboxId: this.inbox.id,
          botId,
        });
        useAlert(this.$t('AGENT_BOTS.OBSERVERS.REMOVE_SUCCESS'));
      } catch (error) {
        useAlert(
          error?.message || this.$t('AGENT_BOTS.OBSERVERS.REMOVE_ERROR')
        );
      }
    },
  },
};
</script>

<template>
  <div class="mx-6 max-w-4xl">
    <LoadingState
      v-if="
        uiFlags.isFetching ||
        uiFlags.isFetchingAgentBot ||
        uiFlags.isFetchingObservers
      "
    />
    <form v-else @submit.prevent="updateActiveAgentBot">
      <SettingsFieldSection
        :label="$t('AGENT_BOTS.BOT_CONFIGURATION.TITLE')"
        :help-text="$t('AGENT_BOTS.BOT_CONFIGURATION.DESC')"
        class="[&>div]:!items-start"
      >
        <SelectInput
          v-model="selectedAgentBotId"
          :placeholder="$t('AGENT_BOTS.BOT_CONFIGURATION.SELECT_PLACEHOLDER')"
          :options="agentBots.map(bot => ({ value: bot.id, label: bot.name }))"
        />
        <template #extra>
          <div class="grid grid-cols-1 lg:grid-cols-8 mt-3">
            <div class="col-span-1 lg:col-span-2 invisible" />
            <div class="col-span-1 lg:col-span-6 flex gap-2 mx-1">
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
        </template>
      </SettingsFieldSection>
      <SettingsFieldSection
        :label="$t('AGENT_BOTS.OBSERVERS.TITLE')"
        :help-text="$t('AGENT_BOTS.OBSERVERS.DESC')"
        class="[&>div]:!items-start"
      >
        <div class="flex flex-col gap-3">
          <ul v-if="observerBots.length" class="flex flex-col gap-2">
            <li
              v-for="bot in observerBots"
              :key="bot.id"
              class="flex items-center justify-between gap-2 px-3 py-2 border rounded-lg border-n-weak"
            >
              <span class="text-sm text-n-slate-12">{{ bot.name }}</span>
              <NextButton
                type="button"
                :label="$t('AGENT_BOTS.OBSERVERS.REMOVE')"
                :disabled="uiFlags.isUpdatingObservers"
                xs
                ghost
                ruby
                @click="removeObserver(bot.id)"
              />
            </li>
          </ul>
          <p v-else class="text-sm text-n-slate-11">
            {{ $t('AGENT_BOTS.OBSERVERS.EMPTY') }}
          </p>
          <div class="flex gap-2">
            <SelectInput
              v-model="selectedObserverBotId"
              :placeholder="$t('AGENT_BOTS.OBSERVERS.SELECT_PLACEHOLDER')"
              :options="observerCandidates"
            />
            <NextButton
              type="button"
              :label="$t('AGENT_BOTS.OBSERVERS.ADD')"
              :disabled="!selectedObserverBotId"
              :is-loading="uiFlags.isUpdatingObservers"
              @click="addObserver"
            />
          </div>
        </div>
      </SettingsFieldSection>
    </form>
  </div>
</template>
