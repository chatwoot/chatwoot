<template>
  <csml-bot-editor
    v-if="agentBot.id"
    :agent-bot="agentBot"
    @submit="updateBot"
  />
  <div v-else class="column content-box no-padding">
    <spinner />
  </div>
</template>
<script>
import Spinner from 'shared/components/Spinner';
import CsmlBotEditor from '../components/CSMLBotEditor.vue';
import alertMixin from 'shared/mixins/alertMixin';

import { mapGetters } from 'vuex';
export default {
  components: { Spinner, CsmlBotEditor },
  mixins: [alertMixin],
  computed: {
    ...mapGetters({ uiFlags: 'agentBots/uiFlags' }),
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
        this.showAlert(this.$t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(
          this.$t('AGENT_BOTS.CSML_BOT_EDITOR.BOT_CONFIG.API_ERROR')
        );
      }
    },
  },
};
</script>
