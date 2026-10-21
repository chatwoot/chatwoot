<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import {
  TRANSLATION_PROVIDERS,
  translationProvider,
} from 'dashboard/helper/translationProvider';
import NewHook from './NewHook.vue';
import SingleIntegrationHooks from './SingleIntegrationHooks.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const INTEGRATION_ID = 'google_translate';
const SETUP_STEPS = [
  {
    key: 'ENABLE_API',
    link: 'https://console.cloud.google.com/apis/library/translate.googleapis.com',
  },
  {
    key: 'CREATE_KEY',
    link: 'https://console.cloud.google.com/iam-admin/serviceaccounts',
  },
  { key: 'CONNECT' },
];

const { t } = useI18n();
const store = useStore();

const integration = useFunctionGetter(
  'integrations/getIntegration',
  INTEGRATION_ID
);
const uiFlags = useMapGetter('integrations/getUIFlags');
const { currentAccount } = useAccount();

const { isAvailable: showTranslationService } = useTranslationPlan();
const isGoogleSelected = computed(
  () =>
    translationProvider(currentAccount.value?.settings) ===
    TRANSLATION_PROVIDERS.GOOGLE
);

const showAddHookModal = ref(false);
const showDeleteModal = ref(false);
const hookToDelete = ref(null);

const hook = computed(() => integration.value.hooks?.[0]);
const isLoaded = computed(() => !!integration.value.id);

const openDeleteModal = selectedHook => {
  hookToDelete.value = selectedHook;
  showDeleteModal.value = true;
};

const deleteHook = async () => {
  try {
    await store.dispatch('integrations/deleteHook', {
      hookId: hookToDelete.value.id,
      appId: INTEGRATION_ID,
    });
    useAlert(t('INTEGRATION_APPS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('INTEGRATION_APPS.DELETE.API.ERROR_MESSAGE')
    );
  } finally {
    showDeleteModal.value = false;
  }
};

onMounted(() => store.dispatch('integrations/get', INTEGRATION_ID));
</script>

<template>
  <SettingsLayout :is-loading="uiFlags.isFetching && !isLoaded">
    <template #header>
      <BaseSettingsHeader
        :title="t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.HEADER')"
        description=""
        :feature-name="INTEGRATION_ID"
        :back-button-label="t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div v-if="isLoaded" class="flex flex-col gap-5">
        <SingleIntegrationHooks
          :integration-id="INTEGRATION_ID"
          @add="showAddHookModal = true"
          @delete="openDeleteModal"
        />

        <div
          v-if="hook"
          class="flex flex-col rounded-xl divide-y outline outline-1 outline-n-container bg-n-card divide-n-weak"
        >
          <div class="flex gap-4 justify-between items-center px-6 py-4">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DETAILS.PROJECT') }}
            </span>
            <span class="font-mono truncate text-body-main text-n-slate-12">
              {{ hook.settings?.project_id }}
            </span>
          </div>
          <div
            v-if="showTranslationService"
            class="flex gap-4 justify-between items-center px-6 py-4"
          >
            <div class="flex flex-col gap-0.5 min-w-0">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DETAILS.SERVICE') }}
              </span>
              <span class="text-body-main text-n-slate-11">
                {{
                  isGoogleSelected
                    ? t(
                        'INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DETAILS.SERVICE_GOOGLE'
                      )
                    : t(
                        'INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DETAILS.SERVICE_OTHER'
                      )
                }}
              </span>
            </div>
            <router-link
              :to="{ name: 'conversation_workflow_index' }"
              class="flex-shrink-0 text-body-main text-n-blue-11 hover:underline"
            >
              {{ t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DETAILS.CHANGE') }}
            </router-link>
          </div>
        </div>

        <div
          v-else
          class="flex flex-col gap-5 px-6 py-5 rounded-xl outline outline-1 outline-n-container bg-n-card"
        >
          <div class="flex flex-col gap-1">
            <h3 class="text-heading-2 text-n-slate-12">
              {{ t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.SETUP.TITLE') }}
            </h3>
            <p class="mb-0 text-body-main text-n-slate-11">
              {{ t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.SETUP.DESCRIPTION') }}
            </p>
          </div>
          <ol class="flex flex-col gap-4 m-0 list-none">
            <li
              v-for="(step, index) in SETUP_STEPS"
              :key="step.key"
              class="flex gap-3 items-start"
            >
              <span
                class="flex flex-shrink-0 justify-center items-center rounded-full size-6 bg-n-alpha-2 text-label-small text-n-slate-12"
              >
                {{ index + 1 }}
              </span>
              <div class="flex flex-col gap-1">
                <span class="text-heading-3 text-n-slate-12">
                  {{
                    t(
                      `INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.SETUP.STEPS.${step.key}.TITLE`
                    )
                  }}
                </span>
                <span class="text-body-main text-n-slate-11">
                  {{
                    t(
                      `INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.SETUP.STEPS.${step.key}.DESCRIPTION`
                    )
                  }}
                </span>
                <a
                  v-if="step.link"
                  :href="step.link"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex gap-1 items-center self-start text-body-main text-n-blue-11 hover:underline"
                >
                  {{
                    t(
                      `INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.SETUP.STEPS.${step.key}.LINK`
                    )
                  }}
                  <span class="i-lucide-external-link size-3.5" />
                </a>
              </div>
            </li>
          </ol>
        </div>
      </div>
    </template>
    <woot-modal
      v-model:show="showAddHookModal"
      :on-close="() => (showAddHookModal = false)"
    >
      <NewHook
        :integration-id="INTEGRATION_ID"
        @close="showAddHookModal = false"
      />
    </woot-modal>
    <woot-delete-modal
      v-model:show="showDeleteModal"
      :on-close="() => (showDeleteModal = false)"
      :on-confirm="deleteHook"
      :title="t('INTEGRATION_APPS.DELETE.TITLE.ACCOUNT')"
      :message="t('INTEGRATION_SETTINGS.GOOGLE_TRANSLATE.DELETE_MESSAGE')"
      :confirm-text="t('INTEGRATION_APPS.DELETE.CONFIRM_BUTTON_TEXT.ACCOUNT')"
      :reject-text="t('INTEGRATION_APPS.DELETE.CANCEL_BUTTON_TEXT')"
    />
  </SettingsLayout>
</template>
