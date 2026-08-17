<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import BandwidthSms from './BandwidthSms.vue';
import Twilio from './Twilio.vue';
import Plivo from './Plivo.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    BandwidthSms,
    Plivo,
  },
  data() {
    return {
      provider: 'twilio',
    };
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <div class="flex-shrink-0 flex-grow-0">
      <label>
        {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.TWILIO') }}
          </option>
          <option value="360dialog">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.BANDWIDTH') }}
          </option>
          <option value="plivo">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.PLIVO') }}
          </option>
        </select>
      </label>
    </div>
    <Twilio v-if="provider === 'twilio'" type="sms" />
    <Plivo v-else-if="provider === 'plivo'" />
    <BandwidthSms v-else />
  </div>
</template>
