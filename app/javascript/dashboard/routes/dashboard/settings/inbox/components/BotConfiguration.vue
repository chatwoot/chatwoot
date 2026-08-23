<script>
import { mapGetters } from 'shared/store/createStore';
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

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
      botFetchError: null,
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
    agentBotOptions() {
      return this.agentBots.map(bot => ({ value: bot.id, label: bot.name }));
    },
  },
  watch: {
    activeAgentBot: {
      handler(newVal) {
        if (newVal && newVal.id) {
          this.selectedAgentBotId = newVal.id;
        } else if (!newVal || !newVal.id) {
          // keep existing selection if user already picked, otherwise clear
          // ensures placeholder shows when no bot is connected
          if (
            !this.selectedAgentBotId ||
            this.selectedAgentBotId === newVal?.id
          ) {
            this.selectedAgentBotId = null;
          }
        }
      },
      immediate: true,
    },
    currentInboxId: {
      handler(newId, oldId) {
        if (newId && newId !== oldId) {
          this.$store.dispatch('agentBots/fetchAgentBotInbox', newId);
        }
      },
      immediate: false,
    },
  },
  mounted() {
    this.fetchBotData();
  },

  methods: {
    async fetchBotData() {
      try {
        await this.$store.dispatch('agentBots/get');
        this.botFetchError = null;
      } catch (error) {
        this.botFetchError = parseAPIErrorResponse(error);
      }
      if (this.currentInboxId) {
        this.$store.dispatch(
          'agentBots/fetchAgentBotInbox',
          this.currentInboxId
        );
      }
    },
    async updateActiveAgentBot() {
      try {
        await this.$store.dispatch('agentBots/setAgentBotInbox', {
          inboxId: this.currentInboxId,
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
          inboxId: this.currentInboxId,
        });
        this.selectedAgentBotId = null;
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
  <div class="mx-6 max-w-4xl">
    <LoadingState v-if="uiFlags.isFetching || uiFlags.isFetchingAgentBot" />
    <form v-else @submit.prevent="updateActiveAgentBot">
      <SettingsFieldSection
        :label="$t('AGENT_BOTS.BOT_CONFIGURATION.TITLE')"
        :help-text="$t('AGENT_BOTS.BOT_CONFIGURATION.DESC')"
        class="[&>div]:!items-start"
      >
        <SelectInput
          v-model="selectedAgentBotId"
          :placeholder="$t('AGENT_BOTS.BOT_CONFIGURATION.SELECT_PLACEHOLDER')"
          :options="agentBotOptions"
        />
        <p
          v-if="!uiFlags.isFetching && botFetchError"
          class="text-sm text-n-ruby-11 mt-2"
        >
          {{ botFetchError }}
        </p>
        <p
          v-else-if="!uiFlags.isFetching && !agentBotOptions.length"
          class="text-sm text-n-slate-11 mt-2"
        >
          {{ $t('AGENT_BOTS.BOT_CONFIGURATION.EMPTY_STATE') }}
        </p>
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
    </form>
  </div>
</template>
