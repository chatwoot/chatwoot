<script setup>
import { ref, computed, watch, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import TemplatePreview from 'dashboard/components-next/Templates/TemplateBuilder/TemplatePreview.vue';
import VariableInput from './VariableInput.vue';

import {
  mapTemplateToPreviewProps,
  buildInitialVariableValues,
  templateHasVariables,
  getHeaderMediaType,
  extractPlaceholderKeys,
  findComponentByType,
} from 'dashboard/components-next/whatsapp/templatePreviewMapper';
import { validateMediaUrlWithMessages } from 'dashboard/components-next/whatsapp/mediaUrlValidator';

const emit = defineEmits(['close']);

const { t, locale } = useI18n();
const store = useStore();

// Store getters
const uiFlags = useMapGetter('campaigns/getUIFlags');
const labels = useMapGetter('labels/getLabels');
const inboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const getFilteredWhatsAppTemplates = useMapGetter(
  'inboxes/getFilteredWhatsAppTemplates'
);

// Dialog ref
const dialogRef = ref(null);
const scheduledAtInput = ref(null);

// Form state
const formState = reactive({
  title: '',
  inboxId: null,
  templateId: null,
  scheduledAt: null,
  selectedAudience: [],
});

// Variable values (body, header, buttons)
const variableValues = ref({});

// Media validation state
const mediaValidation = reactive({
  isValidating: false,
  isValid: true,
  error: null,
});

// Validation rules
const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  templateId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, formState);

// Computed
const isCreating = computed(() => uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const audienceOptions = computed(() =>
  labels.value?.map(label => ({
    value: label.id,
    label: label.title,
  })) ?? []
);

const inboxOptions = computed(() =>
  inboxes.value?.map(inbox => ({
    value: inbox.id,
    label: inbox.name,
  })) ?? []
);

const templateOptions = computed(() => {
  if (!formState.inboxId) return [];
  const templates = getFilteredWhatsAppTemplates.value(formState.inboxId);
  return templates.map(template => {
    const friendlyName = template.name
      .replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());
    return {
      value: template.id,
      label: `${friendlyName} (${template.language || 'en'})`,
      template,
    };
  });
});

const selectedTemplate = computed(() => {
  if (!formState.templateId) return null;
  return templateOptions.value.find(opt => opt.value === formState.templateId)
    ?.template;
});

const hasVariables = computed(() =>
  templateHasVariables(selectedTemplate.value)
);

const headerMediaType = computed(() =>
  getHeaderMediaType(selectedTemplate.value)
);

const bodyPlaceholderKeys = computed(() => {
  if (!selectedTemplate.value) return [];
  const bodyComponent = findComponentByType(selectedTemplate.value, 'BODY');
  return extractPlaceholderKeys(bodyComponent?.text || '');
});

// Preview props
const previewProps = computed(() =>
  mapTemplateToPreviewProps(selectedTemplate.value, variableValues.value)
);

// Form errors
const formErrors = computed(() => ({
  title: v$.value.title.$error
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.ERROR')
    : '',
  inbox: v$.value.inboxId.$error
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.ERROR')
    : '',
  template: v$.value.templateId.$error
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.ERROR')
    : '',
  scheduledAt: v$.value.scheduledAt.$error
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.ERROR')
    : '',
  audience: v$.value.selectedAudience.$error
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.ERROR')
    : '',
}));

// Check if all required variables are filled
const allVariablesFilled = computed(() => {
  if (!hasVariables.value) return true;

  // Check header media URL
  if (headerMediaType.value) {
    if (!variableValues.value.header?.media_url?.trim()) {
      return false;
    }
  }

  // Check body variables
  if (bodyPlaceholderKeys.value.length > 0) {
    const hasEmptyBodyVar = bodyPlaceholderKeys.value.some(
      key => !variableValues.value.body?.[key]?.trim()
    );
    if (hasEmptyBodyVar) {
      return false;
    }
  }

  // Check button variables
  if (variableValues.value.buttons) {
    const hasEmptyButtonParam = variableValues.value.buttons.some(
      btn => btn && !btn.parameter?.trim()
    );
    if (hasEmptyButtonParam) {
      return false;
    }
  }

  return true;
});

