<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <woot-button
      class-names="button--fixed-top"
      color-scheme="primary"
      @click="connectToInbox"
    >
      {{ $t('CHATBOTS.FORM.CONNECT_INBOX') }}
    </woot-button>
    <page-header
      :header-title="$t('CHATBOTS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('CHATBOTS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-wrap">
      <upload-files @uploadTypeSelected="handleUploadTypeSelected" />
      <upload-area :upload-type="currentUploadType" />
    </div>
  </div>
</template>

<script>
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import alertMixin from 'shared/mixins/alertMixin';
import UploadFiles from '../UploadFiles.vue';
import UploadArea from '../UploadArea.vue';

export default {
  components: {
    PageHeader,
    UploadFiles,
    UploadArea,
  },
  mixins: [alertMixin],
  data() {
    return {
      enabledFeatures: {},
      currentUploadType: 'website',
    };
  },
  methods: {
    handleUploadTypeSelected(type) {
      this.currentUploadType = type;
    },
    async connectToInbox() {
      router.replace({
        name: 'chatbots_connect_inbox',
      });
    },
  },
};
</script>
