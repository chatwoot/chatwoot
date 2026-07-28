<script setup>
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const setupVoiceChannel = () => {
  router.push({
    name: 'settings_inbox_new',
    params: { accountId: route.params.accountId },
  });
};
</script>

<template>
  <EmptyStateLayout
    :title="t('CALLS_PAGE.SETUP.TITLE')"
    :subtitle="t('CALLS_PAGE.SETUP.SUBTITLE')"
    :show-backdrop="false"
    :action-perms="['administrator']"
  >
    <template #actions>
      <Button
        :label="t('CALLS_PAGE.SETUP.ACTION')"
        icon="i-lucide-plus"
        @click="setupVoiceChannel"
      />
    </template>
  </EmptyStateLayout>
</template>
