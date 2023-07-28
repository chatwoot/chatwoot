<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="whatsapp_cloud">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
          </option>
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
          </option>
          <option value="360dialog">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG') }}
          </option>
        </select>
      </label>
    </div>

    <twilio v-if="provider === 'twilio'" type="whatsapp" />
    <three-sixty-dialog-whatsapp v-else-if="provider === '360dialog'" />
    <cloud-whatsapp v-else />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader';
import Twilio from './Twilio';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp';
import CloudWhatsapp from './CloudWhatsapp';

export default {
  components: {
    PageHeader,
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
    };
  },
  computed: {
    isSubPageWhatsapp() {
      return this.$route?.params?.sub_page === 'whatsapp';
    },
  },
  watch: {
    provider() {
      // Here we are setting the provider in the route query dynamically
      // When the user changes the provider, we are updating the route query
      this.setProviderInRouteQuery();
    },
  },
  methods: {
    setProviderInRouteQuery() {
      // Here we are setting the provider in the route query
      // This is to make sure that only show the FB login option in the wizard
      // Only for the provider-whatsapp_cloud

      if (
        this.$route.query.channel_type !== this.provider &&
        this.isSubPageWhatsapp
      ) {
        this.$router.push({
          name: 'settings_inboxes_page_channel',
          query: {
            provider_type: this.provider,
          },
        });
      }
    },
  },
};
</script>
