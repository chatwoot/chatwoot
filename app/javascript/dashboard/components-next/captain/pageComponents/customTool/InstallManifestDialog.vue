<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import ToolsManifestAPI from 'dashboard/api/captain/toolsManifest';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['installed', 'close']);

const { t } = useI18n();

const SHORT_REVISION_LENGTH = 7;
const INPUT_TYPES = { password: 'password', number: 'number' };

const dialogRef = ref(null);
// Sent to install exactly as opened; preview returns a lowercase identity, but GitHub folder names are case-sensitive
const source = ref('');
const preview = ref(null);
// Prototype-free, so field names like "constructor" don't read inherited values and look already filled
const emptyValues = () => Object.create(null);
const values = reactive({ inputs: emptyValues(), secrets: emptyValues() });
const isInstalling = ref(false);
// A slow preview must not land in a dialog that was closed or reopened for another source
const { run: runPreview, abort: abortPreview } = useAbortableRequest();

const isInstalled = computed(() => !!preview.value?.up_to_date);
// Installed at this commit but some tools were deleted; reinstalling adds them back
const isReinstall = computed(
  () =>
    !!preview.value &&
    !isInstalled.value &&
    preview.value.installed_revision === preview.value.revision
);
const isUpdate = computed(
  () =>
    !!preview.value?.installed_revision &&
    preview.value.installed_revision !== preview.value.revision
);
const installNote = computed(() => {
  if (isReinstall.value)
    return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.REINSTALL_NOTE');
  if (isUpdate.value)
    return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.UPDATE_NOTE');
  return '';
});
const hasMissingRequiredValues = computed(() =>
  preview.value.fields.some(
    field =>
      field.required &&
      field.type !== 'boolean' &&
      !String(values[field.section][field.name] ?? '').trim()
  )
);
const installLabel = computed(() => {
  if (isInstalled.value)
    return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.ALREADY_INSTALLED');
  if (isReinstall.value)
    return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.REINSTALL');
  if (isUpdate.value) return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.UPDATE');
  return t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.INSTALL');
});
const versionLabel = computed(() =>
  t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.VERSION_LABEL', {
    version: preview.value.version,
    revision: preview.value.revision.slice(0, SHORT_REVISION_LENGTH),
  })
);

const sourceIdentifier = computed(
  () => `${preview.value.repository}/${preview.value.path}`
);

const selectOptions = field =>
  (field.options || []).map(option => ({ value: option, label: option }));

const reset = () => {
  preview.value = null;
  values.inputs = emptyValues();
  values.secrets = emptyValues();
};

// Bumped on every open and close, so an install finishing after the dialog was dismissed or reopened is ignored
let session = 0;

const close = () => dialogRef.value.close();

// The tools page is reused across assistants, so a preview must never be installed into the next one
watch(
  () => props.assistantId,
  () => {
    session += 1;
    abortPreview();
    close();
  }
);

const loadPreview = async () => {
  try {
    const response = await runPreview(signal =>
      ToolsManifestAPI.preview(
        { assistantId: props.assistantId, source: source.value },
        { signal }
      )
    );
    if (!response) return;

    const { data } = response;
    values.inputs = emptyValues();
    values.secrets = emptyValues();
    data.fields
      .filter(field => field.type === 'boolean')
      .forEach(field => {
        values[field.section][field.name] = false;
      });
    preview.value = data;
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.PREVIEW_ERROR')
    );
    // There is nothing to show without a preview
    close();
  }
};

// The catalog and install links open the dialog with a source, which goes straight to its preview
const open = toolsetSource => {
  session += 1;
  abortPreview();
  reset();
  // A request from before a reopen must not keep the new dialog locked
  isInstalling.value = false;
  source.value = toolsetSource;
  dialogRef.value.open();
  loadPreview();
};

