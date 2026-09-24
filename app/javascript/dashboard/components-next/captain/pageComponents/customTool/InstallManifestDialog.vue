<script setup>
import { computed, reactive, ref } from 'vue';
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

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['installed']);

const { t } = useI18n();

const SHORT_REVISION_LENGTH = 7;
const INPUT_TYPES = { password: 'password', number: 'number' };

const dialogRef = ref(null);
const source = ref('');
const preview = ref(null);
// The source exactly as previewed; preview returns a lowercase identity, but GitHub folder names are case-sensitive
const previewedSource = ref('');
// Prototype-free, so field names like "constructor" don't read inherited values and look already filled
const emptyValues = () => Object.create(null);
const values = reactive({ inputs: emptyValues(), secrets: emptyValues() });
const isInstalling = ref(false);
// A slow preview must not land in a dialog that was closed or reopened for another source
const {
  run: runPreview,
  abort: abortPreview,
  isPending: isLoadingPreview,
} = useAbortableRequest();

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
  source.value = '';
  preview.value = null;
  previewedSource.value = '';
  values.inputs = emptyValues();
  values.secrets = emptyValues();
};

// Bumped on every open, so an install finishing after the dialog was reopened doesn't act on the new session
let session = 0;

const open = () => {
  session += 1;
  abortPreview();
  reset();
  dialogRef.value.open();
};

const close = () => dialogRef.value.close();

const loadPreview = async () => {
  const requestedSource = source.value.trim();
  if (!requestedSource) return;

  try {
    const response = await runPreview(signal =>
      ToolsManifestAPI.preview(
        { assistantId: props.assistantId, source: requestedSource },
        { signal }
      )
    );
    if (!response) return;

    previewedSource.value = requestedSource;

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
  }
};

const install = async () => {
  const installSession = session;
  isInstalling.value = true;
  try {
    await ToolsManifestAPI.install({
      assistantId: props.assistantId,
      source: previewedSource.value,
      // Pin to the previewed commit so a newer push can't install tools that were never reviewed
      revision: preview.value.revision,
      configuration: values,
    });
    emit('installed');
    if (installSession !== session) return;

    useAlert(t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.SUCCESS_MESSAGE'));
    close();
  } catch (error) {
    if (installSession !== session) return;

    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.ERROR_MESSAGE')
    );
  } finally {
    isInstalling.value = false;
  }
};

const goBack = () => {
  if (preview.value) {
    preview.value = null;
  } else {
    close();
  }
};

// The dialog is a form, so Enter in the source field submits it
const onEnter = () => {
  if (!preview.value) loadPreview();
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
    @confirm="onEnter"
    @close="abortPreview"
  >
    <div v-if="!preview" class="flex flex-col gap-2">
      <Input
        v-model="source"
        :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.SOURCE_LABEL')"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.SOURCE_PLACEHOLDER')
        "
        :message="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.SOURCE_HELP')"
        class="[&_input]:font-mono"
        autofocus
      />
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
            <span
              class="px-1.5 py-0.5 text-xs font-mono rounded bg-n-alpha-2 text-n-slate-11 w-16 text-center shrink-0"
            >
              {{ tool.http_method }}
            </span>
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
          :label="
            preview
              ? t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.BACK')
              : t('CAPTAIN.FORM.CANCEL')
          "
          class="w-full"
          :disabled="isInstalling"
          @click="goBack"
        />
        <Button
          v-if="!preview"
          type="button"
          :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.CONTINUE')"
          class="w-full"
          :is-loading="isLoadingPreview"
          :disabled="!source.trim() || isLoadingPreview"
          @click="loadPreview"
        />
        <Button
          v-else
          type="button"
          :label="installLabel"
          class="w-full"
          :is-loading="isInstalling"
          :disabled="isInstalled || hasMissingRequiredValues || isInstalling"
          @click="install"
        />
      </div>
    </template>
  </Dialog>
</template>
