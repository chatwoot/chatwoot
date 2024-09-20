<script>
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import UploadFiles from '../UploadFiles.vue';
import UploadArea from '../UploadArea.vue';
import DetectedCharacters from '../DetectedCharacters.vue';
import { mapGetters } from 'vuex';
import ChatbotAPI from '../../../../../api/chatbots';

export default {
  components: {
    PageHeader,
    UploadFiles,
    UploadArea,
    DetectedCharacters,
  },
  data() {
    return {
      enabledFeatures: {},
      currentUploadType: 'website',
      fetching: false,
      progress: 0,
      progressInterval: null,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      accountId: 'getCurrentAccountId',
      links: 'chatbots/getLinks',
      detectedChar: 'chatbots/getChar',
    }),
    accountCharLimit() {
      const currentAccount = this.getAccount(this.accountId);
      return currentAccount?.custom_attributes?.chatbot_char_limit ?? 1000000;
    },
    limitExceeded() {
      return this.detectedChar > this.accountCharLimit;
    },
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
    async connectToInbox() {
      router.replace({
        name: 'chatbots_connect_inbox',
      });
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-5 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <woot-button
      class-names="button--fixed-top"
      color-scheme="primary"
      :disabled="fetching || limitExceeded"
      @click="connectToInbox"
    >
      {{ $t('CHATBOTS.FORM.CONNECT_INBOX') }}
    </woot-button>
    <PageHeader
      :header-title="$t('CHATBOTS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('CHATBOTS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-row w-full max-w-full">
      <UploadFiles @uploadTypeSelected="handleUploadTypeSelected" />
      <UploadArea
        v-model="fetching"
        :progress="progress"
        :upload-type="currentUploadType"
        @startProgress="startProgress"
      />
      <DetectedCharacters
        :detected-char="detectedChar"
        :account-char-limit="accountCharLimit"
      />
    </div>
  </div>
</template>
