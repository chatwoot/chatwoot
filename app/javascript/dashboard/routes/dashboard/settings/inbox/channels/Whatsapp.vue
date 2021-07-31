<template>
  <div class="wizard-body small-9 columns">
     <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
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
