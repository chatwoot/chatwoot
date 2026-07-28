<script setup>
import { ref, computed, watch, nextTick, onBeforeUnmount, inject } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBoxDropdown from 'dashboard/components-next/combobox/ComboBoxDropdown.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
    validator: value =>
      value.every(option => 'value' in option && 'label' in option),
  },
  placeholder: { type: String, default: '' },
  // Fallback label shown when the selected value is not in `options` yet
  // (e.g. API-backed lists that load lazily on open).
  displayLabel: { type: String, default: '' },
  modelValue: { type: [String, Number], default: '' },
  disabled: { type: Boolean, default: false },
  searchPlaceholder: { type: String, default: '' },
  emptyState: { type: String, default: '' },
  message: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
  useApiResults: { type: Boolean, default: false },
  // Render menu outside overflow parents (modals). Prefers dialog portal target.
  teleport: { type: Boolean, default: false },
  // undefined = auto (hide search when few options)
  showSearch: { type: Boolean, default: undefined },
});
const emit = defineEmits(['update:modelValue', 'search', 'open']);
const SEARCH_ROW_PX = 41;
const OPTION_ROW_PX = 36;
const LIST_PAD_PX = 8;
const MENU_GAP_PX = 4;
const VIEWPORT_PAD_PX = 12;
const SEARCH_OPTION_THRESHOLD = 6;

const { t } = useI18n();

const dialogPortalTarget = inject('dialogPortalTarget', null);

const selectedValue = ref(props.modelValue);
const open = ref(false);
const search = ref('');
const dropdownRef = ref(null);
const comboboxRef = ref(null);
const triggerRef = ref(null);
const dropdownStyle = ref({});

const teleportTarget = computed(() => {
  if (!props.teleport) return 'body';
  return dialogPortalTarget?.value || 'body';
});

const showSearchField = computed(() => {
  if (typeof props.showSearch === 'boolean') return props.showSearch;
  return props.options.length > SEARCH_OPTION_THRESHOLD;
});

const filteredOptions = computed(() => {
  if (props.useApiResults && search.value) {
    return props.options;
  }

  const searchTerm = search.value.toLowerCase();
  return props.options.filter(option =>
    option.label.toLowerCase().includes(searchTerm)
  );
});
const selectPlaceholder = computed(() => {
  return props.placeholder || t('COMBOBOX.PLACEHOLDER');
});
const selectedLabel = computed(() => {
  const selected = props.options.find(
    option => option.value === selectedValue.value
  );
  return selected?.label ?? (props.displayLabel || selectPlaceholder.value);
});

const estimateMenuHeight = () => {
  const count = Math.max(filteredOptions.value.length, 1);
  const listH = Math.min(count, 8) * OPTION_ROW_PX + LIST_PAD_PX;
  return (showSearchField.value ? SEARCH_ROW_PX : 0) + listH;
};

const selectOption = option => {
  if (selectedValue.value === option.value) {
    selectedValue.value = '';
    emit('update:modelValue', '');
  } else {
    selectedValue.value = option.value;
    emit('update:modelValue', option.value);
  }
  open.value = false;
  search.value = '';
};

const getScrollParent = el => {
  let node = el?.parentElement;
  while (node && node !== document.body) {
    const { overflowY } = window.getComputedStyle(node);
    if (
      /(auto|scroll|overlay)/.test(overflowY) &&
      node.scrollHeight > node.clientHeight
    ) {
      return node;
    }
    node = node.parentElement;
  }
  return null;
};

/** Prefer opening downward: scroll the field up if the menu wouldn't fit. */
const ensureRoomBelow = neededPx => {
  const el = triggerRef.value;
  if (!el) return;
  const rect = el.getBoundingClientRect();
  const spaceBelow = window.innerHeight - rect.bottom - VIEWPORT_PAD_PX;
  if (spaceBelow >= neededPx) return;

  const deficit = neededPx - spaceBelow;
  const scroller = getScrollParent(el);
  if (scroller) {
    scroller.scrollTop += deficit;
  } else {
    el.scrollIntoView({ block: 'center', inline: 'nearest' });
  }
};