// Validation errors list for display
const validationErrors = computed(() => {
  const errors = [];

  if (v$.value.title.$error) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.TITLE_REQUIRED'));
  }
  if (v$.value.inboxId.$error) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.INBOX_REQUIRED'));
  }
  if (v$.value.templateId.$error) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.TEMPLATE_REQUIRED'));
  }
  if (v$.value.scheduledAt.$error) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.SCHEDULED_REQUIRED'));
  }
  if (v$.value.selectedAudience.$error) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.AUDIENCE_REQUIRED'));
  }
  if (!allVariablesFilled.value) {
    errors.push(t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.ERRORS.VARIABLES_REQUIRED'));
  }
  if (mediaValidation.error) {
    errors.push(mediaValidation.error);
  }

  return errors;
});

const isSubmitDisabled = computed(() => {
  return (
    v$.value.$invalid ||
    !allVariablesFilled.value ||
    !mediaValidation.isValid ||
    mediaValidation.isValidating
  );
});

// Initialize variable values when template changes
watch(selectedTemplate, newTemplate => {
  if (newTemplate) {
    variableValues.value = buildInitialVariableValues(newTemplate);
    // Reset media validation
    mediaValidation.isValid = true;
    mediaValidation.error = null;
  } else {
    variableValues.value = {};
  }
});

// Reset template when inbox changes
watch(
  () => formState.inboxId,
  () => {
    formState.templateId = null;
  }
);

// Validate media URL when it changes
watch(
  () => variableValues.value.header?.media_url,
  async newUrl => {
    if (!headerMediaType.value || !newUrl?.trim()) {
      mediaValidation.isValid = !headerMediaType.value;
      mediaValidation.error = null;
      return;
    }

        mediaValidation.isValidating = true;
        try {
          const userLocale = locale.value === 'pt_BR' ? 'pt_BR' : 'en';
          const result = await validateMediaUrlWithMessages(
            newUrl,
            headerMediaType.value,
            userLocale
          );
          mediaValidation.isValid = result.isValid;
          mediaValidation.error = result.error || null;
        } finally {
          mediaValidation.isValidating = false;
        }
  },
  { debounce: 500 }
);

// Methods
const updateBodyVariable = (key, value) => {
  if (!variableValues.value.body) {
    variableValues.value.body = {};
  }
  variableValues.value.body[key] = value;
};

const updateHeaderMediaUrl = value => {
  if (!variableValues.value.header) {
    variableValues.value.header = {};
  }
  variableValues.value.header.media_url = value;
};

const updateHeaderMediaName = value => {
  if (!variableValues.value.header) {
    variableValues.value.header = {};
  }
  variableValues.value.header.media_name = value;
};

const updateButtonVariable = (index, value) => {
  if (!variableValues.value.buttons) {
    variableValues.value.buttons = [];
  }
  if (!variableValues.value.buttons[index]) {
    variableValues.value.buttons[index] = { type: 'url', parameter: '' };
  }
  variableValues.value.buttons[index].parameter = value;
};

// Handle scheduled at change - blur to close calendar picker
const handleScheduledAtChange = () => {
  // Blur the input to close the native date picker
  if (scheduledAtInput.value?.$el) {
    const input = scheduledAtInput.value.$el.querySelector('input');
    if (input) {
      input.blur();
    }
  }
};

// Format placeholder key for display (e.g., "1" -> "{{1}}")
const formatPlaceholder = key => {
  return `\u007B\u007B${key}\u007D\u007D`;
};

const getRenderedBodyText = () => {
  if (!selectedTemplate.value) return '';
  const bodyComponent = findComponentByType(selectedTemplate.value, 'BODY');
  let text = bodyComponent?.text || '';

  // Replace placeholders with values
  bodyPlaceholderKeys.value.forEach(key => {
    const value = variableValues.value.body?.[key] || `{{${key}}}`;
    text = text.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value);
  });

  return text;
};

