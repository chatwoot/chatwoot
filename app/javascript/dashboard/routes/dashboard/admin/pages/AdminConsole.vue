<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const adminCards = computed(() => [
  {
    id: 'users',
    title: t('ADMIN.USERS_AND_PERMISSIONS'),
    description: t('ADMIN.USERS_AND_PERMISSIONS_DESC'),
    icon: 'i-lucide-users',
    route: accountScopedRoute('agent_list'),
    color: 'iris',
  },
  {
    id: 'inboxes',
    title: t('ADMIN.INBOXES_CHANNELS'),
    description: t('ADMIN.INBOXES_CHANNELS_DESC'),
    icon: 'i-lucide-mailbox',
    route: accountScopedRoute('settings_inbox_list'),
    color: 'jade',
  },
  {
    id: 'conversations',
    title: t('ADMIN.MANAGERIAL_CONVERSATIONS'),
    description: t('ADMIN.MANAGERIAL_CONVERSATIONS_DESC'),
    icon: 'i-lucide-message-circle',
    route: accountScopedRoute('admin_conversations'),
    color: 'amber',
  },
  {
    id: 'integrations',
    title: t('ADMIN.INTEGRATIONS_ENDPOINTS'),
    description: t('ADMIN.INTEGRATIONS_ENDPOINTS_DESC'),
    icon: 'i-lucide-plug',
    route: accountScopedRoute('settings_applications'),
    color: 'ruby',
  },
  {
    id: 'branding',
    title: t('ADMIN.BRANDING_THEMES'),
    description: t('ADMIN.BRANDING_THEMES_DESC'),
    icon: 'i-lucide-palette',
    route: accountScopedRoute('branding_settings_index'),
    color: 'violet',
  },
]);

const handleCardClick = card => {
  router.push(card.route);
};
</script>

<template>
  <div class="flex flex-col h-full w-full bg-n-solid-1">
    <div class="flex flex-col gap-6 p-8 max-w-7xl mx-auto w-full">
      <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('ADMIN.CONSOLE_TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('ADMIN.CONSOLE_DESCRIPTION') }}
        </p>
      </div>

      <div class="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
        <button
          v-for="card in adminCards"
          :key="card.id"
          class="flex flex-col gap-3 p-6 rounded-lg border border-n-weak bg-n-solid-2 hover:bg-n-solid-3 hover:border-n-slate-8 transition-all cursor-pointer text-left group"
          @click="handleCardClick(card)"
        >
          <div
            class="flex items-center justify-center size-12 rounded-lg bg-n-weak group-hover:bg-n-alpha-2 transition-colors"
            :class="`text-${card.color}-11`"
          >
            <span :class="`${card.icon} size-6`" />
          </div>
          <div class="flex flex-col gap-1">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ card.title }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ card.description }}
            </p>
          </div>
        </button>
      </div>
    </div>
  </div>
</template>

