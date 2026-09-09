<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['confirm', 'cancel']);
const { t } = useI18n();

const PRESET_OPTIONS = computed(() => [
  {
    key: '1_hour',
    label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.1_HOUR'),
  },
  {
    key: '8_hours',
    label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.8_HOURS'),
  },
  { key: '1_day', label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.1_DAY') },
  {
    key: '7_days',
    label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.7_DAYS'),
  },
  {
    key: 'custom',
    label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.CUSTOM'),
  },
  { key: null, label: t('CONTACT_PANEL.BAN_DURATION_MODAL.PRESETS.FOREVER') },
]);

const selectedKey = ref('1_hour');
const customDate = ref('');
const customTime = ref('');

const isCustom = computed(() => selectedKey.value === 'custom');
const minDate = computed(() => new Date().toISOString().slice(0, 10));
const confirmDisabled = computed(
  () => isCustom.value && (!customDate.value || !customTime.value)
);

const handleConfirm = () => {
  let bannedUntil;
  if (isCustom.value) {
    bannedUntil = new Date(
      `${customDate.value}T${customTime.value}`
    ).toISOString();
  } else {
    bannedUntil = selectedKey.value;
  }
  emit('confirm', bannedUntil);
};
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    @click.self="$emit('cancel')"
  >
    <div
      class="w-full max-w-sm rounded-2xl bg-white dark:bg-n-solid-3 shadow-2xl p-6 flex flex-col gap-5"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ban-modal-title"
    >
      <div class="flex flex-col gap-1">
        <h2
          id="ban-modal-title"
          class="text-base font-semibold text-n-slate-12"
        >
          {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11">
          {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.DESCRIPTION') }}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-2">
        <button
          v-for="option in PRESET_OPTIONS"
          :key="String(option.key)"
          type="button"
          class="rounded-xl border px-4 py-2.5 text-sm font-medium transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-woot-400"
          :class="
            selectedKey === option.key
              ? 'border-woot-500 bg-woot-50 text-woot-700 dark:bg-woot-900/30 dark:text-woot-300 shadow-sm'
              : 'border-n-weak text-n-slate-11 hover:border-n-slate-7 hover:text-n-slate-12 bg-transparent'
          "
          @click="selectedKey = option.key"
        >
          {{ option.label }}
        </button>
      </div>

      <transition
        enter-active-class="transition-all duration-200 ease-out"
        enter-from-class="opacity-0 -translate-y-1"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition-all duration-150 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-1"
      >
        <div v-if="isCustom" class="flex gap-3">
          <div class="flex-1 flex flex-col gap-1.5">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.CUSTOM_DATE_LABEL') }}
            </label>
            <input
              v-model="customDate"
              type="date"
              :min="minDate"
              class="w-full rounded-xl border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-woot-400 focus:border-transparent dark:bg-n-solid-2"
            />
          </div>
          <div class="flex-1 flex flex-col gap-1.5">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.CUSTOM_TIME_LABEL') }}
            </label>
            <input
              v-model="customTime"
              type="time"
              class="w-full rounded-xl border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-woot-400 focus:border-transparent dark:bg-n-solid-2"
            />
          </div>
        </div>
      </transition>

      <div class="flex justify-end gap-2 pt-1">
        <button
          type="button"
          class="rounded-xl px-4 py-2 text-sm font-medium text-n-slate-11 hover:bg-n-alpha-1 transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-n-slate-7"
          @click="$emit('cancel')"
        >
          {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.CANCEL') }}
        </button>
        <button
          type="button"
          class="rounded-xl bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 active:bg-red-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-red-400"
          :disabled="confirmDisabled"
          @click="handleConfirm"
        >
          {{ t('CONTACT_PANEL.BAN_DURATION_MODAL.CONFIRM') }}
        </button>
      </div>
    </div>
  </div>
</template>
