<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

// CUSTOMIZAÇÃO_SYNAPSEOS — Bell de notificações pessoais.
// Click navega pra /app/accounts/:id/notifications (rota inbox_view).
// Badge de unread REMOVIDO (cliente não usa o contador; o "1" fixo
// incomodava os usuários).

const { t } = useI18n();
const { accountId } = useAccount();

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
  </RouterLink>
</template>
