<script setup>
import { ref, computed, toRef } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useFunctionGetter, useStore } from 'dashboard/composables/store';
import {
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  findComponentByType,
} from 'dashboard/helper/templateHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import { isSendableTemplate } from '@chatwoot/utils';

const props = defineProps({
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSelect']);

const TEMPLATE_CLASSIFICATIONS = ['sendable', 'preview_only', 'unsupported'];

const { t } = useI18n();
const store = useStore();
const query = ref('');
const isRefreshing = ref(false);

const whatsAppTemplateMessages = useFunctionGetter(
  'inboxes/getVisibleWhatsAppTemplates',
  toRef(props, 'inboxId')
);
const inbox = useFunctionGetter('inboxes/getInbox', toRef(props, 'inboxId'));

const isCloudProvider = computed(
  () => inbox.value?.provider === 'whatsapp_cloud'
);

const filteredTemplateMessages = computed(() =>
  whatsAppTemplateMessages.value.filter(template =>
    template.name.toLowerCase().includes(query.value.toLowerCase())
  )
);

const getTemplateBody = template => {
  return findComponentByType(template, COMPONENT_TYPES.BODY)?.text || '';
};

const getTemplateHeader = template => {
  return findComponentByType(template, COMPONENT_TYPES.HEADER);
};

const getTemplateFooter = template => {
  return findComponentByType(template, COMPONENT_TYPES.FOOTER);
};

const getTemplateButtons = template => {
  return findComponentByType(template, COMPONENT_TYPES.BUTTONS);
};

const hasMediaContent = template => {
  const header = getTemplateHeader(template);
  return header && MEDIA_FORMATS.includes(header.format);
};

const getTemplateClassification = template => {
  return TEMPLATE_CLASSIFICATIONS.includes(template.classification)
    ? template.classification
    : 'unavailable';
};

const getClassificationLabel = template => {
  switch (getTemplateClassification(template)) {
    case 'sendable':
      return t('WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.SENDABLE');
    case 'preview_only':
      return t('WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.PREVIEW_ONLY');
    case 'unsupported':
      return t('WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.UNSUPPORTED');
    default:
      return t('WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.UNAVAILABLE');
  }
};

const isTemplateSendable = template => {
  if (isCloudProvider.value) {
    return template.classification === 'sendable';
  }

  return isSendableTemplate(template);
};

const getClassificationReason = template => {
  if (isTemplateSendable(template)) return '';

  switch (template.classification_reason) {
    case 'parameter_adapter_unavailable':
      return t(
        'WHATSAPP_TEMPLATES.PICKER.REASONS.PARAMETER_ADAPTER_UNAVAILABLE'
      );
    case 'unsupported_by_linoo_version':
      return t(
        'WHATSAPP_TEMPLATES.PICKER.REASONS.UNSUPPORTED_BY_LINOO_VERSION'
      );
    case 'template_not_approved':
      return t('WHATSAPP_TEMPLATES.PICKER.REASONS.TEMPLATE_NOT_APPROVED');
    default:
      return t('WHATSAPP_TEMPLATES.PICKER.REASONS.CLASSIFICATION_UNAVAILABLE');
  }
};

const selectTemplate = template => {
  if (isTemplateSendable(template)) {
    emit('onSelect', template);
  }
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', props.inboxId);
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_ERROR'));
  } finally {
    isRefreshing.value = false;
  }
};
</script>

<template>
  <div class="w-full">
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
        />
      </div>
      <button
        :disabled="isRefreshing"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed"
        :title="t('WHATSAPP_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-n-slate-12 size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
      </button>
    </div>
    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          data-testid="template-row"
          class="block p-2.5 w-full text-left rounded-lg enabled:cursor-pointer enabled:hover:bg-n-alpha-2 dark:enabled:hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-70"
          :disabled="!isTemplateSendable(template)"
          @click="selectTemplate(template)"
        >
          <div>
            <div class="flex justify-between items-center mb-2.5">
              <p class="text-sm">
                {{ template.name }}
              </p>
              <div class="flex gap-1.5 items-center">
                <span
                  v-if="isCloudProvider"
                  data-testid="template-classification"
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
                >
                  {{ getClassificationLabel(template) }}
                </span>
                <span
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
                >
                  {{
                    t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE_VALUE', {
                      language: template.language,
                    })
                  }}
                </span>
              </div>
            </div>
            <p
              v-if="getClassificationReason(template)"
              data-testid="template-classification-reason"
              class="mb-2.5 text-xs text-n-slate-11"
            >
              {{ getClassificationReason(template) }}
            </p>
            <!-- Header -->
            <div v-if="getTemplateHeader(template)" class="mb-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.HEADER') || 'HEADER' }}
              </p>
              <div
                v-if="getTemplateHeader(template).format === 'TEXT'"
                class="text-sm label-body"
              >
                {{ getTemplateHeader(template).text }}
              </div>
              <div
                v-else-if="hasMediaContent(template)"
                class="text-sm italic text-n-slate-11"
              >
                {{
                  t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT', {
                    format: getTemplateHeader(template).format,
                  }) ||
                  `${getTemplateHeader(template).format} ${t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT_FALLBACK')}`
                }}
              </div>
            </div>

            <!-- Body -->
            <div>
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.BODY') || 'BODY' }}
              </p>
              <p class="text-sm label-body">{{ getTemplateBody(template) }}</p>
            </div>

            <!-- Footer -->
            <div v-if="getTemplateFooter(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.FOOTER') || 'FOOTER' }}
              </p>
              <p class="text-sm label-body">
                {{ getTemplateFooter(template).text }}
              </p>
            </div>

            <!-- Buttons -->
            <div v-if="getTemplateButtons(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.BUTTONS') || 'BUTTONS' }}
              </p>
              <div class="flex flex-wrap gap-1 mt-1">
                <span
                  v-for="button in getTemplateButtons(template).buttons"
                  :key="button.text"
                  class="px-2 py-1 text-xs rounded bg-n-slate-3 text-n-slate-12"
                >
                  {{ button.text }}
                </span>
              </div>
            </div>

            <div class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.CATEGORY') || 'CATEGORY' }}
              </p>
              <p class="text-sm">{{ template.category }}</p>
            </div>
          </div>
        </button>
        <hr
          v-if="i != filteredTemplateMessages.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredTemplateMessages.length" class="py-8 text-center">
        <div v-if="query && whatsAppTemplateMessages.length">
          <p>
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <div v-else-if="!whatsAppTemplateMessages.length" class="space-y-4">
          <p class="text-n-slate-11">
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
