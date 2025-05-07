<script>
import PageHeader from '../../../../dashboard/routes/dashboard/settings/SettingsSubPageHeader.vue';
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

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0"
  >
    <div class="w-full flex-shrink-0 flex-grow-0 max-w-full">
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
    <Twilio v-if="provider === 'twilio'" type="sms" />
    <BandwidthSms v-else />
  </div>
</template>
