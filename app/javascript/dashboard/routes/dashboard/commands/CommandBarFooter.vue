<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

// ninja-keys ships its footer as fixed English markup; filling its footer slot
// is the only way to translate it. The --ninja-* colors reach this light-DOM
// content because CSS custom properties inherit through the slot.
const { t } = useI18n();

// The native slot attribute of the <ninja-keys> web component. Bound as an
// object because vue/no-deprecated-slot-attribute reads a literal `slot` as
// Vue 2 slot syntax.
const NINJA_FOOTER_SLOT = { slot: 'footer' };

const hints = computed(() => [
  {
    keys: ['i-lucide-corner-down-left'],
    label: t('COMMAND_BAR.FOOTER.SELECT'),
  },
  {
    keys: ['i-lucide-arrow-down', 'i-lucide-arrow-up'],
    label: t('COMMAND_BAR.FOOTER.NAVIGATE'),
  },
  { keys: ['esc'], label: t('COMMAND_BAR.FOOTER.CLOSE') },
  { keys: ['i-lucide-delete'], label: t('COMMAND_BAR.FOOTER.PARENT') },
]);
</script>

<template>
  <div
    v-bind="NINJA_FOOTER_SLOT"
    class="flex flex-wrap gap-x-4 gap-y-1 px-4 py-2 text-xs bg-[var(--ninja-footer-background)] text-[color:var(--ninja-secondary-text-color)] border-t border-n-weak"
  >
    <span
      v-for="hint in hints"
      :key="hint.label"
      class="flex items-center gap-1"
    >
      <span
        v-for="key in hint.keys"
        :key="key"
        class="flex items-center justify-center h-4 min-w-4 px-0.5 rounded bg-[var(--ninja-secondary-background-color)]"
      >
        <span v-if="key === 'esc'" class="leading-none">{{ key }}</span>
        <span v-else class="size-3" :class="key" />
      </span>
      {{ hint.label }}
    </span>
  </div>
</template>
