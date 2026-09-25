<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import MobileAppsAPI from 'dashboard/api/mobileApps';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({ inbox: { type: Object, required: true } });
const { t } = useI18n();
const form = reactive({ name: '', bundle_id: '', team_id: '', key_id: '' });
const privateKey = ref('');
const fileInput = ref(null);
const devices = ref([]);
const configured = ref(false);
const confirmingRemoval = ref(false);
const loading = ref(true);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const fields = ['name', 'bundle_id', 'team_id', 'key_id'];

function reportError(exception) {
  error.value =
    exception.response?.data?.error ||
    exception.response?.data?.message ||
    t('INBOX_MGMT.MOBILE_APPS.ERROR');
}

async function load() {
  error.value = '';
  try {
    const { data } = await MobileAppsAPI.get(props.inbox.id);
    configured.value = !!data.app;
    fields.forEach(field => {
      form[field] = data.app?.[field] || '';
    });
    devices.value = data.devices;
  } catch (exception) {
    reportError(exception);
  } finally {
    loading.value = false;
  }
}

async function readKey(event) {
  privateKey.value = '';
  error.value = '';
  const file = event.target.files[0];
  if (!file) return;
  if (file.size > 8192) {
    error.value = t('INBOX_MGMT.MOBILE_APPS.KEY_TOO_LARGE');
    event.target.value = '';
    return;
  }
  privateKey.value = await file.text();
}

async function save() {
  busy.value = true;
  error.value = '';
  notice.value = '';
  try {
    await MobileAppsAPI.update(props.inbox.id, {
      ...form,
      ...(privateKey.value ? { private_key: privateKey.value } : {}),
    });
    privateKey.value = '';
    fileInput.value.value = '';
    notice.value = t('INBOX_MGMT.MOBILE_APPS.SAVED');
    await load();
  } catch (exception) {
    reportError(exception);
  } finally {
    busy.value = false;
  }
}

async function sendTest(device) {
  busy.value = true;
  error.value = '';
  try {
    await MobileAppsAPI.testNotification(props.inbox.id, device.id);
    notice.value = t('INBOX_MGMT.MOBILE_APPS.QUEUED');
    await load();
  } catch (exception) {
    reportError(exception);
  } finally {
    busy.value = false;
  }
}

async function remove() {
  busy.value = true;
  error.value = '';
  notice.value = '';
  try {
    await MobileAppsAPI.remove(props.inbox.id);
    confirmingRemoval.value = false;
    await load();
  } catch (exception) {
    reportError(exception);
  } finally {
    busy.value = false;
  }
}

onMounted(load);
</script>

<template>
  <section class="flex flex-col gap-6 py-6">
    <div>
      <h2 class="text-heading-2 text-n-slate-12">
        {{ t('INBOX_MGMT.MOBILE_APPS.TITLE') }}
      </h2>
      <p class="mt-2 text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.MOBILE_APPS.DESCRIPTION') }}
      </p>
    </div>
    <p v-if="loading" class="text-n-slate-11">
      {{ t('INBOX_MGMT.MOBILE_APPS.LOADING') }}
    </p>
    <p v-if="error" role="alert" class="text-n-ruby-9">{{ error }}</p>
    <p v-if="notice" role="status" class="text-n-teal-10">{{ notice }}</p>
    <form
      v-if="!loading"
      class="flex flex-col gap-4 max-w-xl"
      @submit.prevent="save"
    >
      <Input
        v-for="field in fields"
        :key="field"
        v-model="form[field]"
        :label="t(`INBOX_MGMT.MOBILE_APPS.FIELDS.${field.toUpperCase()}`)"
      />
      <label class="flex flex-col gap-2 text-body-main text-n-slate-12">
        {{ t('INBOX_MGMT.MOBILE_APPS.PRIVATE_KEY') }}
        <input ref="fileInput" type="file" accept=".p8" @change="readKey" />
      </label>
      <p class="text-body-small text-n-slate-11">
        {{
          t(
            configured
              ? 'INBOX_MGMT.MOBILE_APPS.KEY_SAVED'
              : 'INBOX_MGMT.MOBILE_APPS.KEY_HELP'
          )
        }}
      </p>
      <Button
        type="submit"
        :is-loading="busy"
        :disabled="busy"
        :label="t('INBOX_MGMT.MOBILE_APPS.SAVE')"
        class="self-start"
      />
    </form>
    <div v-if="configured" class="flex flex-col gap-4">
      <p v-if="confirmingRemoval" class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.MOBILE_APPS.REMOVE_HELP') }}
      </p>
      <div class="flex gap-2">
        <Button
          :label="
            t(
              confirmingRemoval
                ? 'INBOX_MGMT.MOBILE_APPS.CONFIRM_REMOVE'
                : 'INBOX_MGMT.MOBILE_APPS.REMOVE'
            )
          "
          color="ruby"
          variant="outline"
          :disabled="busy"
          @click="confirmingRemoval ? remove() : (confirmingRemoval = true)"
        />
        <Button
          v-if="confirmingRemoval"
          :label="t('INBOX_MGMT.MOBILE_APPS.CANCEL')"
          variant="ghost"
          @click="confirmingRemoval = false"
        />
      </div>
      <div class="flex items-center justify-between">
        <h3 class="text-heading-3">
          {{ t('INBOX_MGMT.MOBILE_APPS.DEVICES') }}
        </h3>
        <Button
          :label="t('INBOX_MGMT.MOBILE_APPS.REFRESH')"
          variant="outline"
          @click="load"
        />
      </div>
      <p class="text-body-small text-n-slate-11">
        {{ t('INBOX_MGMT.MOBILE_APPS.DELIVERY_HELP') }}
      </p>
      <p v-if="!devices.length" class="text-n-slate-11">
        {{ t('INBOX_MGMT.MOBILE_APPS.NO_DEVICES') }}
      </p>
      <div
        v-for="device in devices"
        :key="device.id"
        class="flex items-center justify-between gap-4 rounded-xl border border-n-weak p-4"
      >
        <div class="flex flex-col gap-1">
          <span class="text-heading-3">{{ device.name }}</span>
          <span v-if="device.invalidated_at" class="text-n-ruby-9">{{
            t('INBOX_MGMT.MOBILE_APPS.INVALID_DEVICE')
          }}</span>
          <span class="text-body-small text-n-slate-11">{{
            t(
              `INBOX_MGMT.MOBILE_APPS.ENVIRONMENTS.${device.environment.toUpperCase()}`
            )
          }}</span>
          <span
            v-if="device.last_delivery"
            class="text-body-small text-n-slate-11"
          >
            {{
              t(
                `INBOX_MGMT.MOBILE_APPS.STATUSES.${device.last_delivery.status.toUpperCase()}`
              )
            }}
            {{ device.last_delivery.reason }}
          </span>
        </div>
        <Button
          :label="t('INBOX_MGMT.MOBILE_APPS.SEND_TEST')"
          :disabled="busy || !!device.invalidated_at"
          @click="sendTest(device)"
        />
      </div>
    </div>
  </section>
</template>
