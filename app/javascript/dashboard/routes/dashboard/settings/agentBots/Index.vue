<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns with-right-space">
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('AGENT_BOTS.LIST.LOADING')"
        />
        <table v-else-if="agentBots.length" class="woot-table">
          <tbody>
            <agent-bot-row
              v-for="(agentBot, index) in agentBots"
              :key="agentBot.id"
              :agent-bot="agentBot"
              :index="index"
              :is-deleting="loading[agentBot.id]"
              @delete="onDeleteAgentBot"
              @edit="onEditAgentBot"
            />
          </tbody>
        </table>
        <p v-else class="no-items-error-message">
          {{ $t('AGENT_BOTS.LIST.404') }}
        </p>
      </div>

      <div class="small-4 columns content-box">
        <p v-html="$t('AGENT_BOTS.SIDEBAR_TXT')" />
      </div>
    </div>
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="add-circle"
    >
      <router-link to="csml/new" class="white-text">
        {{ $t('AGENT_BOTS.ADD.TITLE') }}
      </router-link>
    </woot-button>
    <woot-confirm-modal
      ref="confirmDialog"
      :title="$t('AGENT_BOTS.DELETE.TITLE')"
      :description="$t('AGENT_BOTS.DELETE.DESCRIPTION')"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AgentBotRow from './components/AgentBotRow.vue';

export default {
  components: { AgentBotRow },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('agentBots/get');
  },
  methods: {
    async onDeleteAgentBot(id) {
      const ok = await this.$refs.confirmDialog.showConfirmation();
      if (ok) {
        await this.$store.dispatch('bots/delete', id);
        this.showAlert(this.$t('BOT.DELETE.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style scoped>
.bots-list {
  list-style: none;
}
.nowrap {
  white-space: nowrap;
}
.white-text {
  color: white;
}
</style>
