<script setup>
import { ref, computed, watch } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  settingKey: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  successMessage: {
    type: String,
    required: true,
  },
  errorMessage: {
    type: String,
    required: true,
  },
  requireConfirmation: {
    type: Boolean,
    default: false,
  },
  confirmTitle: {
    type: String,
    default: '',
  },
  confirmButtonLabel: {
    type: String,
    default: '',
  },
  confirmTitleWhenEnabled: {
    type: String,
    default: '',
  },
  confirmButtonLabelWhenEnabled: {
    type: String,
    default: '',
  },
});

const isEnabled = ref(false);
const dialogRef = ref(null);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    isEnabled.value = !!currentAccount.value?.settings?.[props.settingKey];
  },
  { deep: true, immediate: true }
);

const activeConfirmTitle = computed(() =>
  isEnabled.value && props.confirmTitleWhenEnabled
    ? props.confirmTitleWhenEnabled
    : props.confirmTitle
);

const activeConfirmButtonLabel = computed(() =>
  isEnabled.value && props.confirmButtonLabelWhenEnabled
    ? props.confirmButtonLabelWhenEnabled
    : props.confirmButtonLabel
);

const save = async newValue => {
  try {
    await updateAccount({ [props.settingKey]: newValue }, { silent: true });
    isEnabled.value = newValue;
    useAlert(props.successMessage);
  } catch {
    useAlert(props.errorMessage);
  }
};

const onToggleClick = () => {
  if (props.requireConfirmation) {
    dialogRef.value?.open();
  } else {
    save(!isEnabled.value);
  }
};

const onConfirm = async () => {
  await save(!isEnabled.value);
  dialogRef.value?.close();
};
</script>

<template>
  <SectionLayout :title="title" :description="description" with-border>
    <template #headerActions>
      <div class="flex justify-end">
        <Switch :model-value="isEnabled" @change="onToggleClick" />
      </div>
    </template>
  </SectionLayout>

  <Dialog
    v-if="requireConfirmation"
    ref="dialogRef"
    type="alert"
    :title="activeConfirmTitle"
    :confirm-button-label="activeConfirmButtonLabel"
    @confirm="onConfirm"
  />
</template>
