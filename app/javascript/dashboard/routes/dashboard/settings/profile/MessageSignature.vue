<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useMapGetter } from 'dashboard/composables/store';
import { useInboxSignatures } from 'dashboard/composables/useInboxSignatures';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
  signaturePosition: {
    type: String,
    // NOTE: 'top' or 'bottom'
    default: 'top',
  },
  signatureSeparator: {
    type: String,
    // NOTE: 'blank' or '--'
    default: 'blank',
  },
});

const emit = defineEmits([
  'updateSignature',
  'updateInboxSignature',
  'deleteInboxSignature',
]);

const INBOX_OPTION_DEFAULT = 'default';

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const inboxes = useMapGetter('inboxes/getInboxes');
const { fetchInboxSignatures, getInboxSignature, hasInboxSignature } =
  useInboxSignatures();

const selectedInboxId = ref(INBOX_OPTION_DEFAULT);
const selectedInbox = ref(null);
const signature = ref(props.messageSignature);
const signaturePosition = ref(props.signaturePosition);
const signatureSeparator = ref(props.signatureSeparator);
const isSaving = ref(false);

const defaultOption = computed(() => ({
  id: INBOX_OPTION_DEFAULT,
  name: t(
    'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.INBOX_SELECTOR.DEFAULT'
  ),
}));

const inboxOptions = computed(() => {
  const customLabel = t(
    'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.INBOX_SELECTOR.CUSTOM'
  );
  const items = inboxes.value.map(inbox => ({
    ...inbox,
    icon: hasInboxSignature(inbox.id) ? 'i-lucide-pen-line' : undefined,
    name: hasInboxSignature(inbox.id)
      ? `${inbox.name} (${customLabel})`
      : inbox.name,
  }));
  return [defaultOption.value, ...items];
});

const isDefaultSelected = computed(
  () => selectedInboxId.value === INBOX_OPTION_DEFAULT
);

// Initialize the selected inbox object
selectedInbox.value = defaultOption.value;

const currentInboxHasOverride = computed(() => {
  if (isDefaultSelected.value) return false;
  return hasInboxSignature(selectedInboxId.value);
});

const positionOptions = computed(() => [
  {
    value: 'top',
    label: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.OPTIONS.TOP'
    ),
  },
  {
    value: 'bottom',
    label: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.OPTIONS.BOTTOM'
    ),
  },
]);

const separatorOptions = computed(() => [
  {
    value: 'blank',
    label: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.BLANK'
    ),
  },
  {
    value: '--',
    label: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.HORIZONTAL_LINE'
    ),
  },
]);

const sampleMessage = computed(
  () =>
    `<p>${t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.PREVIEW.SAMPLE_MESSAGE')}</p>`
);

const formattedSignature = computed(() => {
  if (!signature.value) return '';
  return formatMessage(signature.value, false, false);
});

const messagePreview = computed(() => {
  if (!signature.value) return sampleMessage.value;

  const separator =
    signatureSeparator.value === 'blank' ? '<p></p>' : '<p>--</p>';

  if (signaturePosition.value === 'top') {
    return `${formattedSignature.value}${separator}${sampleMessage.value}`;
  }
  return `${sampleMessage.value}${separator}${formattedSignature.value}`;
});

const loadSignatureForSelection = () => {
  if (isDefaultSelected.value) {
    signature.value = props.messageSignature;
    signaturePosition.value = props.signaturePosition;
    signatureSeparator.value = props.signatureSeparator;
    return;
  }

  const inboxSig = getInboxSignature(selectedInboxId.value);
  if (inboxSig) {
    signature.value = inboxSig.message_signature;
    signaturePosition.value = inboxSig.signature_position || 'top';
    signatureSeparator.value = inboxSig.signature_separator || 'blank';
  } else {
    // Pre-fill with global signature for convenience
    signature.value = props.messageSignature;
    signaturePosition.value = props.signaturePosition;
    signatureSeparator.value = props.signatureSeparator;
  }
};

// Keep selectedInboxId in sync with the SingleSelect object model
watch(selectedInbox, newVal => {
  selectedInboxId.value = newVal?.id ?? INBOX_OPTION_DEFAULT;
  loadSignatureForSelection();
});

// Fetch inbox signatures on mount, then reload form values
fetchInboxSignatures().then(() => loadSignatureForSelection());

watch(
  () => props.signaturePosition,
  newValue => {
    if (isDefaultSelected.value) signaturePosition.value = newValue;
  },
  { immediate: true }
);

watch(
  () => props.signatureSeparator,
  newValue => {
    if (isDefaultSelected.value) signatureSeparator.value = newValue;
  },
  { immediate: true }
);

