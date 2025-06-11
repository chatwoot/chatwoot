import { computed } from 'vue';

export function useWhatsappComputed({ t, hasSignupStarted, isProcessing }) {
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

  const showLoader = computed(
    () => hasSignupStarted.value || isProcessing.value
  );

  return {
    benefits,
    showLoader,
  };
}
