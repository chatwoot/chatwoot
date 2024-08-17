<script>
import { useAlert } from 'dashboard/composables';
import Spinner from 'shared/components/Spinner.vue';
import CsmlBotEditor from '../components/CSMLBotEditor.vue';

export default {
  components: { Spinner, CsmlBotEditor },
  computed: {
    agentBot() {
      return this.$store.getters['agentBots/getBot'](this.$route.params.botId);
    },
  },
  mounted() {
    this.$store.dispatch('agentBots/show', this.$route.params.botId);
  },
  methods: {
    async updateBot(bot) {
      try {
        await this.$store.dispatch('agentBots/update', {
          id: bot.id,
          name: bot.name,
          description: bot.description,
          bot_type: 'csml',
          bot_config: { csml_content: bot.csmlContent },
        });
        useAlert(this.$t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.CSML_BOT_EDITOR.BOT_CONFIG.API_ERROR'));
      }
    },
  },
};
</script>

<template>
  <CsmlBotEditor v-if="agentBot.id" :agent-bot="agentBot" @submit="updateBot" />
  <div v-else class="flex flex-col h-auto overflow-auto no-padding">
    <Spinner />
  </div>
</template>
