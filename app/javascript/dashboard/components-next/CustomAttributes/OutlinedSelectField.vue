<script setup>
/**
 * Outlined floating-label select using DropdownMenu (same pattern as list custom attributes).
 */
import { computed, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  label: { type: String, required: true },
  options: { type: Array, default: () => [] },
  selectedItem: { type: Object, default: null },
  placeholder: { type: String, default: '' },
  showSearch: { type: Boolean, default: true },
  disabled: { type: Boolean, default: false },
  /** Show avatar thumbnails in the menu (agents). */
  hasThumbnail: { type: Boolean, default: false },
});

const emit = defineEmits(['select']);

const [showMenu, toggleMenu] = useToggle(false);
const isFocused = ref(false);

const hasValue = computed(() => {
  const item = props.selectedItem;
  if (!item) return false;
  // id 0 / null used as "None"
  return item.id !== null && item.id !== undefined && item.id !== 0;
});

const displayLabel = computed(() => {
  if (hasValue.value) return props.selectedItem.name || '';
  return props.selectedItem?.name || props.placeholder || '';
});

const sameId = (a, b) => {
  if (a === b) return true;
  if (a == null || b == null) return a === b;
  return String(a) === String(b);
};

const menuItems = computed(() =>
  (props.options || []).map(option => ({
    label: option.name,
    value: option.id,
    action: 'select',
    isSelected:
      !!props.selectedItem && sameId(option.id, props.selectedItem.id),
    icon: option.icon || undefined,
    thumbnail:
      props.hasThumbnail && option.name
        ? {
            name: option.name,
            src: option.thumbnail || '',
          }
        : undefined,
    option,
  }))
);

const onTriggerClick = () => {
  if (props.disabled) return;
  if (showMenu.value) {
    toggleMenu(false);
    isFocused.value = false;
    return;
  }
  toggleMenu(true);
  isFocused.value = true;
};

const closeMenu = () => {
  toggleMenu(false);
  isFocused.value = false;
};

const onAction = item => {
  const selected =
    item.option || props.options.find(o => sameId(o.id, item.value)) || null;
  emit('select', selected);
  closeMenu();
};
</script>

<template>
  <OutlinedAttributeField
    :label="label"
    filled
    :focused="isFocused || showMenu"
    :disabled="disabled"
  >
    <div
      v-on-clickaway="closeMenu"
      class="relative flex items-center w-full min-h-8 gap-1.5"
      :class="{ 'cursor-pointer': !disabled }"
      @click="onTriggerClick"
    >
      <Avatar
        v-if="hasThumbnail && hasValue"
        :name="selectedItem.name"
        :src="selectedItem.thumbnail"
        :status="selectedItem.availability_status"
        :size="20"
        hide-offline-status
        rounded-full
        class="shrink-0"
      />
      <Icon
        v-else-if="hasValue && selectedItem.icon"
        :icon="selectedItem.icon"
        class="size-4 shrink-0 text-n-slate-11"
      />
      <span
        class="flex-1 min-w-0 text-sm truncate"
        :class="hasValue ? 'text-n-slate-12' : 'text-n-slate-11'"
      >
        {{ displayLabel || '\u00A0' }}
      </span>
      <span
        class="i-lucide-chevron-down size-3.5 shrink-0 text-n-slate-11"
        :class="{ 'rotate-180': showMenu }"
      />
      <DropdownMenu
        v-if="showMenu"
        :menu-items="menuItems"
        :show-search="showSearch"
        :thumbnail-size="20"
        class="w-full min-w-[14rem] max-h-64 mt-1 top-full ltr:left-0 rtl:right-0 z-[100]"
        @click.stop
        @action="onAction"
      />
    </div>
  </OutlinedAttributeField>
</template>
