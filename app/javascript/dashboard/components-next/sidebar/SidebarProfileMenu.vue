<script setup>
import { computed } from 'vue';
import Auth from 'dashboard/api/auth';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'next/icon/Icon.vue';
import SidebarProfileMenuStatus from './SidebarProfileMenuStatus.vue';

const emit = defineEmits(['close', 'openKeyShortcutModal']);

defineOptions({
  inheritAttrs: false,
});

const { t } = useI18n();
const router = useRouter();

const globalConfig = useMapGetter('globalConfig/get');
const currentUser = useMapGetter('getCurrentUser');
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');
const [showProfileMenu, toggleProfileMenu] = useToggle(false);

const closeMenu = () => {
  if (showProfileMenu.value) {
    emit('close');
    toggleProfileMenu(false);
  }
};

const menuItems = computed(() => {
  return [
    {
      show: !!globalConfig.value.chatwootInboxToken,
      label: t('SIDEBAR_ITEMS.CONTACT_SUPPORT'),
      icon: 'i-lucide-life-buoy',
      click: () => {
        closeMenu();
        window.$chatwoot.toggle();
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS'),
      icon: 'i-lucide-keyboard',
      click: () => {
        closeMenu();
        emit('openKeyShortcutModal');
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.PROFILE_SETTINGS'),
      icon: 'i-lucide-user-pen',
      click: () => {
        closeMenu();
        router.push({ name: 'profile_settings_index' });
      },
    },
    {
      show: true,
      label: t('SIDEBAR_ITEMS.APPEARANCE'),
      icon: 'i-lucide-swatch-book',
      click: () => {
        closeMenu();
        const ninja = document.querySelector('ninja-keys');
        ninja.open({ parent: 'appearance_settings' });
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
      icon: 'i-lucide-log-out',
      click: Auth.logout,
    },
  ];
});

const allowedMenuItems = computed(() => {
  return menuItems.value.filter(item => item.show);
});
</script>

<template>
  <div class="relative z-20 w-full min-w-0">
    <button
      class="flex gap-2 items-center rounded-lg cursor-pointer text-left w-full hover:bg-n-alpha-1 p-1"
      v-bind="$attrs"
      :class="{
        'bg-n-alpha-1': showProfileMenu,
      }"
      @click="toggleProfileMenu"
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
    <div
      v-if="showProfileMenu"
      v-on-clickaway="closeMenu"
      class="absolute left-0 bottom-12 z-50"
    >
      <div
        class="w-72 min-h-32 bg-n-solid-1 border border-n-weak rounded-xl shadow-sm"
      >
        <SidebarProfileMenuStatus />
        <div class="border-t border-n-strong mx-2 my-0" />
        <ul class="list-none m-0 grid gap-1 p-1 text-n-slate-12">
          <li v-for="item in allowedMenuItems" :key="item.label" class="m-0">
            <component
              :is="item.link ? 'a' : 'button'"
              v-bind="item.link ? { target: item.target, href: item.link } : {}"
              class="text-left hover:bg-n-alpha-1 px-2 py-1.5 w-full flex items-center gap-2"
              @click="item.click"
            >
              <Icon :icon="item.icon" class="size-4" />
              {{ item.label }}
            </component>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
