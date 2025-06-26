<script>
/* eslint-env browser */
import { useAccount } from 'dashboard/composables/useAccount';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  setup() {
    const { accountId } = useAccount();
    return {
      accountId,
    };
  },

  data() {
    return {
      errorStateMessage: this.$route.query.error,
    };
  },

  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <div class="flex flex-col items-center justify-center h-full text-center">
      <p class="text-danger mb-5 text-red-400">
        {{ errorStateMessage }}
      </p>
      <a
        :href="`/zalo/callback/new?account_id=${accountId}`"
        class="button icon-button rounded-md flex justify-center items-center gap-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 border border-solid border-slate-200 dark:border-slate-700 hover:border-woot-500 dark:hover:border-woot-500 transition-all duration-200 ease-in px-4 py-2"
      >
        <img
          width="24"
          src="~dashboard/assets/images/channels/zalo.png"
          alt="Zalo-logo"
        />
        <span>{{ $t('INBOX_MGMT.ADD.ZALO.CONNECT') }}</span>
      </a>
      <p class="py-6">
        {{
          useInstallationName(
            $t('INBOX_MGMT.ADD.ZALO.HELP'),
            globalConfig.installationName
          )
        }}
      </p>
    </div>
  </div>
</template>
