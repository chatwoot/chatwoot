<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const route = useRoute();

/**
 * Per-account Tasks board URLs (injected from CORO_TASKS_URL_BY_ACCOUNT).
 * account 4 → admin-essentials MSH, 5 → LG, 7 → company-chat Yalla desk.
 * Accounts with no mapping show an empty state instead of inheriting MSH tasks.
 */
function resolveTasksUrl(accountId) {
  const byAccount = window.chatwootConfig?.coroTasksUrlByAccount;
  if (byAccount && typeof byAccount === 'object') {
    const mapped = byAccount[String(accountId)] || byAccount[Number(accountId)];
    if (typeof mapped === 'string' && mapped.trim()) return mapped.trim();
  }

  // Backward compat: only MSH (account 4) may fall back to the global CORO_HOME_URL.
  const home = window.chatwootConfig?.coroHomeUrl || '';
  if (!home) return '';
  if (String(accountId) !== '4') return '';

  try {
    const url = new URL(home, window.location.origin);
    if (!url.searchParams.has('brand')) url.searchParams.set('brand', 'msh');
    return url.toString();
  } catch {
    const sep = home.includes('?') ? '&' : '?';
    return home.includes('brand=') ? home : `${home}${sep}brand=msh`;
  }
}

const homeUrl = computed(() => resolveTasksUrl(route.params.accountId));
</script>

<template>
  <div class="flex h-full min-h-0 w-full flex-col bg-n-background">
    <div
      v-if="!homeUrl"
      class="flex flex-1 items-center justify-center p-6 text-sm text-n-slate-11"
    >
      {{ t('OPS_TASKS.MISSING_URL') }}
    </div>
    <iframe
      v-else
      :src="homeUrl"
      :title="t('OPS_TASKS.IFRAME_TITLE')"
      class="h-full w-full flex-1 border-0"
      allow="clipboard-read; clipboard-write"
    />
  </div>
</template>
