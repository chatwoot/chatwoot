<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import zaloOaClient from 'dashboard/api/channel/zaloOaClient';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const hasError = ref(false);
const errorStateMessage = ref('');
const errorStateDescription = ref('');
const isRequestingAuthorization = ref(false);

onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search);
  const errorCode = urlParams.get('code');
  const errorMessage = urlParams.get('error_message');

  if (errorMessage) {
    hasError.value = true;
    if (errorCode === '400') {
      errorStateMessage.value = errorMessage;
      errorStateDescription.value = t(
        'INBOX_MGMT.ADD.ZALO_OA_CHANNEL.ERROR_AUTH'
      );
    } else {
      errorStateMessage.value = t(
        'INBOX_MGMT.ADD.ZALO_OA_CHANNEL.ERROR_MESSAGE'
      );
      errorStateDescription.value = errorMessage;
    }
  }
  // User need to remove the error params from the url to avoid the error to be shown again after page reload
  const cleanURL = window.location.pathname;
  window.history.replaceState({}, document.title, cleanURL);
});

const requestAuthorization = async () => {
  isRequestingAuthorization.value = true;
  try {
    const response = await zaloOaClient.generateAuthorization();
    const {
      data: { url },
    } = response;

    window.location.href = url;
  } catch (error) {
    hasError.value = true;
    errorStateMessage.value = t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.ERROR_MESSAGE');
    errorStateDescription.value =
      error.message || t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.API.ERROR_MESSAGE');
    isRequestingAuthorization.value = false;
  }
};
</script>

<template>
  <div class="h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0">
    <div class="flex flex-col items-center justify-start h-full text-center">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center px-8 py-10 text-center rounded-2xl outline outline-1 outline-n-weak"
      >
        <h6 class="text-2xl font-medium">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.CONNECT_YOUR_ZALO_OA') }}
        </h6>
        <p class="py-6 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.HELP') }}
        </p>
        <Button
          class="text-white !rounded-full !px-6 bg-[#0068FF]"
          lg
          icon="i-woot-zalo"
          :disabled="isRequestingAuthorization"
          :is-loading="isRequestingAuthorization"
          :label="$t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.CONTINUE_WITH_ZALO')"
          @click="requestAuthorization()"
        />
      </div>
    </div>
  </div>
</template>
