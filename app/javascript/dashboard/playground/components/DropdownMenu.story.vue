<script setup>
import { ref } from 'vue';
import DropdownMenu from './DropdownMenu.vue';
import Button from './Button.vue';

const menuItems = [
  { label: 'Edit', action: 'edit', icon: 'edit' },
  { label: 'Publish', action: 'publish', icon: 'checkmark' },
  { label: 'Archive', action: 'archive', icon: 'archive' },
  { label: 'Delete', action: 'delete', icon: 'delete' },
];

const isOpen = ref(false);

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
};

const handleAction = () => {
  isOpen.value = false;
};
</script>

<template>
  <Story title="Components/DropdownMenu" :layout="{ type: 'grid', width: 200 }">
    <Variant title="Default">
      <div class="relative h-40">
        <Button label="Open Menu" @click="toggleDropdown" />
        <DropdownMenu
          v-if="isOpen"
          :menu-items="menuItems"
          class="absolute left-0 mt-2 top-full"
          @action="handleAction"
        />
      </div>
    </Variant>

    <Variant title="Always Open">
      <DropdownMenu :menu-items="menuItems" @action="handleAction" />
    </Variant>

    <Variant title="Custom Items">
      <DropdownMenu
        :menu-items="[
          { label: 'Custom 1', action: 'custom1', icon: 'file-upload' },
          { label: 'Custom 2', action: 'custom2', icon: 'document' },
          { label: 'Danger', action: 'delete', icon: 'delete' },
        ]"
        @action="handleAction"
      />
    </Variant>
  </Story>
</template>
