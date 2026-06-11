<script setup>
import MobileBottomSheet from './MobileBottomSheet.vue';
import { vHapticTap } from './hapticTap';

defineProps({
  open: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'select']);

const statusOptions = [
  {
    key: 'pending',
    icon: 'i-lucide-circle-dot-dashed',
    iconClass: 'text-n-amber-10 bg-n-amber-3',
    labelKey: 'MOBILE.STATUS_SHEET.OPTIONS.PENDING',
  },
  {
    key: 'snoozed',
    icon: 'i-lucide-alarm-clock-minus',
    iconClass: 'text-n-blue-10 bg-n-blue-3',
    labelKey: 'MOBILE.STATUS_SHEET.OPTIONS.SNOOZED',
  },
  {
    key: 'resolved',
    icon: 'i-lucide-check-check',
    iconClass: 'text-n-teal-10 bg-n-teal-3',
    labelKey: 'MOBILE.STATUS_SHEET.OPTIONS.RESOLVED',
  },
];
</script>

<template>
  <MobileBottomSheet
    v-if="open"
    :title="$t('MOBILE.STATUS_SHEET.TITLE')"
    @close="emit('close')"
  >
    <div class="-mx-4 -my-4 divide-y divide-n-weak">
      <button
        v-for="option in statusOptions"
        :key="option.key"
        v-haptic-tap
        class="flex w-full items-center gap-3 px-5 py-4 text-left active:bg-n-alpha-2"
        @click="emit('select', option.key)"
      >
        <span
          class="flex size-10 items-center justify-center rounded-full"
          :class="option.iconClass"
        >
          <span class="size-5" :class="option.icon" />
        </span>
        <span class="text-lg font-medium text-n-slate-12">
          {{ $t(option.labelKey) }}
        </span>
      </button>
    </div>
  </MobileBottomSheet>
</template>
