<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownContainer from './base/DropdownContainer.vue';
import DropdownBody from './base/DropdownBody.vue';
import DropdownSection from './base/DropdownSection.vue';
import DropdownItem from './base/DropdownItem.vue';
import DropdownSeparator from './base/DropdownSeparator.vue';
import WootSwitch from 'components/ui/Switch.vue';

const currentUserAutoOffline = ref(false);

const menuItems = ref([
  {
    label: 'Contact Support',
    icon: 'i-lucide-life-buoy',
    click: () => console.log('Contact Support'),
  },
  {
    label: 'Keyboard Shortcuts',
    icon: 'i-lucide-keyboard',
    click: () => console.log('Keyboard Shortcuts'),
  },
  {
    label: 'Profile Settings',
    icon: 'i-lucide-user-pen',
    click: () => console.log('Profile Settings'),
  },
  {
    label: 'Change Appearance',
    icon: 'i-lucide-swatch-book',
    click: () => console.log('Change Appearance'),
  },
  {
    label: 'Open SuperAdmin',
    icon: 'i-lucide-castle',
    link: '/super_admin',
    target: '_blank',
  },
  {
    label: 'Log Out',
    icon: 'i-lucide-log-out',
    click: () => console.log('Log Out'),
  },
]);
</script>

<template>
  <Story
    title="Components/DropdownPrimitives"
    :layout="{ type: 'grid', width: 400, height: 800 }"
  >
    <Variant title="Profile Menu">
      <div class="p-4 bg-white h-[500px] dark:bg-slate-900">
        <DropdownContainer>
          <template #trigger="{ toggle }">
            <Button label="Open Menu" size="sm" @click="toggle" />
          </template>
          <DropdownBody class="w-80">
            <DropdownSection title="Profile Options">
              <DropdownItem label="Contact Support" class="justify-between">
                <span>{{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}</span>
                <div class="flex-shrink-0">
                  <WootSwitch v-model="currentUserAutoOffline" />
                </div>
              </DropdownItem>
            </DropdownSection>
            <DropdownSeparator />
            <DropdownItem
              v-for="item in menuItems"
              :key="item.label"
              v-bind="item"
            />
          </DropdownBody>
        </DropdownContainer>
      </div>
    </Variant>
  </Story>
</template>
