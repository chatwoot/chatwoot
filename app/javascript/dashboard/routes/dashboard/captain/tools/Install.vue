<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const selectedAssistantId = ref('');
const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');

const assistantOptions = computed(() =>
  assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
  }))
);
const isFetching = computed(() => uiFlags.value.fetchingList);
const hasAssistants = computed(() => assistantOptions.value.length > 0);

const continueInstall = () => {
  if (!selectedAssistantId.value || !route.query.source) return;

  router.push({
    name: 'captain_tools_index',
    params: {
      accountId: route.params.accountId,
      assistantId: selectedAssistantId.value,
    },
    query: { source: route.query.source },
  });
};

const createAssistant = () => {
  router.push({
    name: 'captain_assistants_create_index',
    params: { accountId: route.params.accountId },
  });
};

onMounted(() => store.dispatch('captainAssistants/get'));
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.CUSTOM_TOOLS.INSTALL.TITLE')"
    :show-assistant-switcher="false"
    :show-pagination-footer="false"
    :is-fetching="isFetching"
    container-class="max-w-[40rem]"
  >
    <template #body>
      <div class="flex flex-col gap-5 p-6 rounded-xl bg-n-alpha-2">
        <div class="flex flex-col gap-1">
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL.SELECT_TITLE') }}
          </h2>
          <p class="text-body-2 text-n-slate-11">
            {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL.SELECT_DESCRIPTION') }}
          </p>
        </div>

        <template v-if="hasAssistants">
          <ComboBox
            v-model="selectedAssistantId"
            :options="assistantOptions"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.INSTALL.PLACEHOLDER')"
          />
          <Button
            class="self-end"
            :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL.CONTINUE')"
            :disabled="!selectedAssistantId"
            @click="continueInstall"
          />
        </template>

        <template v-else-if="!isFetching">
          <p class="text-body-2 text-n-slate-11">
            {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL.NO_ASSISTANTS') }}
          </p>
          <Button
            class="self-start"
            :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL.CREATE_ASSISTANT')"
            @click="createAssistant"
          />
        </template>
      </div>
    </template>
  </PageLayout>
</template>
