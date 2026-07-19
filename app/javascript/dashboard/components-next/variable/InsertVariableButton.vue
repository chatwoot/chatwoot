<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useMapGetter } from 'dashboard/composables/store';
import {
  buildLiquidVariables,
  formatLiquidVariable,
} from 'dashboard/helper/liquidVariablesHelper';

const props = defineProps({
  context: {
    type: String,
    default: 'message',
    validator: value => ['message', 'campaign'].includes(value),
  },
  size: {
    type: String,
    default: 'sm',
  },
  showLabel: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['insert']);

const { t, te } = useI18n();
const store = useStore();
const customAttributes = useMapGetter('attributes/getAttributes');
const [isOpen, toggleOpen] = useToggle(false);
const rootRef = ref(null);

const resolveLabel = variable => {
  const labelKey = `VARIABLES.LABELS.${variable.key}`;
  return te(labelKey) ? t(labelKey) : variable.label;
};

const liquidVariables = computed(() =>
  buildLiquidVariables(customAttributes.value || [], props.context)
);

const menuItems = computed(() =>
  liquidVariables.value.map(variable => {
    const displayLabel = resolveLabel(variable);
    const liquid = formatLiquidVariable(variable.key);

    return {
      label: `${displayLabel} ${variable.key}`,
      displayLabel,
      description: variable.description || displayLabel,
      liquid,
      value: variable.key,
      action: 'insert',
    };
  })
);

const closeMenu = () => {
  isOpen.value = false;
};

const handleAction = ({ value }) => {
  emit('insert', formatLiquidVariable(value));
  closeMenu();
};

onMounted(() => {
  if (!customAttributes.value?.length) {
    store.dispatch('attributes/get');
  }
});
</script>

<template>
  <div
    ref="rootRef"
    v-on-click-outside="closeMenu"
    class="relative inline-flex shrink-0"
  >
    <Button
      type="button"
      :size="size"
      variant="ghost"
      color="slate"
      icon="i-lucide-braces"
      :label="showLabel ? t('VARIABLES.INSERT') : ''"
      @click="toggleOpen()"
    />
    <DropdownMenu
      v-if="isOpen"
      :menu-items="menuItems"
      show-search
      :search-placeholder="t('VARIABLES.SEARCH_PLACEHOLDER')"
      class="ltr:right-0 rtl:left-0 mt-1 w-72 top-full max-h-64 z-50 [&_button]:!h-auto [&_button]:items-start [&_button]:py-2"
      @action="handleAction"
    >
      <template #label="{ item }">
        <div class="flex flex-col min-w-0 flex-1 gap-0.5 text-left">
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ item.displayLabel }}
          </span>
          <code class="text-xs text-n-slate-11 truncate">
            {{ item.liquid }}
          </code>
          <span
            v-if="item.description && item.description !== item.displayLabel"
            class="text-xs text-n-slate-10 truncate"
          >
            {{ item.description }}
          </span>
        </div>
      </template>
    </DropdownMenu>
  </div>
</template>
