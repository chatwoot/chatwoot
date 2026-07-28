<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { isCloudFeatureEnabled } = useAccount();

const isCaptainV2Enabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
);

const navItems = computed(() => {
  const items = [
    {
      routeName: 'captain_assistants_settings_index',
      icon: 'i-lucide-settings',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.TITLE'),
    },
    {
      routeName: 'captain_assistants_settings_system_index',
      icon: 'i-lucide-sliders-horizontal',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE'),
    },
    {
      routeName: 'captain_assistants_settings_audience_index',
      icon: 'i-lucide-users',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.AUDIENCE.TITLE'),
    },
    {
      routeName: 'captain_assistants_settings_schedule_index',
      icon: 'i-lucide-calendar-clock',
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.SCHEDULE.TITLE'),
    },
  ];

  if (isCaptainV2Enabled.value) {
    items.push(
      {
        routeName: 'captain_assistants_guardrails_index',
        icon: 'i-lucide-shield-check',
        label: t(
          'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.TITLE'
        ),
      },
      {
        routeName: 'captain_assistants_guidelines_index',
        icon: 'i-lucide-message-square-text',
        label: t(
          'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.TITLE'
        ),
      }
    );
  }

  return items;
});

const navTarget = routeName => ({
  name: routeName,
  params: {
    accountId: route.params.accountId,
    assistantId: route.params.assistantId,
  },
});

const handleNavClick = item => router.push(navTarget(item.routeName));
</script>

<template>
  <nav class="sticky self-start flex flex-col flex-shrink-0 w-48 gap-1 top-0">
    <button
      v-for="item in navItems"
      :key="item.routeName"
      type="button"
      class="flex items-center gap-2 px-3 py-2 text-sm text-left rounded-lg transition-colors"
      :class="
        route.name === item.routeName
          ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
          : 'text-n-slate-11 hover:bg-n-alpha-1'
      "
      @click="handleNavClick(item)"
    >
      <span :class="item.icon" class="flex-shrink-0 size-4" />
      {{ item.label }}
    </button>
  </nav>
</template>