watch(
  () => props.messageSignature ?? '',
  newValue => {
    if (isDefaultSelected.value) signature.value = newValue;
  },
  { immediate: true }
);

const updateSignature = () => {
  if (isDefaultSelected.value) {
    emit(
      'updateSignature',
      signature.value,
      signaturePosition.value,
      signatureSeparator.value
    );
  } else {
    isSaving.value = true;
    emit(
      'updateInboxSignature',
      selectedInboxId.value,
      {
        message_signature: signature.value,
        signature_position: signaturePosition.value,
        signature_separator: signatureSeparator.value,
      },
      () => {
        isSaving.value = false;
      }
    );
  }
};

const handlePositionChange = value => {
  signaturePosition.value = value;
};

const handleSeparatorChange = value => {
  signatureSeparator.value = value;
};

const resetToDefault = () => {
  isSaving.value = true;
  emit('deleteInboxSignature', selectedInboxId.value, () => {
    loadSignatureForSelection();
    isSaving.value = false;
  });
};
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{
          t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.INBOX_SELECTOR.LABEL'
          )
        }}
      </label>
      <div class="flex items-center gap-2">
        <SingleSelect
          v-model="selectedInbox"
          :options="inboxOptions"
          :placeholder="
            t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.INBOX_SELECTOR.DEFAULT'
            )
          "
          disable-deselect
          class="min-w-0 [&_button]:max-w-xs [&_button]:min-w-0"
        />
      </div>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="flex flex-col gap-2">
        <label
          for="signaturePosition"
          class="text-sm font-medium text-n-slate-12"
        >
          {{
            t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.LABEL'
            )
          }}
        </label>
        <select
          id="signaturePosition"
          v-model="signaturePosition"
          name="signaturePosition"
          class="block w-full px-3 py-2 pr-6 mb-0 shadow-sm appearance-none rounded-xl select-caret leading-6 bg-white dark:bg-n-slate-3 border border-n-slate-3 dark:border-n-slate-7"
          @change="handlePositionChange($event.target.value)"
        >
          <option
            v-for="option in positionOptions"
            :key="option.value"
            :value="option.value"
            :selected="option.value === signaturePosition"
          >
            {{ option.label }}
          </option>
        </select>
      </div>
      <div class="flex flex-col gap-2">
        <label
          for="signatureSeparator"
          class="text-sm font-medium text-n-slate-12"
        >
          {{
            t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.LABEL'
            )
          }}
        </label>
        <select
          id="signatureSeparator"
          v-model="signatureSeparator"
          name="signatureSeparator"
          class="block w-full px-3 py-2 pr-6 mb-0 shadow-sm appearance-none rounded-xl select-caret leading-6 bg-white dark:bg-n-slate-3 border border-n-slate-3 dark:border-n-slate-7"
          @change="handleSeparatorChange($event.target.value)"
        >
          <option
            v-for="option in separatorOptions"
            :key="option.value"
            :value="option.value"
            :selected="option.value === signatureSeparator"
          >
            {{ option.label }}
          </option>
        </select>
      </div>
    </div>
    <WootMessageEditor
      id="message-signature-input"
      v-model="signature"
      class="message-editor h-40 !px-3"
      is-format-mode
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
      channel-type="Context::MessageSignature"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <div
      class="flex flex-col gap-3 p-4 bg-n-slate-1 dark:bg-n-slate-2 rounded-lg border border-n-slate-4 dark:border-n-slate-8"
    >
      <div class="flex items-center gap-2">
        <fluent-icon icon="info" size="16" class="text-n-slate-11" />
        <h3 class="text-sm font-medium text-n-slate-12 m-0">
          {{
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.PREVIEW.TITLE')
          }}
        </h3>
      </div>
      <div
        class="bg-white dark:bg-n-slate-3 rounded-md p-3 border border-n-slate-3 dark:border-n-slate-7"
      >
        <div
          v-if="messagePreview"
          v-dompurify-html="messagePreview"
          class="message-preview text-sm text-n-slate-12 [&>p]:mb-2 [&>p:last-child]:mb-0"
        />
        <div v-else class="text-sm text-n-slate-10 italic">
          {{
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.PREVIEW.EMPTY')
          }}
        </div>
      </div>
      <p class="text-xs text-n-slate-11 m-0">
        {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.PREVIEW.NOTE') }}
      </p>
    </div>
    <div class="flex items-center gap-3">
      <NextButton
        type="submit"
        :is-loading="isSaving"
        :label="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT')"
      />
      <NextButton
        v-if="!isDefaultSelected && currentInboxHasOverride"
        type="button"
        variant="faded"
        color="ruby"
        :label="
          $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.RESET_TO_DEFAULT')
        "
        @click="resetToDefault"
      />
    </div>
  </form>
</template>
