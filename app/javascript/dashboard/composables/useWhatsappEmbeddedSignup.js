import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useWhatsappComposableOrchestrator } from './whatsapp/useWhatsappComposableOrchestrator';
import { useWhatsappLifecycle } from './whatsapp/useWhatsappLifecycle';
import { useWhatsappComputed } from './whatsapp/useWhatsappComputed';

export function useWhatsappEmbeddedSignup() {
  const store = useStore();
  const router = useRouter();
  const { t } = useI18n();

  const orchestratorResult = useWhatsappComposableOrchestrator({
    store,
    router,
    t,
  });
  const computedResult = useWhatsappComputed({
    t,
    hasSignupStarted: orchestratorResult.hasSignupStarted,
    isProcessing: orchestratorResult.isProcessing,
  });
  const lifecycleResult = useWhatsappLifecycle({
    loadFacebookSdk: orchestratorResult.loadFacebookSdk,
    handleSignupMessage: orchestratorResult.handleSignupMessage,
  });

  return {
    ...orchestratorResult,
    ...computedResult,
    ...lifecycleResult,
  };
}
