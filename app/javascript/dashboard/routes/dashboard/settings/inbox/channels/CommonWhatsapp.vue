<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />

    <wpp-connect-form />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader';
import WppConnectForm from './WppConnectForm';

export default {
  components: {
    PageHeader,
    WppConnectForm,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
    };
  },
};
</script>
