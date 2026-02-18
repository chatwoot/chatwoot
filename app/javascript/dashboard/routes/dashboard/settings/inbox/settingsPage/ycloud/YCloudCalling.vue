<script>
import YCloudAPI from 'dashboard/api/ycloud';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { SettingsSection, NextButton },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      callTo: '',
      activeCallId: '',
      callStatus: '',
      lastCallEvent: null,
    };
  },
  computed: {
    providerConfig() {
      return this.inbox.provider_config || {};
    },
  },
  mounted() {
    this.lastCallEvent = (this.providerConfig.last_events || {}).call_event || null;
  },
  methods: {
    async connectCall() {
      if (!this.callTo) return;
      try {
        const res = await YCloudAPI.connectCall(this.inbox.id, { to: this.callTo });
        this.activeCallId = res.data.callId || res.data.id || '';
        this.callStatus = 'connecting';
        useAlert(this.$t('YCLOUD.CALLING.CONNECT_SUCCESS'));
      } catch {
        useAlert(this.$t('YCLOUD.CALLING.CONNECT_ERROR'));
      }
    },
    async terminateCall() {
      if (!this.activeCallId) return;
      try {
        await YCloudAPI.terminateCall(this.inbox.id, { callId: this.activeCallId });
        this.callStatus = 'terminated';
        useAlert(this.$t('YCLOUD.CALLING.TERMINATE_SUCCESS'));
      } catch {
        useAlert(this.$t('YCLOUD.CALLING.TERMINATE_ERROR'));
      }
    },
    async rejectCall() {
      if (!this.activeCallId) return;
      try {
        await YCloudAPI.rejectCall(this.inbox.id, { callId: this.activeCallId });
        this.callStatus = 'rejected';
        useAlert(this.$t('YCLOUD.CALLING.REJECT_SUCCESS'));
      } catch {
        useAlert(this.$t('YCLOUD.CALLING.REJECT_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="py-4">
    <SettingsSection
      :title="$t('YCLOUD.CALLING.TITLE')"
      :sub-title="$t('YCLOUD.CALLING.DESC')"
    >
      <div class="p-4 bg-n-slate-1 rounded-lg">
        <label class="block mb-3">
          {{ $t('YCLOUD.CALLING.PHONE_NUMBER') }}
          <input v-model="callTo" type="tel" class="mt-1" placeholder="+1234567890" />
        </label>
        <div class="flex gap-2 mb-4">
          <NextButton :label="$t('YCLOUD.CALLING.CONNECT')" color="blue" @click="connectCall" />
          <NextButton v-if="activeCallId" :label="$t('YCLOUD.CALLING.TERMINATE')" color="red" variant="ghost" @click="terminateCall" />
          <NextButton v-if="activeCallId" :label="$t('YCLOUD.CALLING.REJECT')" color="red" variant="ghost" @click="rejectCall" />
        </div>
        <div v-if="activeCallId" class="text-sm">
          <p><strong>{{ $t('YCLOUD.CALLING.CALL_ID') }}:</strong> {{ activeCallId }}</p>
          <p><strong>{{ $t('YCLOUD.CALLING.STATUS_LABEL') }}:</strong> {{ callStatus }}</p>
        </div>
      </div>
    </SettingsSection>

    <!-- Last Call Event -->
    <SettingsSection
      :title="$t('YCLOUD.CALLING.LAST_EVENT')"
      :sub-title="$t('YCLOUD.CALLING.LAST_EVENT_DESC')"
      :show-border="false"
    >
      <div v-if="lastCallEvent" class="p-4 bg-n-slate-1 rounded-lg">
        <p class="text-sm"><strong>Call ID:</strong> {{ lastCallEvent.call_id }}</p>
        <p class="text-sm"><strong>Event:</strong> {{ lastCallEvent.event }}</p>
        <p class="text-sm"><strong>Status:</strong> {{ lastCallEvent.status }}</p>
        <p class="text-sm"><strong>From:</strong> {{ lastCallEvent.from }}</p>
        <p class="text-sm"><strong>To:</strong> {{ lastCallEvent.to }}</p>
        <p class="text-xs text-n-slate-11 mt-1">{{ lastCallEvent.timestamp }}</p>
      </div>
      <p v-else class="text-n-slate-11">{{ $t('YCLOUD.CALLING.NO_EVENTS') }}</p>
    </SettingsSection>
  </div>
</template>