const prepareCampaignPayload = () => {
  const template = selectedTemplate.value;

  return {
    title: formState.title,
    message: getRenderedBodyText(),
    template_params: {
      name: template?.name || '',
      namespace: template?.namespace || '',
      category: template?.category || 'UTILITY',
      language: template?.language || 'en_US',
      processed_params: variableValues.value,
    },
    inbox_id: formState.inboxId,
    scheduled_at: formState.scheduledAt
      ? new Date(formState.scheduledAt).toISOString()
      : null,
    audience: formState.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid || !allVariablesFilled.value || !mediaValidation.isValid) {
    return;
  }

  try {
    const payload = prepareCampaignPayload();
    await store.dispatch('campaigns/create', payload);

    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });

    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.SUCCESS_MESSAGE'));
    dialogRef.value?.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

// Called when Dialog emits 'close' (from clicking outside, pressing Escape, or Cancel button)
const onDialogClose = () => {
  // Reset form state
  formState.title = '';
  formState.inboxId = null;
  formState.templateId = null;
  formState.scheduledAt = null;
  formState.selectedAudience = [];
  variableValues.value = {};
  v$.value.$reset();
  emit('close');
};

// Called when Cancel button is clicked - closes the dialog which triggers onDialogClose
const handleCancel = () => {
  dialogRef.value?.close();
};

const openDialog = () => {
  dialogRef.value?.open();
};

