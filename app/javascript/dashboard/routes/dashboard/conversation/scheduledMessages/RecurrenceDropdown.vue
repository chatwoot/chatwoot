<script setup>
import { computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';

import Icon from 'dashboard/components-next/icon/Icon.vue';

import {
  getRecurrenceShortcuts,
  formatShortcutLabel,
  buildRecurrenceDescription,
} from 'dashboard/helper/recurrenceHelpers';

const props = defineProps({
  modelValue: {
    type: Object,
    default: null,
  },
  scheduledDate: {
    type: Date,
    default: null,
  },
  hideNoRepeat: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'openCustom']);

const { t, locale } = useI18n();

const isOpen = ref(false);
const triggerRef = ref(null);
const dropdownStyle = ref({});

const shortcuts = computed(() => {
  const all = getRecurrenceShortcuts(props.scheduledDate || new Date());
  return props.hideNoRepeat ? all.filter(s => s.label !== 'NO_REPEAT') : all;
});

const selectedLabel = computed(() => {
  if (!props.modelValue) {
    return t('SCHEDULED_MESSAGES.RECURRENCE.NO_REPEAT');
  }

  const match = shortcuts.value.find(
    s => s.value && JSON.stringify(s.value) === JSON.stringify(props.modelValue)
  );

  if (match) {
    return formatShortcutLabel(match, t, locale.value);
  }

  return buildRecurrenceDescription(props.modelValue, t, locale.value);
});

const updatePosition = () => {
  if (!triggerRef.value) return;
  const rect = triggerRef.value.getBoundingClientRect();
  const spaceBelow = window.innerHeight - rect.bottom;
  const dropdownHeight = shortcuts.value.length * 40 + 16;
  const openAbove = spaceBelow < dropdownHeight && rect.top > spaceBelow;

  dropdownStyle.value = {
    position: 'fixed',
    left: `${rect.left}px`,
    width: `${rect.width}px`,
    zIndex: 10001,
    ...(openAbove
      ? { bottom: `${window.innerHeight - rect.top + 4}px` }
      : { top: `${rect.bottom + 4}px` }),
  };
};

const toggleDropdown = async () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    await nextTick();
    updatePosition();
  }
};

const close = () => {
  isOpen.value = false;
};

const onSelect = shortcut => {
  close();
  if (shortcut.value === 'custom') {
    emit('openCustom');
  } else {
    emit('update:modelValue', shortcut.value);
  }
};

const isSelected = shortcut => {
  return JSON.stringify(shortcut.value) === JSON.stringify(props.modelValue);
};
</script>

<template>
  <div class="flex flex-col gap-1">
    <span class="text-sm font-medium text-n-slate-12">
      {{ t('SCHEDULED_MESSAGES.RECURRENCE.SECTION_TITLE') }}
    </span>
    <button
      ref="triggerRef"
      class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-1 w-full justify-between"
      @click="toggleDropdown"
    >
      <div class="flex items-center gap-2">
        <Icon
          icon="i-lucide-repeat"
          class="size-4"
          :class="modelValue ? 'text-n-blue-10' : 'text-n-slate-11'"
        />
        <span>{{ selectedLabel }}</span>
      </div>
      <Icon icon="i-lucide-chevron-down" class="size-4 text-n-slate-11" />
    </button>
    <Teleport to="body">
      <div
        v-if="isOpen"
        v-on-click-outside="close"
        :style="dropdownStyle"
        class="bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak rounded-xl shadow-lg py-1"
      >
        <button
          v-for="shortcut in shortcuts"
          :key="shortcut.label"
          class="flex items-center gap-3 w-full px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2 cursor-pointer transition-colors text-left"
          :class="{ 'bg-n-alpha-1': isSelected(shortcut) }"
          @click="onSelect(shortcut)"
        >
          <Icon
            :icon="
              shortcut.label === 'CUSTOM'
                ? 'i-lucide-settings-2'
                : 'i-lucide-repeat'
            "
            class="size-4 text-n-slate-11 shrink-0"
          />
          <span>{{ formatShortcutLabel(shortcut, t, locale) }}</span>
        </button>
      </div>
    </Teleport>
  </div>
</template>
