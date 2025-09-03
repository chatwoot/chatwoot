<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
// import Twilio from './Twilio.vue';
// import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import Whapi from './Whapi.vue';

export default {
  components: {
    PageHeader,
    // Twilio,
    // ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    Whapi,
  },
  props: {
    disabledAutoRoute: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['stepChanged'],
  data() {
    return {
      provider: 'whapi',
      whapiStep: 'name',
    };
  },
  methods: {
    handleStepChanged(step) {
      this.whapiStep = step;
      this.$emit('stepChanged', step);
    },
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
    <div class="mb-4">
      <a
        href="https://doc.clickup.com/9013924102/d/h/8cmb486-4633/999a328108d91cd"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-2 text-sm text-n-brand dark:text-n-lightBrand hover:underline"
      >
        <fluent-icon icon="video" size="16" />
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.WATCH_VIDEO') }}
      </a>
    </div>
    <div class="flex-shrink-0 flex-grow-0">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider" :disabled="whapiStep !== 'name'">
          <option value="whatsapp_cloud">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
          </option>
          <!-- <option value="twilio">
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
      @step-changed="handleStepChanged"
    />
    <!-- <Twilio v-else-if="provider === 'twilio'" type="whatsapp" />
    <ThreeSixtyDialogWhatsapp v-else-if="provider === '360dialog'" /> -->
    <CloudWhatsapp v-else-if="provider === 'whatsapp_cloud'" />
  </div>
</template>
