<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label>
        {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.TWILIO') }}
          </option>
          <option value="360dialog">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.BANDWIDTH') }}
          </option>
        </select>
      </label>
    </div>
    <twilio v-if="provider === 'twilio'" type="sms" />
    <bandwidth-sms v-else />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import BandwidthSms from './BandwidthSms.vue';
import Twilio from './Twilio.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    BandwidthSms,
  },
  data() {
    return {
      provider: 'twilio',
    };
  },
};
</script>
