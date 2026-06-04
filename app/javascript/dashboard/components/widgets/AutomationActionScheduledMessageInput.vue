<script setup>
import { computed, ref, onBeforeMount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import FileUpload from 'vue-upload-component';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappTemplates from 'dashboard/components/widgets/conversation/WhatsappTemplates/Modal.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';
import { DEFAULT_SCHEDULED_MESSAGE_DELAY_MINUTES } from 'dashboard/routes/dashboard/settings/automation/constants.js';

const props = defineProps({
  modelValue: {
    type: [Object, Array],
    default: () => ({}),
  },
  initialFileName: {
    type: String,
    default: '',
  },
  conditions: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue']);

const MAX_DELAY_MINUTES = 999 * 24 * 60; // 999 days

const { t } = useI18n();
const store = useStore();

const showWhatsAppTemplatesModal = ref(false);

const normalizedParams = computed(() => {
  const value = props.modelValue;
  if (Array.isArray(value)) {
    const first = value[0];
    return typeof first === 'object' && first !== null ? first : {};
  }
  return typeof value === 'object' && value !== null ? value : {};
});

const updateParams = updates => {
  const newParams = { ...normalizedParams.value, ...updates };
  emit('update:modelValue', [newParams]);
};

const content = computed({
  get: () => {
    const value = normalizedParams.value.content;
    return typeof value === 'string' ? value : '';
  },
  set: value => updateParams({ content: value }),
});

const delayMinutes = computed({
  get: () =>
    normalizedParams.value.delay_minutes ??
    DEFAULT_SCHEDULED_MESSAGE_DELAY_MINUTES,
  set: value => {
    const numValue = Math.min(
      Math.max(1, Number(value) || 1),
      MAX_DELAY_MINUTES
    );
    updateParams({ delay_minutes: numValue });
  },
});

const delayUnit = ref(DURATION_UNITS.MINUTES);

const detectUnit = minutes => {
  const m = Number(minutes) || 0;
  if (m === 0) return DURATION_UNITS.DAYS;
  if (m % (24 * 60) === 0) return DURATION_UNITS.DAYS;
  if (m % 60 === 0) return DURATION_UNITS.HOURS;
  return DURATION_UNITS.MINUTES;
};

onBeforeMount(() => {
  // Normalize delay_minutes for existing automations with invalid/out-of-range values
  // For new actions, resetAction in useAutomation.js sets the default
  const rawDelay =
    normalizedParams.value.delay_minutes ??
    DEFAULT_SCHEDULED_MESSAGE_DELAY_MINUTES;
  const clampedDelay = Math.min(
    Math.max(1, Number(rawDelay) || 1),
    MAX_DELAY_MINUTES
  );

  // Only emit if the value needs normalization to avoid unnecessary updates
  if (clampedDelay !== normalizedParams.value.delay_minutes) {
    updateParams({ delay_minutes: clampedDelay });
  }

  delayUnit.value = detectUnit(clampedDelay);
});

// Attachment handling
const attachmentState = ref('idle'); // 'idle' | 'uploading' | 'uploaded' | 'failed'
const attachmentFileName = ref(props.initialFileName || '');

const hasAttachment = computed(() => {
  const blobId = normalizedParams.value.blob_id;
  return !!blobId;
});

const attachmentLabel = computed(() => {
  if (attachmentState.value === 'uploading') {
    return t('AUTOMATION.ATTACHMENT.LABEL_UPLOADING');
  }
  if (attachmentFileName.value) {
    return attachmentFileName.value;
  }
  return t('AUTOMATION.ATTACHMENT.LABEL_IDLE');
});

const onFileUpload = async file => {
  if (!file?.file) return;

  attachmentState.value = 'uploading';
  try {
    const id = await store.dispatch('automations/uploadAttachment', file.file);
    updateParams({ blob_id: id });
    attachmentState.value = 'uploaded';
    attachmentFileName.value = file.file.name;
  } catch {
    attachmentState.value = 'failed';
    useAlert(t('AUTOMATION.ATTACHMENT.UPLOAD_ERROR'));
  }
};

const clearAttachment = () => {
  updateParams({ blob_id: null });
  attachmentState.value = 'idle';
  attachmentFileName.value = '';
};

// Template params handling
const templateParams = computed(
  () => normalizedParams.value.template_params || null
);

const hasTemplate = computed(
  () => templateParams.value && Object.keys(templateParams.value).length > 0
);

const templateName = computed(() => {
  return templateParams.value?.name || templateParams.value?.id || null;
});

// Extract inbox IDs from conditions
const inboxIdsFromConditions = computed(() => {
  const inboxConditions = props.conditions.filter(
    condition => condition.attribute_key === 'inbox_id'
  );
  const ids = [];
  inboxConditions.forEach(condition => {
    const values = condition.values;
    if (Array.isArray(values)) {
      values.forEach(v => {
        const id = typeof v === 'object' ? v.id : v;
        if (id) ids.push(Number(id));
      });
    } else if (values) {
      const id = typeof values === 'object' ? values.id : values;
      if (id) ids.push(Number(id));
    }
  });
  return ids;
});

// Get the first inbox ID that has templates (for the modal)
const inboxIdForTemplates = computed(() => {
  const inboxWithTemplates = inboxIdsFromConditions.value.find(inboxId => {
    const templates =
      store.getters['inboxes/getWhatsAppTemplates'](inboxId) || [];
    return templates.length > 0;
  });
  return inboxWithTemplates ?? null;
});

// Check if any inbox has WhatsApp templates
const showWhatsappTemplates = computed(() => {
  return inboxIdForTemplates.value !== null;
});

// Show action buttons only when no attachment, no template, and not uploading
const isUploading = computed(() => attachmentState.value === 'uploading');
const showActionButtons = computed(
  () => !hasAttachment.value && !hasTemplate.value && !isUploading.value
);

const openWhatsAppTemplatesModal = () => {
  showWhatsAppTemplatesModal.value = true;
};

const hideWhatsAppTemplatesModal = () => {
  showWhatsAppTemplatesModal.value = false;
};

const onTemplateSelect = messagePayload => {
  updateParams({
    template_params: messagePayload.templateParams,
    content: messagePayload.message,
  });
  hideWhatsAppTemplatesModal();
};

const clearTemplate = () => {
  updateParams({
    template_params: null,
    content: '',
  });
};
</script>

<template>
  <div class="mt-2 flex flex-col gap-1">
    <div class="flex flex-col gap-1">
      <label class="text-xs text-n-slate-11">
        {{ $t('AUTOMATION.ACTION.SCHEDULED_MESSAGE_DELAY_LABEL') }}
      </label>
      <div class="flex items-center gap-2">
        <!-- allow 1 min to 999 days -->
        <DurationInput
          v-model:model-value="delayMinutes"
          v-model:unit="delayUnit"
          :min="1"
          :max="MAX_DELAY_MINUTES"
        />
      </div>
    </div>

    <WootMessageEditor
      v-model="content"
      rows="4"
      enable-variables
      :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
      class="action-message"
      :class="hasTemplate ? 'opacity-60 cursor-not-allowed' : ''"
      :disabled="hasTemplate"
    />

    <div
      v-if="isUploading"
      class="flex items-center gap-2 text-xs text-n-slate-11"
    >
      <NextButton
        ghost
        xs
        icon="i-lucide-paperclip"
        :label="t('AUTOMATION.ATTACHMENT.LABEL_UPLOADING')"
        is-loading
        disabled
      />
    </div>

    <div v-if="showActionButtons" class="flex items-center gap-2">
      <FileUpload
        :multiple="false"
        :maximum="1"
        class="cursor-pointer [&:hover_button]:bg-n-alpha-2 [&:hover_button]:text-n-slate-12"
        @input-file="onFileUpload"
      >
        <NextButton
          ghost
          xs
          icon="i-lucide-paperclip"
          :label="t('AUTOMATION.ACTION.ATTACHMENT_ADD')"
          class="pointer-events-none"
        />
      </FileUpload>
      <NextButton
        v-if="showWhatsappTemplates"
        ghost
        xs
        icon="i-lucide-zap"
        :label="t('AUTOMATION.ACTION.TEMPLATE_SELECT')"
        @click="openWhatsAppTemplatesModal"
      />
    </div>

    <div
      v-if="hasAttachment"
      class="flex items-center gap-2 text-xs text-n-slate-11"
    >
      <span>{{ attachmentLabel }}</span>
      <NextButton ghost xs slate icon="i-lucide-x" @click="clearAttachment" />
    </div>

    <div
      v-if="hasTemplate"
      class="flex items-center gap-2 text-xs text-n-slate-11"
    >
      <span>
        {{ t('AUTOMATION.ACTION.TEMPLATE_SELECTED', { name: templateName }) }}
      </span>
      <NextButton ghost xs slate icon="i-lucide-x" @click="clearTemplate" />
    </div>

    <WhatsappTemplates
      v-model:show="showWhatsAppTemplatesModal"
      :inbox-id="inboxIdForTemplates"
      :send-button-label="t('AUTOMATION.ACTION.TEMPLATE_USE')"
      @on-send="onTemplateSelect"
      @cancel="hideWhatsAppTemplatesModal"
    />
  </div>
</template>
