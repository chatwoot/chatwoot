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

  methods: {
    async shopeeAuthorize() {
      let redirectUri = `${window.location.origin}/shopee/callback/${this.accountId}`;
      const authUri = 'https://open.shopee.com/auth';
      authUri += `?auth_type=seller&response_type=code&partner_id=${window.chatwootConfig.shopeePartnerId}&redirect_uri=${redirectUri}`;
      window.location.href = authUri;
    },
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
        href="#"
        class="button icon-button rounded-md"
        @click="shopeeAuthorize()"
      >
        <img
          class="w-auto"
          height="20"
          src="~dashboard/assets/images/channels/shopee_connect.png"
          alt="Shopee-logo"
        />
        <span>{{ $t('INBOX_MGMT.ADD.SHOPEE.CONNECT') }}</span>
      </a>
      <p class="py-6">
        {{
          useInstallationName(
            $t('INBOX_MGMT.ADD.SHOPEE.HELP'),
            globalConfig.installationName
          )
        }}
      </p>
    </div>
  </div>
</template>
