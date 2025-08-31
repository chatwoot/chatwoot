<template>
  <div class="max-w-3xl mx-auto p-6">
    <h1 class="text-xl font-semibold mb-2">WeaveSmart – Feature Flags</h1>
    <p class="text-sm text-gray-600 mb-6">Manage per‑tenant features. Changes apply immediately.</p>

    <div class="rounded-md border border-gray-200 divide-y">
      <div v-for="f in orderedFeatures" :key="f.key" class="flex items-start justify-between p-4">
        <div class="pr-4">
          <div class="font-medium">{{ f.label }}</div>
          <div v-if="f.help" class="text-xs text-gray-500 mt-1">{{ f.help }}</div>
          <div v-if="f.key === 'channel.whatsapp_third_party'" class="text-xs mt-2 p-2 rounded bg-amber-50 text-amber-800 border border-amber-200">
            Third‑party WhatsApp carries a permanent risk of disruption. Use with caution.
          </div>
        </div>
        <label class="inline-flex items-center cursor-pointer select-none">
          <input type="checkbox" class="sr-only peer" :checked="localFeatures[f.key]" @change="toggle(f.key, $event.target.checked)" />
          <span class="w-10 h-6 bg-gray-200 rounded-full peer-checked:bg-violet-600 transition-all relative">
            <span class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transform transition-all peer-checked:translate-x-4"></span>
          </span>
        </label>
      </div>
    </div>

    <div class="mt-6 flex gap-3">
      <button class="px-4 py-2 rounded bg-violet-600 text-white hover:bg-violet-700 disabled:opacity-60" :disabled="saving" @click="save">Save changes</button>
      <button class="px-4 py-2 rounded border border-gray-300 hover:bg-gray-50" :disabled="saving" @click="reset">Reset</button>
      <span v-if="error" class="text-sm text-red-600">{{ error }}</span>
      <span v-if="saved" class="text-sm text-green-700">Saved</span>
    </div>
  </div>
  <div v-if="loading" class="fixed inset-0 bg-white/40 backdrop-blur-sm"></div>
  <div v-if="loading" class="fixed inset-0 flex items-center justify-center">
    <div class="animate-spin h-8 w-8 border-2 border-violet-600 border-t-transparent rounded-full"></div>
  </div>
  
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue';
import { useStore } from 'vuex';
import { getAccountFeatures, updateAccountFeatures, type FeatureMap } from 'weave/api/wsc';

const store = useStore();
const accountId = computed(() => store.getters.getCurrentAccountId);

const loading = ref(false);
const saving = ref(false);
const saved = ref(false);
const error = ref('');

const features = ref<FeatureMap>({});
const localFeatures = ref<FeatureMap>({});
const plan = ref<string>('');

const ALL_FEATURES: { key: string; label: string; help?: string }[] = [
  { key: 'ai.captain', label: 'AI – Captain' },
  { key: 'reporting.advanced', label: 'Reporting – Advanced' },
  { key: 'sla', label: 'SLA Policies' },
  { key: 'queues', label: 'Queues' },
  { key: 'departments', label: 'Departments' },
  { key: 'billing.stripe', label: 'Billing – Stripe' },
  { key: 'billing.paypal', label: 'Billing – PayPal' },
  { key: 'channel.web_widget', label: 'Channel – Web Widget' },
  { key: 'channel.email', label: 'Channel – E‑mail' },
  { key: 'channel.whatsapp_official', label: 'Channel – WhatsApp (Official BSP)' },
  { key: 'channel.whatsapp_third_party', label: 'Channel – WhatsApp (Third‑party)' },
  { key: 'channel.telegram', label: 'Channel – Telegram' },
  { key: 'channel.facebook', label: 'Channel – Facebook' },
  { key: 'channel.instagram', label: 'Channel – Instagram' },
  { key: 'compliance.dsr', label: 'Compliance – DSR' },
  { key: 'compliance.retention', label: 'Compliance – Retention' },
];

const orderedFeatures = computed(() => ALL_FEATURES);

async function load() {
  if (!accountId.value) return;
  loading.value = true;
  error.value = '';
  saved.value = false;
  try {
    const data = await getAccountFeatures(accountId.value);
    plan.value = data.plan;
    features.value = data.features || {};
    localFeatures.value = { ...features.value };
  } catch (e: any) {
    error.value = e?.response?.data?.error || 'Failed to load features';
  } finally {
    loading.value = false;
  }
}

function reset() {
  localFeatures.value = { ...features.value };
  saved.value = false;
  error.value = '';
}

async function save() {
  if (!accountId.value) return;
  saving.value = true;
  error.value = '';
  saved.value = false;
  try {
    const data = await updateAccountFeatures(accountId.value, localFeatures.value);
    features.value = data.features || {};
    localFeatures.value = { ...features.value };
    saved.value = true;
  } catch (e: any) {
    error.value = e?.response?.data?.error || 'Failed to save';
  } finally {
    saving.value = false;
  }
}

function toggle(key: string, value: boolean) {
  localFeatures.value = { ...localFeatures.value, [key]: value };
}

onMounted(load);
</script>