const updateDropdownPosition = () => {
  if (!props.teleport || !open.value) return;
  const el = triggerRef.value;
  if (!el?.getBoundingClientRect) return;
  const rect = el.getBoundingClientRect();
  const spaceBelow = Math.max(
    96,
    window.innerHeight - rect.bottom - MENU_GAP_PX - VIEWPORT_PAD_PX
  );
  const ideal = estimateMenuHeight();
  const maxHeight = Math.min(ideal, spaceBelow);

  // Always open downward — never flip up (avoids the clipped "corte" look).
  dropdownStyle.value = {
    position: 'fixed',
    top: `${rect.bottom + MENU_GAP_PX}px`,
    left: `${rect.left}px`,
    width: `${rect.width}px`,
    maxHeight: `${maxHeight}px`,
    zIndex: 10050,
  };
};

const stopPositionListeners = () => {
  window.removeEventListener('scroll', updateDropdownPosition, true);
  window.removeEventListener('resize', updateDropdownPosition);
};

const startPositionListeners = () => {
  stopPositionListeners();
  window.addEventListener('scroll', updateDropdownPosition, true);
  window.addEventListener('resize', updateDropdownPosition);
};

const toggleDropdown = async () => {
  if (props.disabled) return;
  open.value = !open.value;
  if (open.value) {
    search.value = '';
    emit('open');
    if (props.teleport) {
      ensureRoomBelow(estimateMenuHeight());
      await nextTick();
      await new Promise(resolve => {
        requestAnimationFrame(() => resolve());
      });
      updateDropdownPosition();
      startPositionListeners();
    } else {
      await nextTick();
    }
    dropdownRef.value?.focus();
  } else {
    stopPositionListeners();
  }
};

watch(
  () => props.modelValue,
  newValue => {
    selectedValue.value = newValue;
  }
);

watch(open, isOpen => {
  if (!isOpen) stopPositionListeners();
});

onClickOutside(
  comboboxRef,
  () => {
    open.value = false;
    stopPositionListeners();
  },
  {
    ignore: [dropdownRef],
  }
);

onBeforeUnmount(() => {
  stopPositionListeners();
});
</script>

<template>
  <div
    ref="comboboxRef"
    class="relative w-full min-w-0"
    :class="{
      'cursor-not-allowed': disabled,
      'group/combobox': !disabled,
    }"
    @click.prevent
  >
    <div ref="triggerRef" class="w-full">
      <Button
        variant="outline"
        :color="hasError && !open ? 'ruby' : open ? 'blue' : 'slate'"
        :label="selectedLabel"
        trailing-icon
        :disabled="disabled"
        no-animation
        class="justify-between w-full !px-3 !py-2.5 text-n-slate-12 font-normal group-hover/combobox:border-n-slate-6 focus:outline-n-brand"
        :class="{
          focused: open,
          '[&:not(.focused)]:dark:outline-n-weak [&:not(.focused)]:hover:enabled:outline-n-slate-6 [&:not(.focused)]:dark:hover:enabled:outline-n-slate-6':
            !hasError,
        }"
        :icon="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="toggleDropdown"
      />
    </div>

    <Teleport :to="teleportTarget" :disabled="!teleport">
      <ComboBoxDropdown
        ref="dropdownRef"
        v-model:search-value="search"
        :open="open"
        :options="filteredOptions"
        :search-placeholder="searchPlaceholder"
        :empty-state="emptyState"
        :selected-values="selectedValue"
        :portal="teleport"
        :show-search="showSearchField"
        :style="teleport ? dropdownStyle : undefined"
        @search="emit('search', $event)"
        @select="selectOption"
      />
    </Teleport>

    <p
      v-if="message"
      class="mt-2 mb-0 text-xs truncate transition-all duration-500 ease-in-out"
      :class="{
        'text-n-ruby-9': hasError,
        'text-n-slate-11': !hasError,
      }"
    >
      {{ message }}
    </p>
  </div>
</template>
