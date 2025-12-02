<script setup>
// import { computed } from 'vue';
// import { useI18n } from 'vue-i18n';
// import { useRouter } from 'vue-router';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';

// const router = useRouter();
// const { t } = useI18n();
</script>

<template>
  <SettingsLayout :no-records-found="false" class="gap-10">
    <template #header>
      <BaseSettingsHeader
        :title="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.TITLE')"
        :description="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.DESCRIPTION')"
        feature-name="assignment-policy"
      />
    </template>

    <template #body>
      <div class="grid grid-cols-1 gap-6 2xl:grid-cols-2">
        <span>{{ $t('CONVERSATION_WORKFLOW.INDEX.HEADER.TITLE') }}</span>
      </div>
    </template>
  </SettingsLayout>
</template>
