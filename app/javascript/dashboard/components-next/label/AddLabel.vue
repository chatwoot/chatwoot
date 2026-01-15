<script setup>
import { ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { useResizeObserver } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  labelMenuItems: {
    type: Array,
    default: () => [],
  },
  wrapperRef: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['updateLabel']);

const { t } = useI18n();

const showDropdown = ref(false);
const triggerRef = ref(null);
const dropdownRef = ref(null);

const { position, updatePosition } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  showDropdown,
  { container: props.wrapperRef }
);

const openDropdown = async () => {
  showDropdown.value = !showDropdown.value;
  if (showDropdown.value) {
    await nextTick();
    updatePosition();
  }
};

const updateLabel = label => {
  emit('updateLabel', label);
};

const closeDropdown = () => {
  showDropdown.value = false;
};

// Watch labelMenuItems and update position when they change
watch(
  () => props.labelMenuItems,
  async () => {
    if (showDropdown.value) {
      await nextTick();
      updatePosition();
    }
  },
  { deep: true }
);

// Watch wrapper container for size changes (hover effects from parent)
useResizeObserver(props.wrapperRef, () => {
  if (showDropdown.value) {
    updatePosition();
  }
});
</script>

<template>
  <div
    v-on-click-outside="[closeDropdown, { ignore: [triggerRef] }]"
    class="relative"
  >
    <Button
      ref="triggerRef"
      :label="t('LABEL.TAG_BUTTON')"
      sm
      slate
      :variant="showDropdown ? 'faded' : 'solid'"
      class="font-460 !-outline-offset-1"
      icon="i-lucide-plus"
      @click="openDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      ref="dropdownRef"
      :menu-items="labelMenuItems"
      show-search
      class="z-[100] w-48 overflow-y-auto max-h-52"
      :class="position.class"
      :style="position.style"
      @action="updateLabel($event)"
    >
      <template #thumbnail="{ item }">
        <div
          class="rounded-sm size-2"
          :style="{ backgroundColor: item.thumbnail.color }"
        />
      </template>
      <template #trailing-icon="{ item }">
        <Icon
          v-if="item.isSelected"
          icon="i-lucide-check"
          class="size-4 text-n-blue-11 flex-shrink-0"
        />
      </template>
    </DropdownMenu>
  </div>
</template>
