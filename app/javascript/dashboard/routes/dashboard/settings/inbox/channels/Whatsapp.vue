<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
// import Twilio from './Twilio.vue';
// import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
// import CloudWhatsapp from './CloudWhatsapp.vue';
import Whapi from './Whapi.vue';

export default {
  components: {
    PageHeader,
    // Twilio,
    // ThreeSixtyDialogWhatsapp,
    // CloudWhatsapp,
    Whapi,
  },
  props: {
    disabledAutoRoute: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      provider: 'whapi',
    };
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="flex-shrink-0 flex-grow-0">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <!-- <option value="whatsapp_cloud">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
          </option>
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
          </option> -->
          <option value="whapi">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHAPI') }}
          </option>
        </select>
      </label>
    </div>
    <Whapi
      v-if="provider === 'whapi'"
      :disabled-auto-route="disabledAutoRoute"
    />
    <!-- <Twilio v-else-if="provider === 'twilio'" type="whatsapp" />
    <ThreeSixtyDialogWhatsapp v-else-if="provider === '360dialog'" /> -->
    <!-- <CloudWhatsapp v-else /> -->
  </div>
</template>
