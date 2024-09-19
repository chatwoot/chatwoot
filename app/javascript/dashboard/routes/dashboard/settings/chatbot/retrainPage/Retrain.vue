<script>
import { mapGetters } from 'vuex';
import UploadFiles from './UploadFiles.vue';
import UploadArea from './UploadArea.vue';
import DetectedCharacters from '../DetectedCharacters.vue';
import ChatbotAPI from '../../../../../api/chatbots';

export default {
  components: {
    UploadFiles,
    UploadArea,
    DetectedCharacters,
  },
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
      return currentAccount?.custom_attributes?.chatbot_char_limit ?? 1000000;
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
        if (response) {
          this.savedFiles =
            response.length > 0
              ? response.map(file => {
                  this.savedFilesCharCount += file.metadata.char_count;
                  return file;
                })
              : [];
        }
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
          this.checkCrawlingStatus();
        } else {
          this.fetching = false;
          clearInterval(this.progressInterval);
        }
      }, 5000);
    },
    endProgress() {
      this.progress = 100;
    },
    checkCrawlingStatus() {
      ChatbotAPI.checkCrawlingStatus().then(response => {
        if (response.data.links_with_char_count) {
          this.endProgress();
          const linksWithCharCount = response.data.links_with_char_count;
          const filteredLinks = linksWithCharCount.filter(link => {
            return !this.links.some(
              existingLink => existingLink.link === link.link
            );
          });
          this.$store.dispatch('chatbots/addLink', filteredLinks);
        }
      });
    },
    removeFile(filename) {
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
      this.$router.push({ name: 'chatbots_wrapper' });
    },
  },
};
</script>

<template>
  <div>
    <div class="flex flex-row w-3/4 max-w-3/4 pt-6 pb-6">
      <UploadFiles @uploadTypeSelected="handleUploadTypeSelected" />
      <UploadArea
        v-model="fetching"
        :progress="progress"
        :upload-type="currentUploadType"
        :saved-files="savedFiles"
        @startProgress="startProgress"
        @retrainChatbot="retrainChatbot"
        @removeFile="removeFile"
      />
      <DetectedCharacters
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
