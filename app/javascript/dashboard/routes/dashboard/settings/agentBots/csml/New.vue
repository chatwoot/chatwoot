<template>
  <csml-bot-editor @submit="saveBot" />
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import CsmlBotEditor from '../components/CSMLBotEditor.vue';
export default {
  components: { CsmlBotEditor },
  mixins: [alertMixin],
  methods: {
    async saveBot(bot) {
      try {
        await this.$store.dispatch('agentBots/create', {
          name: bot.name,
          description: bot.description,
          bot_type: 'csml',
          bot_config: { csml_content: bot.csmlContent },
        });
        this.showAlert(this.$t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_BOTS.ADD.FORM.BOT_CONFIG.API_ERROR'));
      }
    },
  },
};
</script>
