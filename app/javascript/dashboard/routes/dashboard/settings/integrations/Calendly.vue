<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import calendlyAPI from 'dashboard/api/integrations/calendly';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'next/button/Button.vue';

const store = useStore();
const { t: $t } = useI18n();

const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const hasWhatsAppInboxes = ref(false);

const formState = reactive({
  booked: '',
  rescheduled: '',
  canceled: '',
});

const integration = useFunctionGetter(
  'integrations/getIntegration',
  'calendly'
);

const uiFlags = useMapGetter('integrations/getUIFlags');

const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');

const approvedTemplates = computed(() => {
  const templates = [];
  const seen = new Set();
  (whatsAppInboxes.value || []).forEach(inbox => {
    (inbox.message_templates || []).forEach(tpl => {
      if (tpl.status?.toLowerCase() === 'approved' && !seen.has(tpl.name)) {
        seen.add(tpl.name);
        templates.push(tpl);
      }
    });
  });
  return templates;
});

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const showTemplateSection = computed(
  () =>
    integration.value.enabled &&
    hasWhatsAppInboxes.value &&
    integrationLoaded.value
);

const loadCurrentSettings = async () => {
  try {
    const hook = integration.value.hooks?.[0];
    if (!hook?.settings?.calendly_templates) return;

    const templates = hook.settings.calendly_templates;
    formState.booked = templates.booked || '';
    formState.rescheduled = templates.rescheduled || '';
    formState.canceled = templates.canceled || '';
  } catch {
    // Settings not configured yet
  }
};

const initializeCalendlyIntegration = async () => {
  await store.dispatch('integrations/get', 'calendly');
  await store.dispatch('inboxes/get');
  hasWhatsAppInboxes.value = (whatsAppInboxes.value || []).length > 0;
  await loadCurrentSettings();
  integrationLoaded.value = true;
};

const handleSubmit = async () => {
  isSubmitting.value = true;
  try {
    await calendlyAPI.updateSettings({
      calendly_templates: {
        booked: formState.booked || null,
        rescheduled: formState.rescheduled || null,
        canceled: formState.canceled || null,
      },
    });
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_SUCCESS'));
  } catch {
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {
  initializeCalendlyIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div v-if="integrationLoaded && !uiFlags.isDeleting">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.CALENDLY.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.CALENDLY.DELETE.MESSAGE'),
        }"
      />

      <div v-if="showTemplateSection" class="mt-6">
        <SectionLayout
          :title="$t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.TITLE')"
          :description="
            $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.DESCRIPTION')
          "
        >
          <div
            class="mb-4 rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-700"
          >
            <p>
              {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.HELP_TEXT') }}
            </p>
            <ul class="mt-2 list-disc pl-5 space-y-1">
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_NAME') }}
              </li>
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_EVENT') }}
              </li>
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_TIME') }}
              </li>
            </ul>
          </div>

          <form class="grid gap-5" @submit.prevent="handleSubmit">
            <WithLabel
              name="bookedTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.BOOKED_LABEL')
              "
            >
              <select
                v-model="formState.booked"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <WithLabel
              name="rescheduledTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.RESCHEDULED_LABEL')
              "
            >
              <select
                v-model="formState.rescheduled"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <WithLabel
              name="canceledTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.CANCELED_LABEL')
              "
            >
              <select
                v-model="formState.canceled"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <div class="flex gap-2">
              <NextButton
                blue
                type="submit"
                :is-loading="isSubmitting"
                :label="
                  $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_BUTTON')
                "
              />
            </div>
          </form>
        </SectionLayout>
      </div>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
