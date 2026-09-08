<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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

const rotate = async () => {
  isRotating.value = true;
  try {
    await store.dispatch('inboxes/rotateHmacToken', props.inbox.id);
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
  <div class="flex items-stretch gap-2">
    <woot-code class="flex-1 min-w-0" :script="inbox.hmac_token" />
    <NextButton
      faded
      slate
      class="flex-shrink-0 h-auto"
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
