<script setup>
import { ref } from 'vue';
import DropdownMenu from './DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
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
  <Story title="Components/DropdownMenu" :layout="{ type: 'grid', width: 300 }">
    <Variant title="Default">
      <div class="p-4 bg-white h-72 dark:bg-slate-900">
        <div class="relative">
          <Button label="Open Menu" size="sm" @click="toggleDropdown" />
          <DropdownMenu
            v-if="isOpen"
            :menu-items="menuItems"
            class="absolute left-0 top-10"
            @action="handleAction"
          />
        </div>
      </div>
    </Variant>

    <Variant title="Always Open">
      <div class="p-4 bg-white h-72 dark:bg-slate-900">
        <DropdownMenu :menu-items="menuItems" @action="handleAction" />
      </div>
    </Variant>

    <Variant title="Custom Items">
      <div class="p-4 bg-white h-72 dark:bg-slate-900">
        <DropdownMenu
          :menu-items="[
            { label: 'Custom 1', action: 'custom1', icon: 'file-upload' },
            { label: 'Custom 2', action: 'custom2', icon: 'document' },
            { label: 'Danger', action: 'delete', icon: 'delete' },
          ]"
          @action="handleAction"
        />
      </div>
    </Variant>

    <Variant title="With search">
      <div class="p-4 bg-white h-72 dark:bg-slate-900">
        <DropdownMenu
          :menu-items="[
            { label: 'Custom 1', action: 'custom1', icon: 'file-upload' },
            { label: 'Custom 2', action: 'custom2', icon: 'document' },
            { label: 'Danger', action: 'delete', icon: 'delete' },
          ]"
          show-search
          @action="handleAction"
        />
      </div>
    </Variant>
  </Story>
</template>
