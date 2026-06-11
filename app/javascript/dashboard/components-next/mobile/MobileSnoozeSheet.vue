<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, getUnixTime } from 'date-fns';
import wootConstants from 'dashboard/constants/globals';
import {
  findSnoozeTime,
  snoozedReopenTime,
} from 'dashboard/helper/snoozeHelpers';
import { useHaptics } from 'dashboard/composables/useHaptics';
import MobileBottomSheet from './MobileBottomSheet.vue';
import { vHapticTap } from './hapticTap';

const props = defineProps({
  open: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'select']);

const { t } = useI18n();
const { medium } = useHaptics();

const { SNOOZE_OPTIONS } = wootConstants;

const customTime = ref('');
const minCustomTime = ref('');

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) return;
    customTime.value = '';
    minCustomTime.value = format(new Date(), "yyyy-MM-dd'T'HH:mm");
  }
);

const reopenLabel = key => {
  const snoozedUntil = findSnoozeTime(key);
  return snoozedUntil ? snoozedReopenTime(snoozedUntil * 1000) : '';
};

const presetOptions = computed(() => [
  {
    key: SNOOZE_OPTIONS.UNTIL_NEXT_REPLY,
    icon: 'i-lucide-message-square-reply',
    label: t('MOBILE.SNOOZE.NEXT_REPLY'),
    time: '',
  },
  {
    key: SNOOZE_OPTIONS.AN_HOUR_FROM_NOW,
    icon: 'i-lucide-clock-3',
    label: t('MOBILE.SNOOZE.AN_HOUR'),
    time: reopenLabel(SNOOZE_OPTIONS.AN_HOUR_FROM_NOW),
  },
  {
    key: SNOOZE_OPTIONS.UNTIL_TOMORROW,
    icon: 'i-lucide-sunrise',
    label: t('MOBILE.SNOOZE.TOMORROW'),
    time: reopenLabel(SNOOZE_OPTIONS.UNTIL_TOMORROW),
  },
  {
    key: SNOOZE_OPTIONS.UNTIL_NEXT_WEEK,
    icon: 'i-lucide-calendar-days',
    label: t('MOBILE.SNOOZE.NEXT_WEEK'),
    time: reopenLabel(SNOOZE_OPTIONS.UNTIL_NEXT_WEEK),
  },
]);

const onPresetSelect = key => {
  medium();
  emit('select', { snoozedUntil: findSnoozeTime(key) || null });
};

const isCustomTimeValid = computed(() => {
  if (!customTime.value) return false;
  return new Date(customTime.value).getTime() > Date.now();
});

const onCustomConfirm = () => {
  if (!isCustomTimeValid.value) return;
  medium();
  emit('select', { snoozedUntil: getUnixTime(new Date(customTime.value)) });
};
</script>

<template>
  <MobileBottomSheet
    v-if="open"
    :title="t('MOBILE.SNOOZE.TITLE')"
    @close="emit('close')"
  >
    <div class="-mx-4 -mt-4 divide-y divide-n-weak">
      <button
        v-for="option in presetOptions"
        :key="option.key"
        v-haptic-tap
        class="flex w-full items-center gap-3 px-5 py-3.5 text-left active:bg-n-alpha-2"
        @click="onPresetSelect(option.key)"
      >
        <span
          class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-blue-2 text-n-blue-10"
        >
          <span class="size-5" :class="option.icon" />
        </span>
        <span class="flex-1 text-base font-medium text-n-slate-12">
          {{ option.label }}
        </span>
        <span v-if="option.time" class="text-sm text-n-slate-10">
          {{ option.time }}
        </span>
      </button>
    </div>

    <div class="-mx-4 border-t border-n-weak px-5 pb-1 pt-4">
      <p class="mb-2 text-[13px] font-medium text-n-slate-10">
        {{ t('MOBILE.SNOOZE.CUSTOM') }}
      </p>
      <div class="flex items-center gap-3">
        <input
          v-model="customTime"
          type="datetime-local"
          :min="minCustomTime"
          class="h-10 flex-1 rounded-lg border border-n-weak bg-white dark:bg-n-background px-3 text-sm text-n-slate-12"
        />
        <button
          v-haptic-tap
          class="h-10 rounded-lg bg-n-brand px-4 text-sm font-medium text-white active:opacity-90 disabled:opacity-40"
          :disabled="!isCustomTimeValid"
          @click="onCustomConfirm"
        >
          {{ t('MOBILE.SNOOZE.CONFIRM') }}
        </button>
      </div>
    </div>
  </MobileBottomSheet>
</template>
