<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Avatar from 'next/avatar/Avatar.vue';
import MobileSettingsHeader from './MobileSettingsHeader.vue';
import MobileAvailabilityToggle from './MobileAvailabilityToggle.vue';

const store = useStore();
const { t } = useI18n();

const currentUser = useMapGetter('getCurrentUser');

const userName = computed(() => currentUser.value?.name || '');
const userEmail = computed(() => currentUser.value?.email || '');
const userAvatar = computed(() => currentUser.value?.avatar_url || '');
const userAvailability = computed(
  () => currentUser.value?.availability_status || 'online'
);

const onAvailabilityChange = status => {
  store.dispatch('updateAvailability', {
    availability: status,
    account_id: currentUser.value.account_id,
  });
};

const onLogout = () => {
  store.dispatch('logout');
};

const settingsItems = computed(() => [
  {
    icon: 'i-lucide-bell',
    label: t('MOBILE.SETTINGS.NOTIFICATIONS'),
    action: 'notifications',
  },
  {
    icon: 'i-lucide-globe',
    label: t('MOBILE.SETTINGS.LANGUAGE'),
    action: 'language',
  },
]);
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-y-auto">
    <MobileSettingsHeader />

    <!-- User Profile Section -->
    <div class="flex items-center gap-3 px-4 py-5 border-b border-n-weak">
      <Avatar :src="userAvatar" :name="userName" :size="56" />
      <div class="flex flex-col min-w-0">
        <span class="text-base font-semibold text-n-slate-12 truncate">
          {{ userName }}
        </span>
        <span class="text-sm text-n-slate-10 truncate">
          {{ userEmail }}
        </span>
      </div>
    </div>

    <!-- Availability -->
    <div class="px-4 py-4 border-b border-n-weak">
      <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block">
        {{ t('MOBILE.SETTINGS.AVAILABILITY') }}
      </span>
      <MobileAvailabilityToggle
        :current-status="userAvailability"
        @change="onAvailabilityChange"
      />
    </div>

    <!-- Settings List -->
    <div class="flex flex-col">
      <button
        v-for="item in settingsItems"
        :key="item.action"
        class="flex items-center gap-3 px-4 py-3.5 text-left text-n-slate-12 active:bg-n-alpha-1 border-b border-n-weak"
      >
        <span class="size-5" :class="item.icon" />
        <span class="text-sm">{{ item.label }}</span>
        <span class="i-lucide-chevron-right size-4 ml-auto text-n-slate-10" />
      </button>
    </div>

    <!-- Logout -->
    <div class="px-4 py-4 mt-auto">
      <button
        class="flex items-center justify-center gap-2 w-full py-3 text-sm font-medium text-n-ruby-9 rounded-lg border border-n-weak active:bg-n-alpha-1"
        @click="onLogout"
      >
        <span class="i-lucide-log-out size-4" />
        {{ t('MOBILE.SETTINGS.LOGOUT') }}
      </button>
    </div>
  </div>
</template>
