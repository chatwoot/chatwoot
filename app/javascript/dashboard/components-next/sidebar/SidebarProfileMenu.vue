<script setup>
import { computed } from 'vue';
import Auth from 'dashboard/api/auth';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import SidebarProfileMenuStatus from './SidebarProfileMenuStatus.vue';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSeparator,
  DropdownItem,
} from 'next/dropdown-menu/base';

const emit = defineEmits(['close', 'openKeyShortcutModal']);

defineOptions({
  inheritAttrs: false,
});

const { t } = useI18n();
const router = useRouter();

const globalConfig = useMapGetter('globalConfig/get');
const currentUser = useMapGetter('getCurrentUser');
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');

const menuItems = computed(() => {
  return [
    {
      show: !!globalConfig.value.chatwootInboxToken,
      label: t('SIDEBAR_ITEMS.CONTACT_SUPPORT'),
      icon: 'i-lucide-life-buoy',
      click: () => {
        window.$chatwoot.toggle();
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS'),
      icon: 'i-lucide-keyboard',
      click: () => {
        emit('openKeyShortcutModal');
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.PROFILE_SETTINGS'),
      icon: 'i-lucide-user-pen',
      click: () => {
        router.push({ name: 'profile_settings_index' });
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.APPEARANCE'),
      icon: 'i-lucide-palette',
      click: () => {
        const ninja = document.querySelector('ninja-keys');
        ninja.open({ parent: 'appearance_settings' });
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.DOCS'),
      icon: 'i-lucide-book',
      click: () => {
        window.open('https://www.chatwoot.com/hc/user-guide/en', '_blank');
      },
    },
    {
      show: currentUser.value.type === 'SuperAdmin',
      label: t('SIDEBAR_ITEMS.SUPER_ADMIN_CONSOLE'),
      icon: 'i-lucide-castle',
      link: '/super_admin',
      target: '_blank',
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.LOGOUT'),
      icon: 'i-lucide-power',
      click: Auth.logout,
    },
  ];
});

const allowedMenuItems = computed(() => {
  return menuItems.value.filter(item => item.show);
});
</script>

<template>
  <DropdownContainer
    class="relative z-20 w-full min-w-0"
    @close="emit('close')"
  >
    <template #trigger="{ toggle, isOpen }">
      <button
        class="flex gap-2 items-center rounded-lg cursor-pointer text-left w-full hover:bg-n-alpha-1 p-1"
        :class="{ 'bg-n-alpha-1': isOpen }"
        @click="toggle"
      >
        <Avatar
          :size="32"
          :name="currentUser.available_name"
          :src="currentUser.avatar_url"
          :status="currentUserAvailability"
          class="flex-shrink-0"
          rounded-full
        />
        <div class="min-w-0">
          <div class="text-n-slate-12 text-sm leading-4 font-medium truncate">
            {{ currentUser.available_name }}
          </div>
          <div class="text-n-slate-11 text-xs truncate">
            {{ currentUser.email }}
          </div>
        </div>
      </button>
    </template>
    <DropdownBody class="left-0 bottom-12 z-50 w-80 mb-1">
      <SidebarProfileMenuStatus />
      <DropdownSeparator />
      <template v-for="item in allowedMenuItems" :key="item.label">
        <DropdownItem v-if="item.show" v-bind="item" />
      </template>
    </DropdownBody>
  </DropdownContainer>
</template>
