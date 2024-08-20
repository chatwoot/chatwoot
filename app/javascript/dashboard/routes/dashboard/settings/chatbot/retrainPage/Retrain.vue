<template>
  <div>
    <settings-section
      :title="$t('CHATBOTS.RETRAIN.TITLE')"
      :sub-title="$t('CHATBOTS.RETRAIN.SUBTITLE')"
      :show-border="false"
    >
      <div class="flex flex-wrap">
        <upload-files @uploadTypeSelected="handleUploadTypeSelected" />
        <upload-area :upload-type="currentUploadType" />
      </div>
    </settings-section>
    <settings-section :show-border="false">
      <woot-submit-button
        type="submit"
        :button-text="$t('CHATBOTS.RETRAIN.UPDATE')"
        :loading="uiFlags.isUpdating"
        @click="retrainChatbot"
      />
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import configMixin from 'shared/mixins/configMixin';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import UploadFiles from './UploadFiles.vue';
import UploadArea from './UploadArea.vue';

export default {
  components: {
    SettingsSection,
    UploadFiles,
    UploadArea,
  },
  mixins: [alertMixin, configMixin],
  props: {
    chatbot: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      enabledFeatures: {},
      currentUploadType: 'website',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      uiFlags: 'chatbots/getUIFlags',
      files: 'chatbots/getFiles',
      text: 'chatbots/getText',
      urls: 'chatbots/getUrls',
    }),
    currentChatbotId() {
      return this.$route.params.chatbotId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.chatbot.inbox_id);
    },
  },
  methods: {
    handleUploadTypeSelected(type) {
      this.currentUploadType = type;
    },
    async retrainChatbot() {
      let urls = this.urls;
      if (this.inbox.help_center) {
        const portalUrl = `${window.chatwootConfig.hostURL}/hc/${this.inbox.help_center.slug}`;
        urls = `${urls}, ${portalUrl}`;
      }
      const payload = {
        accountId: this.accountId,
        chatbotId: this.currentChatbotId,
        files: this.files,
        text: this.text,
        urls: urls,
      };
      await this.$store.dispatch('chatbots/retrain', payload);
      this.$router.push({ name: 'chatbots_index' });
    },
  },
};
</script>
