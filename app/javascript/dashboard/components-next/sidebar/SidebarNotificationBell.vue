<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

// CUSTOMIZAÇÃO_SYNAPSEOS — Bell de notificações pessoais.
// Click navega pra /app/accounts/:id/notifications (rota inbox_view do
// Chatwoot), que mostra menções, atribuições e alertas pessoais do agente.
// Badge cyan Dexi com contagem de unread (igual badges de item ativo
// na sidebar), com ring pra destacar sobre o fundo navy.

const { t } = useI18n();
const { accountId } = useAccount();
const notificationMetadata = useMapGetter('notifications/getMeta');

const unreadCount = computed(() => {
  const n = notificationMetadata.value?.unreadCount || 0;
  if (!n) return '';
  return n < 100 ? `${n}` : '99+';
});

const target = computed(() => ({
  name: 'inbox_view',
  params: { accountId: accountId.value },
}));
</script>

<template>
  <RouterLink
    :to="target"
    :title="t('SIDEBAR_ITEMS.NOTIFICATIONS')"
    :aria-label="t('SIDEBAR_ITEMS.NOTIFICATIONS')"
    class="flex items-center justify-center size-9 rounded-lg border border-white/10 bg-white/[0.06] text-s-on-dark-muted hover:bg-white/10 hover:text-s-on-dark transition-colors flex-shrink-0 relative"
    active-class="!bg-s-brand-800 !text-s-on-dark !border-s-accent-500"
  >
    <span class="i-lucide-bell size-4" />
    <span
      v-if="unreadCount"
      class="min-w-4 h-4 px-1 bg-s-accent-500 rounded-full absolute -top-1 -right-1 grid place-items-center text-[9px] leading-none font-semibold text-s-brand-900 ring-2 ring-s-sidebar"
    >
      {{ unreadCount }}
    </span>
  </RouterLink>
</template>
