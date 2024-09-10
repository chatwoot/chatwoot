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
    <page-header
      :header-title="$t('CHATBOTS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('CHATBOTS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-row w-full max-w-full">
      <upload-files @uploadTypeSelected="handleUploadTypeSelected" />
      <upload-area
        v-model="fetching"
        :progress="progress"
        :upload-type="currentUploadType"
        @start-progress="startProgress"
        @end-progress="endProgress"
      />
      <detected-characters
        :detected-char="detectedChar"
        :account-char-limit="accountCharLimit"
      />
    </div>
  </div>
</template>

<script>
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import alertMixin from 'shared/mixins/alertMixin';
import UploadFiles from '../UploadFiles.vue';
import UploadArea from '../UploadArea.vue';
import DetectedCharacters from '../DetectedCharacters.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    PageHeader,
    UploadFiles,
    UploadArea,
    DetectedCharacters,
  },
  mixins: [alertMixin],
  data() {
    return {
      enabledFeatures: {},
      currentUploadType: 'file',
      fetching: false,
      progress: 0,
      progressInterval: null,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      accountId: 'getCurrentAccountId',
      files: 'chatbots/getFiles',
      links: 'chatbots/getLinks',
      detectedChar: 'chatbots/getChar',
    }),
    accountCharLimit() {
      const currentAccount = this.getAccount(this.accountId);
      return currentAccount.custom_attributes.chatbot_char_limit || 1000000;
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
        } else {
          this.fetching = false;
          clearInterval(this.progressInterval);
        }
      }, 5000);
    },
    endProgress() {
      this.progress = 100;
    },
    async connectToInbox() {
      router.replace({
        name: 'chatbots_connect_inbox',
      });
    },
  },
};
</script>
