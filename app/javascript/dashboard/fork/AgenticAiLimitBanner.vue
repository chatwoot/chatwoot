<script setup>
/**
 * Fork banner: warns admins when the account has reached the agentic-AI
 * (automated workflow) cap enforced by the external NestJS backend.
 *
 * Data rides the existing quota pipeline — the account limits endpoint exposes
 * `agentic_ai: { allowed, consumed }` (see the Custom accounts controller and
 * docs/fork/ENTITLEMENTS.md), so this reuses `useQuota` and adds no coupling to
 * NestJS. Self-contained under dashboard/fork/ and mounted with a single line
 * in App.vue to keep upstream merges clean.
 */
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useQuota } from 'dashboard/composables/useQuota';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Banner from 'dashboard/components/ui/Banner.vue';

const { t } = useI18n();
const { isAdmin } = useAdmin();
const { quota, atQuotaLimit } = useQuota('agentic_ai');

const shouldShow = computed(() => isAdmin.value && atQuotaLimit.value);

const bannerMessage = computed(() =>
  t('AGENTIC_AI_LIMIT.BANNER', {
    consumed: quota.value?.consumed,
    allowed: quota.value?.allowed,
  })
);
</script>

<template>
  <Banner
    v-if="shouldShow"
    color-scheme="warning"
    :banner-message="bannerMessage"
  />
</template>
