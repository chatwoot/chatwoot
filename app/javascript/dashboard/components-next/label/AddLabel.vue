<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  labelMenuItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['updateLabel']);

const { t } = useI18n();

const showDropdown = ref(false);
const triggerRef = ref(null);
const dropdownRef = ref(null);

const { positionClasses } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  showDropdown
);
</script>

<template>
  <div class="relative">
    <Button
      ref="triggerRef"
      :label="t('LABEL.TAG_BUTTON')"
      sm
      slate
      :variant="showDropdown ? 'faded' : 'solid'"
      class="font-460 !-outline-offset-1"
      icon="i-lucide-plus"
      @click="showDropdown = !showDropdown"
    />
    <DropdownMenu
      v-if="showDropdown"
      ref="dropdownRef"
      v-on-clickaway="() => (showDropdown = false)"
      :menu-items="labelMenuItems"
      show-search
      class="z-[100] w-48 overflow-y-auto max-h-52"
      :class="positionClasses"
      @action="emit('updateLabel', $event)"
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
