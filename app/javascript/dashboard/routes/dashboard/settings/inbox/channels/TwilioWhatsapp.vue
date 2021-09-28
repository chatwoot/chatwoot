<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP_VIA_TWILIO.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP_VIA_TWILIO.DESC')"
    />
		<twilio type="whatsapp"></twilio>
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader';
import Twilio from './Twilio';
export default {
  components: {
    PageHeader,
    Twilio,
  },
};
</script>
