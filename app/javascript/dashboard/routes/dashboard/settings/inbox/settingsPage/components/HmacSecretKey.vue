<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const isRotating = ref(false);
const isKeyVisible = ref(false);

const visibilityLabel = computed(() =>
  isKeyVisible.value
    ? t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.HIDE_KEY')
    : t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.SHOW_KEY')
);

const copyKey = async () => {
  await copyTextToClipboard(props.inbox.hmac_token);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
};

const rotate = async () => {
  isRotating.value = true;
  try {
    await store.dispatch('inboxes/rotateHmacToken', props.inbox.id);
    isKeyVisible.value = false;
    dialogRef.value.close();
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.SUCCESS'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.ERROR'));
  } finally {
    isRotating.value = false;
  }
};
</script>

<template>
  <div class="flex items-center gap-2">
    <Input
      :model-value="inbox.hmac_token"
      :type="isKeyVisible ? 'text' : 'password'"
      class="flex-1 min-w-0"
      custom-input-class="font-mono"
      readonly
    />
    <NextButton
      v-tooltip="visibilityLabel"
      faded
      slate
      class="flex-shrink-0"
      :icon="isKeyVisible ? 'i-lucide-eye-off' : 'i-lucide-eye'"
      :aria-label="visibilityLabel"
      @click="isKeyVisible = !isKeyVisible"
    />
    <NextButton
      v-tooltip="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.COPY_KEY')"
      faded
      slate
      class="flex-shrink-0"
      icon="i-lucide-copy"
      :aria-label="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.COPY_KEY')"
      @click="copyKey"
    />
    <NextButton
      faded
      slate
      class="flex-shrink-0"
      icon="i-lucide-refresh-cw"
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.BUTTON')"
      @click="dialogRef.open()"
    />
  </div>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.TITLE')"
    :confirm-button-label="
      $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.CONFIRM')
    "
    :cancel-button-label="
      $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.CANCEL')
    "
    :is-loading="isRotating"
    @confirm="rotate"
  >
    <template #description>
      <div class="flex flex-col gap-2 text-sm text-n-slate-11">
        <p class="mb-0">
          <span class="font-medium text-n-slate-12">
            {{
              $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.WARNING')
            }}
          </span>
          {{
            $t(
              'INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.WARNING_DETAIL'
            )
          }}
        </p>
        <p class="mb-0">
          {{
            $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.ROTATE.IMPACT')
          }}
        </p>
      </div>
    </template>
  </Dialog>
</template>
