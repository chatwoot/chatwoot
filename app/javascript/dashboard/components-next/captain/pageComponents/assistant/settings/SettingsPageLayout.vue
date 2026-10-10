<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import VerticalTabs from 'dashboard/components-next/vertical-tabs/VerticalTabs.vue';

defineProps({
  heading: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);

const tabs = computed(() => {
  const items = [
    {
      id: 'captain_assistants_settings_index',
      icon: 'i-lucide-settings',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.TITLE'),
    },
    {
      id: 'captain_assistants_settings_system_index',
      icon: 'i-lucide-sliders-horizontal',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE'),
    },
    {
      id: 'captain_assistants_settings_audience_index',
      icon: 'i-lucide-users',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.AUDIENCE.TITLE'),
    },
    {
      id: 'captain_assistants_settings_schedule_index',
      icon: 'i-lucide-calendar-clock',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.SCHEDULE.TITLE'),
    },
  ];

  items.push(
    {
      id: 'captain_assistants_guardrails_index',
      icon: 'i-lucide-shield-check',
      label: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.TITLE'
      ),
    },
    {
      id: 'captain_assistants_guidelines_index',
      icon: 'i-lucide-message-square-text',
      label: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.TITLE'
      ),
    }
  );

  return items;
});

const activeTab = computed({
  get: () => route.name,
  set: name =>
    router.push({
      name,
      params: {
        accountId: route.params.accountId,
        assistantId: route.params.assistantId,
      },
    }),
});
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.ASSISTANTS.SETTINGS.HEADER')"
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <VerticalTabs
        v-model="activeTab"
        :tabs="tabs"
        content-class="max-w-[45rem] pb-24 lg:pb-8"
      >
        <template #[activeTab]>
          <div class="flex flex-col w-full gap-6">
            <SettingsHeader :heading="heading" :description="description" />
            <slot />
          </div>
        </template>
      </VerticalTabs>
    </template>
  </PageLayout>
</template>
