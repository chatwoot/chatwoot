<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  readOnly: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'focusChange']);

const [showAttributeListDropdown, toggleAttributeListDropdown] = useToggle();

const attributeListMenuItems = computed(() => {
  return (
    props.attribute.attributeValues?.map(value => ({
      label: value,
      value,
      action: 'select',
      isSelected: value === props.attribute.value,
    })) || []
  );
});

const openDropdown = () => {
  if (props.readOnly) return;
  toggleAttributeListDropdown(true);
  emit('focusChange', true);
};

const closeDropdown = () => {
  toggleAttributeListDropdown(false);
  emit('focusChange', false);
};

const handleAttributeAction = async action => {
  emit('update', action.value);
  closeDropdown();
};
</script>

<template>
  <div
    v-on-clickaway="closeDropdown"
    class="relative flex items-center w-full min-h-8 min-w-0"
    :class="{ 'cursor-pointer': !readOnly }"
    @click="openDropdown"
  >
    <span
      class="min-w-0 text-sm text-n-slate-12 truncate"
      :class="{ 'opacity-0': !attribute.value }"
    >
      {{ attribute.value || '\u00A0' }}
    </span>
    <DropdownMenu
      v-if="showAttributeListDropdown"
      :menu-items="attributeListMenuItems"
      show-search
      class="w-48 mt-2 top-full ltr:left-0 rtl:right-0 z-50"
      @click.stop
      @action="handleAttributeAction($event)"
    />
  </div>
</template>
