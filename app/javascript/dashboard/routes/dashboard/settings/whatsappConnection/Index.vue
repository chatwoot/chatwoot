<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WhatsappConnectionAPI from 'dashboard/api/whatsappConnection';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();

const channels = ref([]);
const isLoading = ref(false);
const isChecking = ref(false);

const STATUS_META = {
  connected: { color: 'bg-green-500', key: 'CONNECTED' },
  disconnected: { color: 'bg-red-500', key: 'DISCONNECTED' },
  unknown: { color: 'bg-slate-400', key: 'UNKNOWN' },
};

const metaFor = status => STATUS_META[status] || STATUS_META.unknown;

const formatCheckedAt = checkedAt => {
  if (!checkedAt) return t('WHATSAPP_CONNECTION.NEVER');
  return new Date(checkedAt).toLocaleString();
};

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await WhatsappConnectionAPI.getStatus();
    channels.value = data.data || [];
  } catch (error) {
    useAlert(t('WHATSAPP_CONNECTION.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const runCheck = async () => {
  isChecking.value = true;
  try {
    const { data } = await WhatsappConnectionAPI.runCheck();
    channels.value = data.data || [];
    const down = channels.value.filter(c => c.status === 'disconnected');
    if (down.length) {
      useAlert(t('WHATSAPP_CONNECTION.RESULT_DISCONNECTED'));
    } else {
      useAlert(t('WHATSAPP_CONNECTION.RESULT_OK'));
    }
  } catch (error) {
    useAlert(t('WHATSAPP_CONNECTION.CHECK_ERROR'));
  } finally {
    isChecking.value = false;
  }
};

onMounted(load);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('WHATSAPP_CONNECTION.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('WHATSAPP_CONNECTION.HEADER')"
        :description="$t('WHATSAPP_CONNECTION.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-4">
        <div class="flex justify-end">
          <NextButton
            :label="$t('WHATSAPP_CONNECTION.CHECK_NOW')"
            :is-loading="isChecking"
            icon="i-lucide-refresh-cw"
            @click="runCheck"
          />
        </div>

        <p
          v-if="!channels.length"
          class="py-16 text-center text-sm text-slate-500 dark:text-slate-400"
        >
          {{ $t('WHATSAPP_CONNECTION.EMPTY') }}
        </p>

        <div
          v-for="channel in channels"
          :key="channel.inbox_id"
          class="flex items-center justify-between gap-4 p-4 border border-slate-75 dark:border-slate-700 rounded-lg"
        >
          <div class="flex flex-col gap-1 min-w-0">
            <span class="text-sm font-medium text-slate-900 dark:text-slate-50 truncate">
              {{ channel.inbox_name || channel.phone_number }}
            </span>
            <span class="text-xs text-slate-500 dark:text-slate-400">
              {{ $t('WHATSAPP_CONNECTION.LAST_CHECK') }}:
              {{ formatCheckedAt(channel.checked_at) }}
            </span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <span class="size-2.5 rounded-full" :class="metaFor(channel.status).color" />
            <span class="text-sm text-slate-700 dark:text-slate-200">
              {{ $t(`WHATSAPP_CONNECTION.STATUS.${metaFor(channel.status).key}`) }}
            </span>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
