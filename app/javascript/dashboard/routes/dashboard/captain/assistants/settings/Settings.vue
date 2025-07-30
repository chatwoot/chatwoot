<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsPageLayout from 'dashboard/components-next/captain/SettingsPageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import AssistantBasicSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantBasicSettingsForm.vue';
import AssistantSystemSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantSystemSettingsForm.vue';
import AssistantControlItems from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantControlItems.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const assistantId = route.params.assistantId;
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistant = computed(() =>
  store.getters['captainAssistants/getRecord'](Number(assistantId))
);

const isAssistantAvailable = computed(() => !!assistant.value?.id);

const controlItems = computed(() => {
  return [
    {
      name: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.TITLE'
      ),
      description: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.DESCRIPTION'
      ),
      routeName: 'captain_assistants_guardrails_index',
    },
    {
      name: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.SCENARIOS.TITLE'
      ),
      description: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.SCENARIOS.DESCRIPTION'
      ),
      routeName: 'captain_assistants_scenarios_index',
    },
    {
      name: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.TITLE'
      ),
      description: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.DESCRIPTION'
      ),
      routeName: 'captain_assistants_guidelines_index',
    },
  ];
});

const breadcrumbItems = computed(() => {
  const activeControlItem = controlItems.value?.find(
    item => item.routeName === route.name
  );

  return [
    {
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.BREADCRUMB.ASSISTANT'),
      routeName: 'captain_assistants_index',
    },
    { label: assistant.value?.name, routeName: 'captain_assistants_edit' },
    ...(activeControlItem
      ? [
          {
            label: activeControlItem.name,
            routeName: activeControlItem.routeName,
          },
        ]
      : []),
  ];
});

const handleSubmit = async updatedAssistant => {
  try {
    await store.dispatch('captainAssistants/update', {
      id: assistantId,
      ...updatedAssistant,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  if (!isAssistantAvailable.value) {
    store.dispatch('captainAssistants/show', assistantId);
  }
});
</script>

<template>
  <SettingsPageLayout
    :breadcrumb-items="breadcrumbItems"
    :is-fetching="isFetching"
    class="[&>div]:max-w-[80rem]"
  >
    <template #body>
      <div class="flex flex-col gap-6">
        <div class="flex flex-col gap-6">
          <SettingsHeader
            :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.TITLE')"
            :description="
              t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.DESCRIPTION')
            "
          />
          <AssistantBasicSettingsForm
            :assistant="assistant"
            @submit="handleSubmit"
          />
        </div>
        <span class="h-px w-full bg-n-weak mt-2" />
        <div class="flex flex-col gap-6">
          <SettingsHeader
            :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE')"
            :description="
              t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.DESCRIPTION')
            "
          />
          <AssistantSystemSettingsForm
            :assistant="assistant"
            @submit="handleSubmit"
          />
        </div>
      </div>
    </template>
    <template #controls>
      <div class="flex flex-col gap-6">
        <SettingsHeader
          :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.TITLE')"
          :description="
            t('CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.DESCRIPTION')
          "
        />
        <div class="flex flex-col gap-6">
          <AssistantControlItems
            v-for="item in controlItems"
            :key="item.name"
            :control-item="item"
          />
        </div>
      </div>
    </template>
  </SettingsPageLayout>
</template>
