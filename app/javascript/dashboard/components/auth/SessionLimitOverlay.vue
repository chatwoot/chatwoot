<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, parseISO } from 'date-fns';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  sessions: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['revoke', 'revokeAll', 'cancel']);

const { t } = useI18n();
const revokingId = ref(null);
const revokingAll = ref(false);

const sortedSessions = computed(() =>
  [...props.sessions].sort(
    (a, b) => new Date(b.created_at) - new Date(a.created_at)
  )
);

const formatDate = dateStr => {
  if (!dateStr) return '';
  return format(parseISO(dateStr), 'MMMM d, yyyy');
};

const formatTime = dateStr => {
  if (!dateStr) return '';
  return format(parseISO(dateStr), 'hh:mma');
};

const isUnknown = val => !val || val === 'Unknown' || val === 'Unknown Browser';

const sessionLabel = session => {
  const parts = [];
  if (!isUnknown(session.browser_name)) parts.push(session.browser_name);
  if (!isUnknown(session.platform_name)) parts.push(session.platform_name);
  return parts.join(' on ') || t('SESSION_LIMIT.UNKNOWN_DEVICE');
};

watch(
  () => props.sessions,
  () => {
    revokingId.value = null;
    revokingAll.value = false;
  }
);

const handleRevoke = session => {
  revokingId.value = session.id;
  emit('revoke', session.id);
};

const handleRevokeAll = () => {
  revokingAll.value = true;
  emit('revokeAll');
};
</script>

<template>
  <div class="w-full max-w-lg mx-auto">
    <div
      class="bg-white shadow dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
    >
      <!-- Header -->
      <div class="flex items-start justify-between gap-4 mb-6">
        <div>
          <h2 class="text-2xl font-semibold text-n-slate-12">
            {{ $t('SESSION_LIMIT.TITLE') }}
          </h2>
          <p class="text-sm text-n-slate-11 mt-2">
            {{ $t('SESSION_LIMIT.DESCRIPTION') }}
          </p>
        </div>
        <NextButton
          type="button"
          faded
          sm
          class="flex-shrink-0 whitespace-nowrap"
          :label="$t('SESSION_LIMIT.END_ALL')"
          :is-loading="revokingAll"
          :disabled="revokingId !== null"
          @click="handleRevokeAll"
        />
      </div>

      <!-- Session List -->
      <div class="flex flex-col gap-3 max-h-80 overflow-y-auto">
        <div
          v-for="session in sortedSessions"
          :key="session.id"
          class="flex items-center justify-between gap-4 rounded-xl border border-n-slate-4 bg-n-background px-4 py-3"
        >
          <div class="flex items-center gap-3 min-w-0">
            <Icon
              icon="i-lucide-monitor"
              class="size-4 text-n-slate-10 flex-shrink-0"
            />
            <div class="flex flex-col gap-0.5 min-w-0">
              <span class="text-sm font-medium text-n-slate-12">
                {{ sessionLabel(session) }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{
                  `${$t('SESSION_LIMIT.STARTED')} ${formatDate(session.created_at)}, ${formatTime(session.created_at)}`
                }}
              </span>
            </div>
          </div>
          <button
            type="button"
            class="text-sm font-medium text-n-slate-11 hover:text-n-slate-12 flex-shrink-0 disabled:opacity-50"
            :disabled="revokingId !== null || revokingAll"
            @click="handleRevoke(session)"
          >
            {{ $t('SESSION_LIMIT.END') }}
          </button>
        </div>
      </div>

      <!-- Cancel -->
      <div class="text-center pt-4">
        <NextButton
          sm
          slate
          link
          type="button"
          class="w-full hover:!no-underline"
          :label="$t('SESSION_LIMIT.CANCEL')"
          @click="() => emit('cancel')"
        />
      </div>
    </div>
  </div>
</template>
