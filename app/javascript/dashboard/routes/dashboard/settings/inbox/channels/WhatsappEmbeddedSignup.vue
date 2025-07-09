<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import Icon from 'next/icon/Icon.vue';
import NextButton from 'next/button/Button.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import whatsappIcon from 'dashboard/assets/images/whatsapp.png';
import { useWhatsappEmbeddedSignup } from 'dashboard/composables/useWhatsappEmbeddedSignup';

const {
  fbSdkLoaded,
  processingMessage,
  isAuthenticating,
  benefits,
  showLoader,
  launchEmbeddedSignup,
  initialize,
  cleanupMessageListener,
} = useWhatsappEmbeddedSignup();

onMounted(() => {
  initialize();
});

onBeforeUnmount(() => {
  cleanupMessageListener();
});
</script>

<template>
  <div class="h-full">
    <LoadingState v-if="showLoader" :message="processingMessage" />

    <div v-else>
      <div class="flex flex-col items-start mb-6 text-start">
        <div class="flex justify-start mb-6">
          <div
            class="flex items-center justify-center w-12 h-12 bg-n-alpha-2 rounded-full"
          >
            <img
              :src="whatsappIcon"
              :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD')"
              class="object-contain w-8 h-8"
              draggable="false"
            />
          </div>
        </div>

        <h3 class="mb-2 text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-sm leading-[24px] text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>
      </div>

      <div class="flex flex-col gap-2 mb-6">
        <div
          v-for="benefit in benefits"
          :key="benefit.key"
          class="flex items-center gap-2 text-sm text-n-slate-11"
        >
          <Icon icon="i-lucide-check" class="text-n-slate-11 size-4" />
          {{ benefit.text }}
        </div>
      </div>

      <div class="flex mt-4">
        <NextButton
          :disabled="!fbSdkLoaded || isAuthenticating"
          :is-loading="isAuthenticating"
          faded
          slate
          class="w-full"
          @click="launchEmbeddedSignup"
        >
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
        </NextButton>
      </div>

      <p v-if="!fbSdkLoaded" class="mt-3 text-xs text-start text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LOADING_SDK') }}
      </p>
    </div>
  </div>
</template>
