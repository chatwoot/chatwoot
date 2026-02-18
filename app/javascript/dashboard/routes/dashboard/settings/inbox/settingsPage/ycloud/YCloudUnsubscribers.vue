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
      unsubscribers: [],
      webhookEndpoints: [],
      isLoadingUnsubs: false,
      isLoadingWebhooks: false,
      showAddModal: false,
      newUnsub: { customer: '', channel: 'whatsapp' },
      isRotating: false,
    };
  },
  mounted() {
    this.fetchUnsubscribers();
    this.fetchWebhookEndpoints();
  },
  methods: {
    async fetchUnsubscribers() {
      this.isLoadingUnsubs = true;
      try {
        const res = await YCloudAPI.listUnsubscribers(this.inbox.id);
        this.unsubscribers = res.data.items || res.data || [];
      } catch { this.unsubscribers = []; }
      this.isLoadingUnsubs = false;
    },
    async addUnsubscriber() {
      try {
        await YCloudAPI.createUnsubscriber(this.inbox.id, this.newUnsub);
        useAlert(this.$t('YCLOUD.UNSUB.ADD_SUCCESS'));
        this.showAddModal = false;
        this.newUnsub = { customer: '', channel: 'whatsapp' };
        this.fetchUnsubscribers();
      } catch { useAlert(this.$t('YCLOUD.UNSUB.ADD_ERROR')); }
    },
    async removeUnsubscriber(unsub) {
      if (!window.confirm(this.$t('YCLOUD.UNSUB.REMOVE_CONFIRM'))) return;
      try {
        await YCloudAPI.deleteUnsubscriber(this.inbox.id, unsub.customer, unsub.channel);
        useAlert(this.$t('YCLOUD.UNSUB.REMOVE_SUCCESS'));
        this.fetchUnsubscribers();
      } catch { useAlert(this.$t('YCLOUD.UNSUB.REMOVE_ERROR')); }
    },
    async fetchWebhookEndpoints() {
      this.isLoadingWebhooks = true;
      try {
        const res = await YCloudAPI.listWebhookEndpoints(this.inbox.id);
        this.webhookEndpoints = res.data.items || res.data || [];
      } catch { this.webhookEndpoints = []; }
      this.isLoadingWebhooks = false;
    },
    async rotateSecret(endpoint) {
      if (!window.confirm(this.$t('YCLOUD.WEBHOOKS.ROTATE_CONFIRM'))) return;
      this.isRotating = true;
      try {
        await YCloudAPI.rotateWebhookSecret(this.inbox.id, endpoint.id);
        useAlert(this.$t('YCLOUD.WEBHOOKS.ROTATE_SUCCESS'));
        this.fetchWebhookEndpoints();
      } catch { useAlert(this.$t('YCLOUD.WEBHOOKS.ROTATE_ERROR')); }
      this.isRotating = false;
    },
  },
};
</script>

<template>
  <div class="py-4">
    <!-- Unsubscribers -->
    <SettingsSection :title="$t('YCLOUD.UNSUB.TITLE')" :sub-title="$t('YCLOUD.UNSUB.DESC')">
      <div class="flex justify-end mb-4">
        <NextButton :label="$t('YCLOUD.UNSUB.ADD')" icon="i-lucide-plus" @click="showAddModal = true" />
      </div>
      <div v-if="isLoadingUnsubs" class="text-center py-4"><span class="spinner" /></div>
      <div v-else-if="unsubscribers.length === 0" class="text-center py-4 text-n-slate-11">{{ $t('YCLOUD.UNSUB.EMPTY') }}</div>
      <table v-else class="min-w-full">
        <thead>
          <tr class="border-b border-n-weak">
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.UNSUB.CUSTOMER') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.UNSUB.CHANNEL') }}</th>
            <th class="text-right py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.ACTIONS') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in unsubscribers" :key="`${u.customer}-${u.channel}`" class="border-b border-n-weak/50 hover:bg-n-slate-1">
            <td class="py-2 px-3 text-sm">{{ u.customer }}</td>
            <td class="py-2 px-3 text-sm">{{ u.channel }}</td>
            <td class="py-2 px-3 text-right">
              <button class="text-green-600 text-sm hover:underline" @click="removeUnsubscriber(u)">{{ $t('YCLOUD.UNSUB.RESUBSCRIBE') }}</button>
            </td>
          </tr>
        </tbody>
      </table>
    </SettingsSection>

    <!-- Webhook Endpoints -->
    <SettingsSection :title="$t('YCLOUD.WEBHOOKS.TITLE')" :sub-title="$t('YCLOUD.WEBHOOKS.DESC')" :show-border="false">
      <div v-if="isLoadingWebhooks" class="text-center py-4"><span class="spinner" /></div>
      <div v-else-if="webhookEndpoints.length === 0" class="text-center py-4 text-n-slate-11">{{ $t('YCLOUD.WEBHOOKS.EMPTY') }}</div>
      <div v-else class="space-y-3">
        <div v-for="wh in webhookEndpoints" :key="wh.id" class="p-4 bg-n-slate-1 rounded-lg">
          <p class="font-medium text-sm">{{ wh.url }}</p>
          <p class="text-xs text-n-slate-11 mt-1">ID: {{ wh.id }} | Status: {{ wh.status }} | Events: {{ (wh.events || []).length }}</p>
          <div class="mt-2">
            <NextButton :label="$t('YCLOUD.WEBHOOKS.ROTATE')" size="sm" variant="ghost" color="red" :is-loading="isRotating" @click="rotateSecret(wh)" />
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- Add Unsubscriber Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-6 w-full max-w-md shadow-xl">
        <h3 class="text-lg font-semibold mb-4">{{ $t('YCLOUD.UNSUB.ADD') }}</h3>
        <label class="block mb-3">{{ $t('YCLOUD.UNSUB.CUSTOMER') }}<input v-model="newUnsub.customer" type="text" class="mt-1" placeholder="+1234567890" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.UNSUB.CHANNEL') }}
          <select v-model="newUnsub.channel" class="mt-1">
            <option v-for="ch in ['whatsapp','sms','email']" :key="ch" :value="ch">{{ ch }}</option>
          </select>
        </label>
        <div class="flex justify-end gap-2 mt-4">
          <NextButton :label="$t('YCLOUD.COMMON.CANCEL')" variant="ghost" @click="showAddModal = false" />
          <NextButton :label="$t('YCLOUD.COMMON.SAVE')" @click="addUnsubscriber" />
        </div>
      </div>
    </div>
  </div>
</template>
