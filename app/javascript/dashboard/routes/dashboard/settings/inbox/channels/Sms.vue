<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <twilio type="sms"></twilio>
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
