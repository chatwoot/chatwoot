<template>
  <div class="row content-box full-height">
    <woot-wizard
      class="hide-for-small-only medium-3 columns"
      :global-config="globalConfig"
      :items="items"
    />
    <router-view />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    items() {
      const isSubPageWhatsappCloud =
        this.$route?.params?.sub_page === 'whatsapp' &&
        this.$route?.query?.provider_type === 'whatsapp_cloud';

      return this.$t('INBOX_MGMT.CREATE_FLOW')
        .filter(
          // Here we are filtering out the whatsapp cloud option from the wizard
          // To support facebook login, we need to keep the facebook option
          item =>
            isSubPageWhatsappCloud ||
            item.route !== 'settings_inboxes_page_fb_login'
        )
        .map(item => ({
          ...item,
          body: this.useInstallationName(
            item.body,
            this.globalConfig.installationName
          ),
        }));
    },
  },
};
</script>
