<template>
  <csml-bot-editor :agent-bot="{ bot_config: {} }" @submit="saveBot" />
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { frontendURL } from '../../../../../helper/URLHelper';
import CsmlBotEditor from '../components/CSMLBotEditor.vue';

export default {
  components: { CsmlBotEditor },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    async saveBot(bot) {
      try {
        const agentBot = await this.$store.dispatch('agentBots/create', {
          name: bot.name,
          description: bot.description,
          bot_type: 'csml',
          bot_config: { csml_content: bot.csmlContent },
        });
        if (agentBot) {
          this.$router.replace(
            frontendURL(
              `accounts/${this.accountId}/settings/agent-bots/csml/${agentBot.id}`
            )
          );
        }
        useAlert(this.$t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.ADD.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
