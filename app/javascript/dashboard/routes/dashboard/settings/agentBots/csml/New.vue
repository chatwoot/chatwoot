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
        await this.$store.dispatch('bots/create', bot);
        this.showAlert(this.$t('BOT.ADD.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('BOT.ADD.FORM.BOT_CONFIG.API_ERROR'));
      }
    },
  },
};
</script>
