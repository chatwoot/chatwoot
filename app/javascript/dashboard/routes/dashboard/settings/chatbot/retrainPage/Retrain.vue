<template>
  <div>
    <div class="flex flex-row w-3/4 max-w-3/4 p-6">
      <upload-files @uploadTypeSelected="handleUploadTypeSelected" />
      <upload-area
        v-model="fetching"
        :progress="progress"
        :upload-type="currentUploadType"
        :saved-files="savedFiles"
        @start-progress="startProgress"
        @end-progress="endProgress"
        @retrain-chatbot="retrainChatbot"
        @remove-file="handleRemoveFile"
      />
      <detected-characters
        :detected-char="totalDetectedChar"
        :account-char-limit="accountCharLimit"
      />
    </div>
    <woot-submit-button
      type="submit"
      :button-text="$t('CHATBOTS.RETRAIN.UPDATE')"
      :loading="uiFlags.isUpdating"
      @click="retrainChatbot"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import configMixin from 'shared/mixins/configMixin';
import alertMixin from 'shared/mixins/alertMixin';
import UploadFiles from './UploadFiles.vue';
import UploadArea from './UploadArea.vue';
import DetectedCharacters from '../DetectedCharacters.vue';

export default {
  components: {
    UploadFiles,
    UploadArea,
    DetectedCharacters,
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
      currentUploadType: 'file',
      fetching: false,
      progress: 0,
      progressInterval: null,
      savedFiles: [],
      savedFilesCharCount: 0,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      accountId: 'getCurrentAccountId',
      uiFlags: 'chatbots/getUIFlags',
      files: 'chatbots/getFiles',
      text: 'chatbots/getText',
      links: 'chatbots/getLinks',
      detectedChar: 'chatbots/getChar',
    }),
    currentChatbotId() {
      return this.$route.params.chatbotId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.chatbot.inbox_id);
    },
    accountCharLimit() {
      const currentAccount = this.getAccount(this.accountId);
      return currentAccount.custom_attributes.chatbot_char_limit;
    },
    limitExceeded() {
      return this.detectedChar > this.accountCharLimit;
    },
    totalDetectedChar() {
      return this.detectedChar + this.savedFilesCharCount;
    },
  },
  mounted() {
    this.$store
      .dispatch('chatbots/getSavedData', this.currentChatbotId)
      .then(response => {
        this.savedFiles =
          response.length > 0
            ? response.map(file => {
                this.savedFilesCharCount += file.metadata.char_count;
                return file;
              })
            : [];
      });
  },
  methods: {
    handleUploadTypeSelected(type) {
      this.currentUploadType = type;
    },
    startProgress() {
      this.progress = 0;
      this.fetching = true;
      this.progressInterval = setInterval(() => {
        if (this.progress < 100) {
          this.progress += 1;
        } else {
          this.fetching = false;
          clearInterval(this.progressInterval);
        }
      }, 5000);
    },
    endProgress() {
      this.progress = 100;
    },
    handleRemoveFile(filename) {
      if (this.savedFiles.length > 0) {
        this.savedFiles = this.savedFiles.filter(
          file => file.filename !== filename
        );
      }
    },
    async retrainChatbot() {
      const payload = {
        accountId: this.accountId,
        chatbotId: this.currentChatbotId,
        files: this.files,
        text: this.text,
        urls: this.links,
      };
      await this.$store.dispatch('chatbots/retrain', payload);
      this.$router.push({ name: 'chatbots_index' });
    },
  },
};
</script>
