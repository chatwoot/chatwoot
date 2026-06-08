<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n, I18nT } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useWhatsappEmbeddedSignup } from 'dashboard/composables/useWhatsappEmbeddedSignup';
import Icon from 'next/icon/Icon.vue';
import NextButton from 'next/button/Button.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import InboxesAPI from 'dashboard/api/inboxes';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import globalConstants from 'dashboard/constants/globals.js';

const props = defineProps({
  enableCallingOnComplete: {
    type: Boolean,
    default: false,
  },
});

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { isAuthenticating, runEmbeddedSignup } = useWhatsappEmbeddedSignup();

const isProcessing = ref(false);
const processingMessage = ref('');

const benefits = computed(() => [
  {
    key: 'EASY_SETUP',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.EASY_SETUP'),
  },
  {
    key: 'SECURE_AUTH',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.SECURE_AUTH'),
  },
  {
    key: 'AUTO_CONFIG',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.AUTO_CONFIG'),
  },
]);

const showLoader = computed(() => isAuthenticating.value || isProcessing.value);

const enableCallingForInbox = async inboxId => {
  try {
    await InboxesAPI.enableWhatsappCalling(inboxId);
  } catch (_) {
    useAlert(
      t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CALLING_ENABLE_FAILED')
    );
  }
};

const handleSignupSuccess = async inboxData => {
  if (inboxData && inboxData.id) {
    if (props.enableCallingOnComplete) {
      processingMessage.value = t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ENABLING_CALLING'
      );
      await enableCallingForInbox(inboxData.id);
    }
    isProcessing.value = false;
    useAlert(t('INBOX_MGMT.FINISH.MESSAGE'));
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: inboxData.id,
      },
    });
  } else {
    isProcessing.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
    router.replace({
      name: 'settings_inbox_list',
    });
  }
};

const launchEmbeddedSignup = async () => {
  let credentials;
  try {
    credentials = await runEmbeddedSignup();
  } catch (error) {
    useAlert(
      error.message ||
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SDK_LOAD_ERROR')
    );
    return;
  }

  // Resolves null when the user dismisses the Meta popup.
  if (!credentials) {
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
    return;
  }

  isProcessing.value = true;
  processingMessage.value = t(
    'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
  );
  try {
    const inboxData = await store.dispatch(
      'inboxes/createWhatsAppEmbeddedSignup',
      credentials
    );
    await handleSignupSuccess(inboxData);
  } catch (error) {
    isProcessing.value = false;
    useAlert(
      parseAPIErrorResponse(error) ||
        t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <div class="h-full">
    <LoadingState v-if="showLoader" :message="processingMessage" />

    <div v-else>
      <div class="flex flex-col items-start mb-6 text-start">
        <div class="flex justify-start mb-6">
          <div
            class="flex size-11 items-center justify-center rounded-full bg-n-alpha-2"
          >
            <Icon icon="i-woot-whatsapp" class="text-n-slate-10 size-6" />
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
          class="flex gap-2 items-center text-sm text-n-slate-11"
        >
          <Icon icon="i-lucide-check" class="text-n-slate-11 size-4" />
          {{ benefit.text }}
        </div>
      </div>

      <div class="flex flex-col gap-2 mb-6">
        <I18nT
          keypath="INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.TEXT"
          tag="span"
          class="text-sm text-n-slate-11"
        >
          <template #link>
            <a
              :href="globalConstants.WHATSAPP_EMBEDDED_SIGNUP_DOCS_URL"
              target="_blank"
              rel="noopener noreferrer"
              class="underline text-n-brand"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.LINK_TEXT'
                )
              }}
            </a>
          </template>
        </I18nT>
      </div>

      <div class="flex mt-4">
        <NextButton
          :disabled="isAuthenticating"
          :is-loading="isAuthenticating"
          faded
          slate
          class="w-full"
          @click="launchEmbeddedSignup"
        >
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
