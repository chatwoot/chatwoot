<script setup>
import { reactive, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Switch from 'dashboard/components-next/switch/Switch.vue';
import SettingsSVG from 'dashboard/components-next/captain/AnimatingImg/Settings.vue';
import OnboardingHeader from 'dashboard/components-next/captain/assistant/OnboardingHeader.vue';
import SettingsPageLayout from 'dashboard/components-next/captain/SettingsPageLayout.vue';

const router = useRouter();
const { t } = useI18n();

const state = reactive({
  temperature: 0.7,
  features: {
    conversationFaqs: false,
    memories: false,
  },
});

const breadcrumbItems = computed(() => [
  {
    label: t('CAPTAIN.ASSISTANTS.SETTINGS.BREADCRUMB.ASSISTANT'),
    routeName: 'captain_assistants_index',
  },
  {
    label: t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.TITLE'),
    routeName: 'captain_assistants_create',
  },
]);

const handleSaveAndNext = () => {
  router.push({
    name: 'captain_assistants_create_guardrails',
  });
};
</script>

<template>
  <SettingsPageLayout
    :breadcrumb-items="breadcrumbItems"
    :header-button-label="
      t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.BUTTON_LABEL')
    "
    @click="handleSaveAndNext"
  >
    <template #body>
      <OnboardingHeader
        :title="t('CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.TITLE')"
        icon="i-lucide-settings-2"
        :subtitle="
          t('CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.SUBTITLE', {
            assistantName: 'Support Genie',
          })
        "
        :description="
          t('CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.DESCRIPTION', {
            assistantName: 'Support Genie',
            productName: 'The Cat Cafe',
          })
        "
      >
        <div class="w-[12.5rem] h-[9.75rem] flex-shrink-0">
          <SettingsSVG class="w-full h-full" />
        </div>
      </OnboardingHeader>

      <div class="pt-8 flex flex-col items-start gap-8 w-full">
        <div class="flex flex-col gap-6 mt-4 w-full">
          <div class="flex flex-col items-start gap-2">
            <label class="text-base font-medium text-n-slate-12 py-1">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.RESPONSE_TEMPERATURE.TITLE'
                )
              }}
            </label>
            <p class="text-sm text-n-slate-11 mb-0">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.RESPONSE_TEMPERATURE.DESCRIPTION'
                )
              }}
            </p>
          </div>
          <div class="flex flex-col items-start gap-3 w-full">
            <div
              class="flex items-center bg-n-solid-1 py-3 ltr:pl-4 w-full rtl:pr-4 ltr:pr-3 rtl:pl-3 rounded-xl gap-3 outline outline-1 outline-n-weak"
            >
              <input
                v-model="state.temperature"
                type="range"
                min="0"
                max="1"
                step="0.1"
                class="w-full"
              />
              <div
                class="bg-n-alpha-3 rounded-lg w-9 h-8 flex items-center justify-center outline outline-1 outline-n-weak"
              >
                <span class="text-xs font-semibold text-n-slate-12">
                  {{ state.temperature }}
                </span>
              </div>
            </div>
            <p class="text-sm text-n-slate-11 mb-0">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.RESPONSE_TEMPERATURE.HELP'
                )
              }}
            </p>
          </div>
        </div>
        <div class="flex flex-col gap-6 mt-4 w-full">
          <div class="flex flex-col items-start gap-2">
            <label class="text-base font-medium text-n-slate-12 py-1">
              {{
                t('CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.FEATURES.TITLE')
              }}
            </label>
            <p class="text-sm text-n-slate-11 mb-0">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.FEATURES.DESCRIPTION'
                )
              }}
            </p>
          </div>
          <div
            class="flex flex-col items-start bg-n-solid-1 w-full rounded-xl outline outline-1 outline-n-weak divide-y divide-n-weak"
          >
            <div class="p-4 flex items-center gap-2 w-full justify-between">
              <label>
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.FEATURES.OPTIONS.ALLOW_CONVERSATION_FAQS'
                  )
                }}
              </label>
              <Switch v-model="state.features.conversationFaqs" />
            </div>
            <div class="p-4 flex items-center gap-2 w-full justify-between">
              <label>
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.ONBOARDING.BASE_SETTINGS.FEATURES.OPTIONS.ALLOW_MEMORIES'
                  )
                }}
              </label>
              <Switch v-model="state.features.memories" />
            </div>
          </div>
        </div>
      </div>
    </template>
  </SettingsPageLayout>
</template>