defineExpose({ openDialog });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="5xl"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="onDialogClose"
  >
    <div class="flex flex-col -mx-6 -my-6 max-h-[85vh]">
      <!-- Header -->
      <div class="flex-shrink-0 px-6 py-4 border-b border-n-weak">
        <h2 class="text-lg font-medium text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.SUBTITLE') }}
        </p>
      </div>

      <!-- Content -->
      <div class="flex-1 flex gap-6 p-6 overflow-hidden min-h-0">
        <!-- Form Panel -->
        <div class="flex-1 min-w-0 overflow-y-auto pr-4 space-y-6">
          <!-- Basic Info Section -->
          <section
            class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container"
          >
            <div class="flex items-center gap-2 mb-4">
              <i class="i-lucide-settings-2 text-lg text-n-slate-11" />
              <h3
                class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide"
              >
                {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.SECTIONS.BASIC_INFO') }}
              </h3>
            </div>

            <div class="space-y-4">
              <!-- Campaign Title -->
              <Input
                v-model="formState.title"
                :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.LABEL')"
                :placeholder="
                  t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')
                "
                :message="formErrors.title"
                :message-type="formErrors.title ? 'error' : 'info'"
                required
              />

              <!-- Inbox Selection -->
              <div class="flex flex-col gap-1">
                <label
                  for="inbox"
                  class="mb-0.5 text-sm font-medium text-n-slate-12"
                >
                  {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.LABEL') }}
                  <span class="text-red-500 ml-0.5">{{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.REQUIRED_INDICATOR') }}</span>
                </label>
                <ComboBox
                  id="inbox"
                  v-model="formState.inboxId"
                  :options="inboxOptions"
                  :has-error="!!formErrors.inbox"
                  :placeholder="
                    t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER')
                  "
                  :message="formErrors.inbox"
                />
              </div>

              <!-- Template Selection -->
              <div class="flex flex-col gap-1">
                <label
                  for="template"
                  class="mb-0.5 text-sm font-medium text-n-slate-12"
                >
                  {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LABEL') }}
                  <span class="text-red-500 ml-0.5">{{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.REQUIRED_INDICATOR') }}</span>
                </label>
                <ComboBox
                  id="template"
                  v-model="formState.templateId"
                  :options="templateOptions"
                  :has-error="!!formErrors.template"
                  :placeholder="
                    t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.PLACEHOLDER')
                  "
                  :message="formErrors.template"
                  :disabled="!formState.inboxId"
                />
                <p class="mt-1 text-xs text-n-slate-11">
                  {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.INFO') }}
                </p>
              </div>
            </div>
          </section>

          <!-- Template Variables Section -->
          <section
            v-if="selectedTemplate && hasVariables"
            class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container"
          >
            <div class="flex items-center gap-2 mb-4">
              <i class="i-lucide-variable text-lg text-n-slate-11" />
              <h3
                class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide"
              >
                {{
                  t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.SECTIONS.TEMPLATE_PARAMS')
                }}
              </h3>
            </div>

            <div class="space-y-4">
              <!-- Header Media URL -->
              <div v-if="headerMediaType" class="space-y-3">
                <div
                  class="bg-blue-500/10 border border-blue-500/30 rounded-lg p-3"
                >
                  <p class="text-xs text-blue-600 dark:text-blue-400">
                    <i class="i-lucide-info inline-block mr-1" />
                    {{
                      t(
                        `CAMPAIGN.WHATSAPP.CREATE_DIALOG.MEDIA_INFO.${headerMediaType}`
                      )
                    }}
                  </p>
                </div>

                <Input
                  :model-value="variableValues.header?.media_url || ''"
                  :label="
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.MEDIA_URL_LABEL', {
                      type: headerMediaType.toLowerCase(),
                    })
                  "
                  type="url"
                  :placeholder="
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.MEDIA_URL_PLACEHOLDER')
                  "
                  :message="mediaValidation.error"
                  :message-type="mediaValidation.error ? 'error' : 'info'"
                  required
                  @update:model-value="updateHeaderMediaUrl"
                />

                <div v-if="mediaValidation.isValidating" class="flex items-center gap-2 text-xs text-n-slate-11">
                  <i class="i-lucide-loader-2 animate-spin" />
                  {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VALIDATING_MEDIA') }}
                </div>

                <!-- Document filename -->
                <Input
                  v-if="headerMediaType === 'DOCUMENT'"
                  :model-value="variableValues.header?.media_name || ''"
                  :label="
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.DOCUMENT_NAME_LABEL')
                  "
                  :placeholder="
                    t(
                      'CAMPAIGN.WHATSAPP.CREATE_DIALOG.DOCUMENT_NAME_PLACEHOLDER'
                    )
                  "
                  @update:model-value="updateHeaderMediaName"
                />
              </div>

              <!-- Body Variables -->
              <div
                v-if="bodyPlaceholderKeys.length > 0"
                class="space-y-3 pt-2"
                :class="{ 'border-t border-n-weak': headerMediaType }"
              >
                <label class="block text-sm font-medium text-n-slate-12">
                  {{
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.BODY_VARIABLES_LABEL')
                  }}
                </label>

                <div
                  v-for="key in bodyPlaceholderKeys"
                  :key="`body-${key}`"
                  class="flex items-start gap-3"
                >
                  <div
                    class="flex-shrink-0 w-14 h-9 rounded bg-woot-500/20 flex items-center justify-center"
                  >
                    <span
                      class="text-xs font-mono font-semibold text-woot-500"
                    >
                      {{ formatPlaceholder(key) }}
                    </span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <VariableInput
                      :model-value="variableValues.body?.[key] || ''"
                      :placeholder="
                        t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PLACEHOLDER', { index: key })
                      "
                      @update:model-value="value => updateBodyVariable(key, value)"
                    />
                  </div>
                </div>
              </div>

              <!-- Button Variables -->
              <div
                v-if="variableValues.buttons?.length"
                class="space-y-3 pt-2 border-t border-n-weak"
              >
                <label class="block text-sm font-medium text-n-slate-12">
                  {{
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.BUTTON_VARIABLES_LABEL')
                  }}
                </label>

                <div
                  v-for="(btn, index) in variableValues.buttons"
                  :key="`btn-${index}`"
                >
                  <div v-if="btn" class="flex items-center gap-3">
                    <div
                      class="flex-shrink-0 px-2 h-9 rounded bg-n-slate-3 flex items-center justify-center"
                    >
                      <span class="text-xs font-medium text-n-slate-11">
                        {{
                          t(
                            'CAMPAIGN.WHATSAPP.CREATE_DIALOG.BUTTON_INDEX',
                            { index: index + 1 }
                          )
                        }}
                      </span>
                    </div>
                    <Input
                      :model-value="btn.parameter || ''"
                      class="flex-1 min-w-0"
                      :placeholder="
                        t(
                          'CAMPAIGN.WHATSAPP.CREATE_DIALOG.BUTTON_PARAM_PLACEHOLDER'
                        )
                      "
                      @update:model-value="
                        value => updateButtonVariable(index, value)
                      "
                    />
                  </div>
                </div>
              </div>
            </div>
          </section>

          <!-- Audience & Schedule Section -->
          <section
            class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container"
          >
            <div class="flex items-center gap-2 mb-4">
              <i class="i-lucide-users text-lg text-n-slate-11" />
              <h3
                class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide"
              >
                {{
                  t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.SECTIONS.AUDIENCE_SCHEDULE')
                }}
              </h3>
            </div>

            <div class="space-y-4">
              <!-- Audience -->
              <div class="flex flex-col gap-1">
                <label
                  for="audience"
                  class="mb-0.5 text-sm font-medium text-n-slate-12"
                >
                  {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL') }}
                  <span class="text-red-500 ml-0.5">{{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.REQUIRED_INDICATOR') }}</span>
                </label>
                <TagMultiSelectComboBox
                  v-model="formState.selectedAudience"
                  :options="audienceOptions"
                  :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL')"
                  :placeholder="
                    t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PLACEHOLDER')
                  "
                  :has-error="!!formErrors.audience"
                  :message="formErrors.audience"
                />
              </div>

              <!-- Scheduled At -->
              <Input
                ref="scheduledAtInput"
                v-model="formState.scheduledAt"
                :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.LABEL')"
                type="datetime-local"
                :min="currentDateTime"
                :placeholder="
                  t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')
                "
                :message="formErrors.scheduledAt"
                :message-type="formErrors.scheduledAt ? 'error' : 'info'"
                required
                @change="handleScheduledAtChange"
              />
            </div>
          </section>

          <!-- Validation Errors -->
          <div
            v-if="validationErrors.length > 0 && v$.$dirty"
            class="bg-red-500/10 border border-red-500/30 rounded-xl p-4"
          >
            <div class="flex items-start gap-3">
              <i
                class="i-lucide-alert-circle text-lg text-red-500 flex-shrink-0 mt-0.5"
              />
              <div>
                <p class="text-sm font-medium text-red-500 mb-2">
                  {{
                    t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VALIDATION_ERRORS_TITLE')
                  }}
                </p>
                <ul class="space-y-1">
                  <li
                    v-for="(error, index) in validationErrors"
                    :key="index"
                    class="text-sm text-red-400 flex items-start gap-2"
                  >
                    <span class="text-red-500/50">{{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.BULLET_POINT') }}</span>
                    <span>{{ error }}</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- Preview Panel -->
        <div class="w-[360px] flex-shrink-0 overflow-y-auto">
          <div>
            <div class="flex items-center gap-2 mb-4">
              <i class="i-lucide-smartphone text-lg text-n-slate-11" />
              <h3
                class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide"
              >
                {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.PREVIEW_TITLE') }}
              </h3>
            </div>
            <TemplatePreview
              :header-format="previewProps.headerFormat"
              :header-text="previewProps.headerText"
              :header-text-example="previewProps.headerTextExample"
              :header-media-url="previewProps.headerMediaUrl"
              :header-media-name="previewProps.headerMediaName"
              :body-text="previewProps.bodyText"
              :body-examples="previewProps.bodyExamples"
              :footer-text="previewProps.footerText"
              :buttons="previewProps.buttons"
            />
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="flex-shrink-0 flex justify-end gap-3 px-6 py-4 border-t border-n-weak"
      >
        <Button
          variant="faded"
          color="slate"
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL')"
          @click="handleCancel"
        />
        <Button
          :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE')"
          :is-loading="isCreating"
          :disabled="isSubmitDisabled"
          @click="handleSubmit"
        />
      </div>
    </div>
  </Dialog>
</template>

