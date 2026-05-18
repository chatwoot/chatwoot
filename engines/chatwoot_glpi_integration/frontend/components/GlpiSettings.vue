<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';

const store      = useStore();
const connection = computed(() => store.getters['glpi/connection']);

const form = ref({
  base_url: '',
  client_id: '',
  client_secret: '',
  scope: 'api',
  default_entity_id: 0,
  default_request_type_id: 1,
  webhook_secret: '',
});
const testResult = ref(null);

onMounted(async () => {
  await store.dispatch('glpi/fetchConnection');
  if (connection.value) form.value = { ...form.value, ...connection.value };
});

const save = async () => {
  if (connection.value) await store.dispatch('glpi/updateConnection', form.value);
  else                  await store.dispatch('glpi/saveConnection',   form.value);
};

const test = async () => {
  try {
    const { data } = await store.dispatch('glpi/testConnection');
    testResult.value = { ok: true, msg: `Handshake at ${data.handshaked_at || 'now'}` };
  } catch (e) {
    testResult.value = { ok: false, msg: e.response?.data?.error || e.message };
  }
};
</script>

<template>
  <div class="p-6 max-w-2xl">
    <h2 class="text-xl font-semibold mb-4">GLPI Integration</h2>

    <div class="space-y-3">
      <label class="block text-sm">
        <span class="text-slate-600 dark:text-slate-300">Base URL</span>
        <input v-model="form.base_url" class="input w-full" placeholder="https://glpi.empresa.com" />
      </label>
      <label class="block text-sm">
        <span class="text-slate-600 dark:text-slate-300">OAuth Client ID</span>
        <input v-model="form.client_id" class="input w-full" />
      </label>
      <label class="block text-sm">
        <span class="text-slate-600 dark:text-slate-300">OAuth Client Secret</span>
        <input v-model="form.client_secret" type="password" class="input w-full" placeholder="••••••••" />
      </label>
      <div class="grid grid-cols-3 gap-2">
        <label class="text-sm">
          <span class="text-slate-600 dark:text-slate-300">Entity ID</span>
          <input v-model.number="form.default_entity_id" type="number" class="input w-full" />
        </label>
        <label class="text-sm">
          <span class="text-slate-600 dark:text-slate-300">Request Type ID</span>
          <input v-model.number="form.default_request_type_id" type="number" class="input w-full" />
        </label>
        <label class="text-sm">
          <span class="text-slate-600 dark:text-slate-300">Scope</span>
          <input v-model="form.scope" class="input w-full" />
        </label>
      </div>
      <label class="block text-sm">
        <span class="text-slate-600 dark:text-slate-300">Webhook Secret (optional)</span>
        <input v-model="form.webhook_secret" class="input w-full" />
      </label>
    </div>

    <div class="mt-4 flex gap-2">
      <button class="button success" @click="save">Save</button>
      <button class="button clear"   @click="test">Test connection</button>
    </div>

    <p v-if="testResult"
       :class="['mt-3 text-sm', testResult.ok ? 'text-green-600' : 'text-red-600']">
      {{ testResult.msg }}
    </p>

    <div v-if="connection" class="mt-6 text-xs text-slate-500">
      Webhook URL: <code>{{ connection.webhook_url }}</code>
    </div>
  </div>
</template>
