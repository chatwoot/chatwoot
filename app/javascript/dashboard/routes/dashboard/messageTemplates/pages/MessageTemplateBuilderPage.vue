<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter, onBeforeRouteLeave } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { vOnClickOutside } from '@vueuse/components';
import HeaderSection from '../components/HeaderSection.vue';
import BodySection from '../components/BodySection.vue';
import FooterSection from '../components/FooterSection.vue';
import ButtonsSection from '../components/ButtonsSection.vue';
import TemplatePreview from '../components/TemplatePreview.vue';
import {
  generateTemplateComponents,
  validateTemplateData,
} from 'dashboard/helper/templateHelper';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();

// ── Edit mode detection ─────────────────────────────────────────────
const isEditMode = computed(() => !!route.params.templateId);
const templateId = computed(() => route.params.templateId);
const isLoading = ref(false);

// Form metadata
const templateName = ref('');
const selectedCategory = ref('marketing');
const selectedLanguage = ref('en');
const selectedInboxId = ref('');
const parameterType = ref('positional');
const showParamDropdown = ref(false);
const isSubmitting = ref(false);
const isDirty = ref(false);
const hasAttemptedSubmit = ref(false);

// Unsaved changes guard
onBeforeRouteLeave((_to, _from, next) => {
  if (isDirty.value && !isSubmitting.value) {
    // eslint-disable-next-line no-alert
    const leave = window.confirm(
      t('MESSAGE_TEMPLATES.BUILDER.UNSAVED_CHANGES')
    );
    next(leave);
  } else {
    next();
  }
});

function handleBeforeUnload(e) {
  if (isDirty.value) {
    e.preventDefault();
    e.returnValue = '';
  }
}

onMounted(() => window.addEventListener('beforeunload', handleBeforeUnload));
onBeforeUnmount(() =>
  window.removeEventListener('beforeunload', handleBeforeUnload)
);

// Template data (modular sections)
const templateData = ref({
  header: {
    enabled: false,
    type: 'HEADER',
    format: 'TEXT',
    text: '',
    example: {
      header_text: [],
      header_text_named_params: [],
    },
    media: {},
    error: '',
  },
  body: {
    type: 'BODY',
    text: '',
    example: {
      body_text: [],
      body_text_named_params: [],
    },
    error: '',
  },
  footer: {
    type: 'FOOTER',
    enabled: false,
    text: '',
  },
  buttons: [],
});

// Track dirty state on form changes
watch(
  [
    templateName,
    selectedCategory,
    selectedLanguage,
    selectedInboxId,
    templateData,
  ],
  () => {
    isDirty.value = true;
  },
  { deep: true }
);

// Available inboxes (WhatsApp only)
const inboxes = computed(() => {
  const allInboxes = getters['inboxes/getInboxes'].value || [];
  return allInboxes.filter(inbox => inbox.channel_type === 'Channel::Whatsapp');
});
const inboxOptions = computed(() =>
  inboxes.value.map(i => ({ value: i.id, label: i.name }))
);

const categories = [
  { value: 'marketing', label: 'MESSAGE_TEMPLATES.CATEGORIES.MARKETING' },
  { value: 'utility', label: 'MESSAGE_TEMPLATES.CATEGORIES.UTILITY' },
  {
    value: 'authentication',
    label: 'MESSAGE_TEMPLATES.CATEGORIES.AUTHENTICATION',
  },
];
const categoryOptions = computed(() =>
  categories.map(c => ({ value: c.value, label: t(c.label) }))
);

const languages = [
  { value: 'en', label: 'English' },
  { value: 'en_US', label: 'English (US)' },
  { value: 'pt_BR', label: 'Portuguese (BR)' },
  { value: 'es', label: 'Spanish' },
  { value: 'fr', label: 'French' },
  { value: 'de', label: 'German' },
  { value: 'it', label: 'Italian' },
  { value: 'ar', label: 'Arabic' },
  { value: 'hi', label: 'Hindi' },
  { value: 'ja', label: 'Japanese' },
  { value: 'ko', label: 'Korean' },
  { value: 'zh_CN', label: 'Chinese (Simplified)' },
  { value: 'zh_TW', label: 'Chinese (Traditional)' },
  { value: 'ru', label: 'Russian' },
  { value: 'tr', label: 'Turkish' },
  { value: 'nl', label: 'Dutch' },
  { value: 'id', label: 'Indonesian' },
  { value: 'ms', label: 'Malay' },
  { value: 'th', label: 'Thai' },
  { value: 'vi', label: 'Vietnamese' },
];