const install = async () => {
  const installSession = session;
  isInstalling.value = true;
  try {
    await ToolsManifestAPI.install({
      assistantId: props.assistantId,
      source: source.value,
      // Pin to the previewed commit so a newer push can't install tools that were never reviewed
      revision: preview.value.revision,
      configuration: values,
    });
    if (installSession !== session) return;

    emit('installed');
    useAlert(t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.SUCCESS_MESSAGE'));
    close();
  } catch (error) {
    if (installSession !== session) return;

    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.ERROR_MESSAGE')
    );
  } finally {
    if (installSession === session) isInstalling.value = false;
  }
};

const onClose = () => {
  session += 1;
  abortPreview();
  emit('close');
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="xl"
    :title="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.TITLE')"
    :description="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="onClose"
  >
    <div v-if="!preview" class="flex justify-center py-8">
      <Spinner />
    </div>

    <div
      v-else
      class="flex flex-col gap-5 max-h-[min(28rem,calc(100vh-18rem))] overflow-y-auto px-1 -mx-1"
    >
      <div class="flex flex-col gap-1">
        <div class="flex items-baseline justify-between gap-3">
          <h4 class="text-sm font-medium text-n-slate-12 truncate">
            {{ preview.name }}
          </h4>
          <span class="text-xs text-n-slate-11 shrink-0 font-mono">
            {{ versionLabel }}
          </span>
        </div>
        <p class="text-sm text-n-slate-11 mb-0">{{ preview.description }}</p>
        <span class="text-xs text-n-slate-10 font-mono inline-flex gap-1">
          <i class="i-lucide-github size-3.5 shrink-0" />
          {{ sourceIdentifier }}
        </span>
      </div>

      <div
        v-if="installNote"
        class="flex items-start gap-2 px-3 py-2 text-xs rounded-lg bg-n-amber-2 text-n-amber-11"
      >
        <i class="i-lucide-info size-3.5 mt-0.5 shrink-0" />
        {{ installNote }}
      </div>

      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.TOOLS_LABEL') }}
        </span>
        <ul class="flex flex-col gap-1.5 list-none m-0">
          <li
            v-for="tool in preview.tools"
            :key="tool.id"
            class="flex items-center gap-2 text-sm text-n-slate-12"
          >
            <i class="i-lucide-wrench size-3.5 shrink-0 text-n-slate-10" />
            <span class="truncate">{{ tool.title }}</span>
          </li>
        </ul>
      </div>

      <div
        v-if="preview.fields.length && !isInstalled"
        class="flex flex-col gap-3"
      >
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.CONFIGURATION_LABEL') }}
        </span>
        <template
          v-for="field in preview.fields"
          :key="`${field.section}-${field.name}`"
        >
          <label
            v-if="field.type === 'boolean'"
            class="flex items-center justify-between gap-3 text-sm text-n-slate-12"
          >
            {{ field.label }}
            <Switch v-model="values[field.section][field.name]" />
          </label>
          <div v-else-if="field.type === 'select'" class="flex flex-col gap-1">
            <label class="mb-0.5 text-sm font-medium text-n-slate-12">
              {{ field.label }}
            </label>
            <ComboBox
              v-model="values[field.section][field.name]"
              :options="selectOptions(field)"
              :placeholder="field.placeholder || ''"
              class="[&>div>button]:bg-n-alpha-black2"
            />
          </div>
          <Input
            v-else
            v-model="values[field.section][field.name]"
            :label="field.label"
            :type="INPUT_TYPES[field.type] || 'text'"
            :placeholder="field.placeholder || ''"
          />
        </template>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          type="button"
          faded
          slate
          :label="t('CAPTAIN.FORM.CANCEL')"
          class="w-full"
          :disabled="isInstalling"
          @click="close"
        />
        <Button
          type="button"
          :label="installLabel"
          class="w-full"
          :is-loading="isInstalling"
          :disabled="
            !preview || isInstalled || hasMissingRequiredValues || isInstalling
          "
          @click="install"
        />
      </div>
    </template>
  </Dialog>
</template>
