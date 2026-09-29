<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import InstallManifestDialog from './InstallManifestDialog.vue';

const props = defineProps({
  source: {
    type: String,
    required: true,
  },
  // The assistant whose page is open, preselected in the picker
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['installed', 'done']);

const { t } = useI18n();
const store = useStore();
const assistants = useMapGetter('captainAssistants/getRecords');

const pickerRef = ref(null);
const installDialogRef = ref(null);
const pickedAssistantId = ref(Number(props.assistantId));
// Set once an assistant is chosen, which mounts the install dialog for it
const installAssistantId = ref(null);

const assistantOptions = computed(() =>
  assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
  }))
);

const install = async assistantId => {
  installAssistantId.value = assistantId;
  await nextTick();
  installDialogRef.value.open(props.source);
};

const confirmAssistant = () => {
  install(pickedAssistantId.value);
  pickerRef.value.close();
};

// Cancelling keeps the assistant that was open, not an unconfirmed pick
const onPickerClose = () => {
  if (!installAssistantId.value) emit('done', Number(props.assistantId));
};

// Leaving the tools page while assistants load must not open dialogs that are already gone
let isUnmounted = false;
onBeforeUnmount(() => {
  isUnmounted = true;
});

onMounted(async () => {
  try {
    await store.dispatch('captainAssistants/get');
  } catch {
    if (isUnmounted) return;
    // Finishing clears the install query, so the tools page doesn't keep a flow that never started
    useAlert(t('CAPTAIN.CUSTOM_TOOLS.INSTALL_LINK.LOAD_ERROR'));
    emit('done', Number(props.assistantId));
    return;
  }
  if (isUnmounted) return;

  if (assistants.value.length > 1) {
    pickerRef.value.open();
  } else {
    install(Number(props.assistantId));
  }
});
</script>

<template>
  <Dialog
    ref="pickerRef"
    :title="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_LINK.TITLE')"
    :description="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_LINK.DESCRIPTION')"
    :confirm-button-label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.CONTINUE')"
    :disable-confirm-button="!pickedAssistantId"
    @confirm="confirmAssistant"
    @close="onPickerClose"
  >
    <ComboBox
      v-model="pickedAssistantId"
      :options="assistantOptions"
      :placeholder="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_LINK.PLACEHOLDER')"
      class="[&>div>button]:bg-n-alpha-black2"
    />
  </Dialog>

  <InstallManifestDialog
    v-if="installAssistantId"
    ref="installDialogRef"
    :assistant-id="installAssistantId"
    @installed="emit('installed', installAssistantId)"
    @close="emit('done', installAssistantId)"
  />
</template>
