<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const captainAssistants = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const searchQuery = ref('');

const tableHeaders = computed(() => {
  return [
    t('AGENT_BOTS.LIST.TABLE_HEADER.DETAILS'),
    t('AGENT_BOTS.LIST.TABLE_HEADER.ACTIONS'),
  ];
});

const filteredCaptainAssistants = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return captainAssistants.value;
  return picoSearch(captainAssistants.value, query, ['name', 'description']);
});

const openAssistantManager = assistant => {
  router.push({
    name: 'captain_assistants_settings_index',
    params: {
      accountId: router.currentRoute.value.params.accountId,
      assistantId: assistant.id,
    },
  });
};

const createAssistant = () => {
  router.push({
    name: 'captain_assistants_create_index',
    params: {
      accountId: router.currentRoute.value.params.accountId,
    },
  });
};

onMounted(async () => {
  try {
    await store.dispatch('agentBots/get');
  } catch (error) {
    useAlert(error.message || t('AGENT_BOTS.LIST.404'));
  }
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('AGENT_BOTS.LIST.LOADING')"
    :no-records-found="!captainAssistants.length"
    :no-records-message="t('AGENT_BOTS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="t('AGENT_BOTS.HEADER')"
        :description="t('AGENT_BOTS.DESCRIPTION')"
        :link-text="t('AGENT_BOTS.LEARN_MORE')"
        :search-placeholder="t('AGENT_BOTS.SEARCH_PLACEHOLDER')"
        feature-name="agent_bots"
      >
        <template v-if="captainAssistants?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('AGENT_BOTS.COUNT', { n: captainAssistants.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('AGENT_BOTS.ADD.TITLE')"
            size="sm"
            @click="createAssistant"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="filteredCaptainAssistants"
        :no-data-message="
          searchQuery ? t('AGENT_BOTS.NO_RESULTS') : t('AGENT_BOTS.LIST.404')
        "
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="assistant in items"
            :key="assistant.id"
            :item="assistant"
            class="cursor-pointer"
            @click="openAssistantManager(assistant)"
          >
            <template #default>
              <BaseTableCell class="max-w-0">
                <div class="flex items-center gap-4 min-w-0">
                  <Avatar
                    :name="assistant.name || ''"
                    :size="40"
                    class="flex-shrink-0"
                  />
                  <div class="min-w-0">
                    <span class="text-body-main text-n-slate-12 truncate block">
                      {{ assistant.name }}
                    </span>
                    <span class="text-body-main text-n-slate-11 block truncate">
                      {{ assistant.description }}
                    </span>
                  </div>
                </div>
              </BaseTableCell>

              <BaseTableCell align="end" class="w-40">
                <Button
                  slate
                  sm
                  :label="$t('AGENT_BOTS.MANAGE')"
                  @click.stop="openAssistantManager(assistant)"
                />
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
  </SettingsLayout>
</template>
