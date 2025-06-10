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
      <div class="flex flex-col items-start mb-4 text-left">
        <div class="flex justify-start mb-5">
          <div class="flex items-center justify-center w-12 h-12 rounded-lg">
            <img
              :src="whatsappIcon"
              :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD')"
              class="object-contain w-10 h-10"
            />
          </div>
        </div>

        <h3 class="mb-2 text-lg font-medium text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-sm leading-relaxed text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>
      </div>

      <div class="flex flex-col gap-2 mb-8">
        <div
          v-for="benefit in benefits"
          :key="benefit.key"
          class="flex items-center gap-2 text-sm text-slate-11"
        >
          <Icon icon="i-lucide-check" class="text-slate-11" />
          {{ benefit.text }}
        </div>
      </div>

      <NextButton
        :disabled="!fbSdkLoaded || isAuthenticating"
        :loading="isAuthenticating"
        faded
        slate
        @click="launchEmbeddedSignup"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
      </NextButton>
      <p
        v-if="!fbSdkLoaded"
        class="mt-3 text-xs text-left text-slate-500 dark:text-slate-400"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LOADING_SDK') }}
      </p>
    </div>
  </div>
</template>