const parameterTypeOptions = [
  {
    label: t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.POSITIONAL'),
    description: t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.POSITIONAL_DESC'),
    value: 'positional',
    action: 'set-positional',
  },
  {
    label: t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.NAMED'),
    description: t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.NAMED_DESC'),
    value: 'named',
    action: 'set-named',
  },
];

// Validation
const isNameValid = computed(() => /^[a-z0-9_]+$/.test(templateName.value));
const isFormValid = computed(() => {
  return (
    templateName.value.length > 0 &&
    isNameValid.value &&
    selectedInboxId.value &&
    validateTemplateData(templateData.value)
  );
});

// Per-field validation hints (shown after first submit attempt)
const showNameError = computed(
  () => hasAttemptedSubmit.value && templateName.value.length === 0
);
const showInboxError = computed(
  () => hasAttemptedSubmit.value && !selectedInboxId.value
);

// Submit
const handleSubmit = async () => {
  hasAttemptedSubmit.value = true;
  if (!isFormValid.value || isSubmitting.value) return;
  isSubmitting.value = true;

  const components = generateTemplateComponents(
    templateData.value,
    parameterType.value
  );

  const payload = {
    message_template: {
      name: templateName.value,
      category: selectedCategory.value,
      language: selectedLanguage.value,
      channel_type: 'Channel::Whatsapp',
      inbox_id: selectedInboxId.value,
      content: { components },
    },
  };

  try {
    if (isEditMode.value) {
      await store.dispatch('messageTemplates/update', {
        id: templateId.value,
        ...payload,
      });
      useAlert(t('MESSAGE_TEMPLATES.BUILDER.UPDATE_SUCCESS'));
    } else {
      await store.dispatch('messageTemplates/create', payload);
      useAlert(t('MESSAGE_TEMPLATES.BUILDER.SUCCESS'));
    }
    isDirty.value = false;
    router.push({ name: 'message_templates_index' });
  } catch {
    useAlert(t('MESSAGE_TEMPLATES.BUILDER.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'message_templates_index' });
};

const handleParameterTypeAction = action => {
  if (action.action === 'set-positional') {
    parameterType.value = 'positional';
  } else if (action.action === 'set-named') {
    parameterType.value = 'named';
  }
  showParamDropdown.value = false;
};

// Auto-format name
watch(templateName, val => {
  templateName.value = val.toLowerCase().replace(/[^a-z0-9_]/g, '_');
});

// ── Load existing template for edit mode ────────────────────────────
function populateFromComponent(comp, section) {
  if (!comp) return;
  if (comp.type === 'HEADER') {
    section.header.enabled = true;
    section.header.format = comp.format || 'TEXT';
    section.header.text = comp.text || '';
    if (comp.example?.header_text) {
      section.header.example.header_text = comp.example.header_text;
    }
  } else if (comp.type === 'BODY') {
    section.body.text = comp.text || '';
    if (comp.example?.body_text) {
      section.body.example.body_text = comp.example.body_text;
    }
  } else if (comp.type === 'FOOTER') {
    section.footer.enabled = true;
    section.footer.text = comp.text || '';
  } else if (comp.type === 'BUTTONS') {
    section.buttons = (comp.buttons || []).map(btn => ({ ...btn }));
  }
}

async function loadExistingTemplate() {
  if (!isEditMode.value) return;

  isLoading.value = true;
  try {
    // Ensure templates are loaded
    if (!getters['messageTemplates/getMessageTemplates'].value.length) {
      await store.dispatch('messageTemplates/get');
    }

    const tmpl = getters['messageTemplates/getTemplateById'].value(
      templateId.value
    );
    if (!tmpl) {
      useAlert(t('MESSAGE_TEMPLATES.BUILDER.NOT_FOUND'));
      router.push({ name: 'message_templates_index' });
      return;
    }

    templateName.value = tmpl.name || '';
    selectedCategory.value = tmpl.category || 'marketing';
    selectedLanguage.value = tmpl.language || 'en';
    selectedInboxId.value = tmpl.inbox_id || '';

    // Populate sections from content.components
    const components = tmpl.content?.components || [];
    const data = JSON.parse(JSON.stringify(templateData.value));
    components.forEach(comp => populateFromComponent(comp, data));
    templateData.value = data;
  } finally {
    isLoading.value = false;
    isDirty.value = false;
  }
}

async function loadCloneSource() {
  const cloneFromId = route.query.cloneFrom;
  if (!cloneFromId) return;

  isLoading.value = true;
  try {
    if (!getters['messageTemplates/getMessageTemplates'].value.length) {
      await store.dispatch('messageTemplates/get');
    }

    const tmpl = getters['messageTemplates/getTemplateById'].value(cloneFromId);
    if (!tmpl) return;

    templateName.value = `${tmpl.name}_copy`;
    selectedCategory.value = tmpl.category || 'marketing';
    selectedLanguage.value = tmpl.language || 'en';
    selectedInboxId.value = tmpl.inbox_id || '';

    const components = tmpl.content?.components || [];
    const data = JSON.parse(JSON.stringify(templateData.value));
    components.forEach(comp => populateFromComponent(comp, data));
    templateData.value = data;
  } finally {
    isLoading.value = false;
    isDirty.value = false;
  }
}

onMounted(() => {
  if (isEditMode.value) {
    loadExistingTemplate();
  } else {
    loadCloneSource();
  }
});
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <!-- Header bar -->
    <header class="sticky top-0 z-10 px-6 border-b border-n-strong">
      <div class="w-full max-w-7xl mx-auto">
        <div class="flex items-center justify-between w-full h-16 gap-2">
          <div class="flex items-center gap-3">
            <Button
              icon="i-lucide-arrow-left"
              size="sm"
              variant="ghost"
              color-scheme="secondary"
              @click="goBack"
            />
            <div class="flex items-center gap-2 text-sm text-n-slate-11">
              <span
                class="cursor-pointer hover:text-n-slate-12"
                @click="goBack"
              >
                {{ t('MESSAGE_TEMPLATES.HEADER_TITLE') }}
              </span>
              <span class="i-lucide-chevron-right size-4" />
              <span class="text-n-slate-12 font-medium">
                {{
                  isEditMode
                    ? t('MESSAGE_TEMPLATES.BUILDER.EDIT_TITLE')
                    : t('MESSAGE_TEMPLATES.BUILDER.TITLE')
                }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <Button
              :label="t('MESSAGE_TEMPLATES.BUILDER.DISCARD')"
              variant="ghost"
              color="slate"
              size="sm"
              @click="goBack"
            />
            <Button
              :label="
                isEditMode
                  ? t('MESSAGE_TEMPLATES.BUILDER.UPDATE')
                  : t('MESSAGE_TEMPLATES.BUILDER.SUBMIT')
              "
              :icon="isEditMode ? 'i-lucide-save' : 'i-lucide-send'"
              size="sm"
              :disabled="!isFormValid"
              :is-loading="isSubmitting"
              @click="handleSubmit"
            />
          </div>
        </div>
      </div>
    </header>

    <main class="flex-1 overflow-y-auto px-6 py-6">
      <div
        class="w-full max-w-7xl mx-auto grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] xl:items-start"
      >
        <!-- Left: Builder form -->
        <div class="flex flex-col gap-6">
          <!-- Template metadata card -->
          <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
            <div class="flex items-center gap-3 mb-4">
              <span class="i-lucide-file-text size-5 text-n-slate-11" />
              <h4 class="font-medium text-n-slate-12">
                {{ t('MESSAGE_TEMPLATES.BUILDER.TEMPLATE_INFO') }}
              </h4>
            </div>

            <div class="space-y-4">
              <!-- Template name -->
              <div>
                <label class="block text-sm font-medium text-n-slate-12 mb-2">
                  {{ t('MESSAGE_TEMPLATES.BUILDER.NAME_LABEL') }}
                </label>
                <input
                  v-model="templateName"
                  type="text"
                  :placeholder="t('MESSAGE_TEMPLATES.BUILDER.NAME_PLACEHOLDER')"
                  :readonly="isEditMode"
                  class="w-full px-3 py-2 text-sm border rounded-lg border-n-strong bg-n-alpha-black2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
                  :class="{
                    'border-n-ruby-9': templateName.length > 0 && !isNameValid,
                    'opacity-60 cursor-not-allowed': isEditMode,
                  }"
                />
                <p
                  v-if="templateName.length > 0 && !isNameValid"
                  class="text-xs text-n-ruby-11 mt-1"
                >
                  {{ t('MESSAGE_TEMPLATES.BUILDER.NAME_HINT') }}
                </p>
                <p
                  v-else-if="showNameError"
                  class="text-xs text-n-ruby-11 mt-1"
                >
                  {{ t('MESSAGE_TEMPLATES.BUILDER.NAME_REQUIRED') }}
                </p>
              </div>

              <!-- Category + Language + Inbox row -->
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-2">
                    {{ t('MESSAGE_TEMPLATES.BUILDER.CATEGORY_LABEL') }}
                  </label>
                  <Select
                    v-model="selectedCategory"
                    :options="categoryOptions"
                    class="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-2">
                    {{ t('MESSAGE_TEMPLATES.BUILDER.LANGUAGE_LABEL') }}
                  </label>
                  <Select
                    v-model="selectedLanguage"
                    :options="languages"
                    class="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-2">
                    {{ t('MESSAGE_TEMPLATES.BUILDER.INBOX_LABEL') }}
                  </label>
                  <Select
                    v-model="selectedInboxId"
                    :options="inboxOptions"
                    :placeholder="
                      t('MESSAGE_TEMPLATES.BUILDER.INBOX_PLACEHOLDER')
                    "
                    class="w-full"
                  />
                  <p v-if="showInboxError" class="text-xs text-n-ruby-11 mt-1">
                    {{ t('MESSAGE_TEMPLATES.BUILDER.INBOX_REQUIRED') }}
                  </p>
                </div>
              </div>

              <!-- Parameter type selector -->
              <div>
                <label class="block text-sm font-medium text-n-slate-12 mb-2">
                  {{ t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.LABEL') }}
                </label>
                <div
                  v-on-click-outside="() => (showParamDropdown = false)"
                  class="relative inline-block"
                >
                  <Button
                    :label="
                      parameterType === 'positional'
                        ? t(
                            'MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.POSITIONAL'
                          )
                        : t('MESSAGE_TEMPLATES.BUILDER.PARAMETER_TYPE.NAMED')
                    "
                    :trailing-icon="
                      showParamDropdown
                        ? 'i-lucide-chevron-up'
                        : 'i-lucide-chevron-down'
                    "
                    variant="outline"
                    color="slate"
                    size="sm"
                    @click="showParamDropdown = !showParamDropdown"
                  />
                  <DropdownMenu
                    v-if="showParamDropdown"
                    :menu-items="parameterTypeOptions"
                    class="ltr:left-0 rtl:right-0 z-[100] top-full mt-1"
                    @action="handleParameterTypeAction"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Header section -->
          <HeaderSection
            v-model="templateData.header"
            :parameter-type="parameterType"
          />

          <!-- Body section -->
          <BodySection
            v-model="templateData.body"
            :parameter-type="parameterType"
          />

          <!-- Footer section -->
          <FooterSection v-model="templateData.footer" />

          <!-- Buttons section -->
          <ButtonsSection v-model="templateData.buttons" />
        </div>

        <!-- Right: Sticky Preview -->
        <div class="xl:sticky xl:top-[80px]">
          <TemplatePreview
            :template-data="templateData"
            :parameter-type="parameterType"
          />
        </div>
      </div>
    </main>
  </section>
</template>
