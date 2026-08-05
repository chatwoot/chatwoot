<script setup>
import { computed, onBeforeMount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { SENDER_LIST_TYPES } from 'dashboard/constants/senderLists';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SenderListSection from './SenderListSection.vue';

const { t } = useI18n();
const store = useStore();

const uiFlags = useMapGetter('senderListEntries/getUIFlags');
const entries = useMapGetter('senderListEntries/getEntries');

const isLoading = computed(
  () => uiFlags.value.isFetching && !entries.value.length
);

const sections = computed(() =>
  SENDER_LIST_TYPES.map(listType => ({
    listType,
    title: t(`SENDER_LISTS.LISTS.${listType.toUpperCase()}.TITLE`),
    description: t(`SENDER_LISTS.LISTS.${listType.toUpperCase()}.DESCRIPTION`),
  }))
);

onBeforeMount(() => {
  store.dispatch('senderListEntries/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('SENDER_LISTS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('SENDER_LISTS.HEADER')"
        :description="$t('SENDER_LISTS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-8">
        <SenderListSection
          v-for="section in sections"
          :key="section.listType"
          :list-type="section.listType"
          :title="section.title"
          :description="section.description"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
