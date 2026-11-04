<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useFunctionGetter, useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  TRANSLATION_PROVIDERS,
  translationProvider,
} from 'dashboard/helper/translationProvider';
import Switch from 'next/switch/Switch.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const GOOGLE_LOGO = '/dashboard/images/integrations/google_translate.png';
const GOOGLE_LOGO_DARK =
  '/dashboard/images/integrations/google_translate-dark.png';

const { t } = useI18n();
const router = useRouter();
const { needsUpgrade } = useTranslationPlan();
const store = useStore();
const { accountId, currentAccount, updateAccount } = useAccount();
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const googleIntegration = useFunctionGetter(
  'integrations/getIntegration',
  TRANSLATION_PROVIDERS.GOOGLE
);

const isAutoTranslateOn = ref(false);

const captainEnabled = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.CAPTAIN_TASKS)
);
const googleConnected = computed(() => !!googleIntegration.value.enabled);

const provider = computed(() =>
  translationProvider(currentAccount.value?.settings)
);
const isCaptainSelected = computed(
  () => captainEnabled.value && provider.value === TRANSLATION_PROVIDERS.CAPTAIN
);
const isGoogleSelected = computed(
  () => googleConnected.value && provider.value === TRANSLATION_PROVIDERS.GOOGLE
);
const isAutoTranslateFeatureEnabled = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.AUTO_TRANSLATE)
);
const hasSelection = computed(
  () => isCaptainSelected.value || isGoogleSelected.value
);
const autoTranslateLockedReason = computed(() => {
  if (!isAutoTranslateFeatureEnabled.value) {
    return t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.NOT_AVAILABLE');
  }
  if (!hasSelection.value) {
    return t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.LOCKED');
  }
  return '';
});
watch(
  () =>
    !autoTranslateLockedReason.value &&
    currentAccount.value?.settings?.auto_translate === true,
  isOn => {
    isAutoTranslateOn.value = isOn;
  },
  { immediate: true }
);

onMounted(() => store.dispatch('integrations/get'));

const saveSettings = async settings => {
  try {
    await updateAccount(settings, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.TRANSLATION.API.SUCCESS'));
  } catch {
    useAlert(t('GENERAL_SETTINGS.FORM.TRANSLATION.API.ERROR'));
  }
};

const selectProvider = value => saveSettings({ translation_provider: value });
const toggleAutoTranslate = () =>
  saveSettings({ auto_translate: isAutoTranslateOn.value });
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.NOTE') }}
      </p>
    </div>

    <div
      v-if="needsUpgrade"
      class="flex flex-col gap-3 justify-between items-start px-5 py-4 sm:flex-row sm:items-center"
    >
      <p class="mb-0 text-body-main text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.UPGRADE.NOTE') }}
      </p>
      <NextButton
        sm
        :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.UPGRADE.BUTTON')"
        class="flex-shrink-0"
        @click="router.push({ name: 'billing_settings_index' })"
      />
    </div>
    <div v-else class="flex flex-col gap-4 px-5 py-4">
      <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
        <RadioCard
          v-if="captainEnabled"
          :id="TRANSLATION_PROVIDERS.CAPTAIN"
          name="translation-provider"
          class="h-full"
          :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.CAPTAIN.TITLE')"
          :description="t('GENERAL_SETTINGS.FORM.TRANSLATION.CAPTAIN.NOTE')"
          :is-active="isCaptainSelected"
          @select="selectProvider"
        >
          <template #icon>
            <span
              class="flex flex-shrink-0 justify-center items-center rounded-lg size-12 bg-n-alpha-2"
            >
              <span class="i-woot-captain size-6 text-n-slate-12" />
            </span>
          </template>
        </RadioCard>
        <div class="relative group">
          <RadioCard
            :id="TRANSLATION_PROVIDERS.GOOGLE"
            name="translation-provider"
            class="h-full"
            :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.TITLE')"
            :description="t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.NOTE')"
            :is-active="isGoogleSelected"
            :disabled="!googleConnected"
            :disabled-label="
              t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.NOT_CONNECTED')
            "
            @select="selectProvider"
          >
            <template #icon>
              <span
                class="flex flex-shrink-0 justify-center items-center rounded-lg size-12 bg-n-alpha-2"
              >
                <img
                  :src="GOOGLE_LOGO"
                  class="object-contain size-6 dark:hidden"
                  alt=""
                />
                <img
                  :src="GOOGLE_LOGO_DARK"
                  class="hidden object-contain size-6 dark:block"
                  alt=""
                />
              </span>
            </template>
          </RadioCard>
          <div
            v-if="!googleConnected"
            class="hidden absolute inset-0 gap-3 justify-between items-center px-4 rounded-xl group-hover:flex group-focus-within:flex bg-n-solid-1 outline outline-1 outline-n-weak"
          >
            <span class="text-body-main text-n-slate-12">
              {{
                t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.NOT_CONNECTED_HINT')
              }}
            </span>
            <router-link
              :to="{ name: 'settings_integrations_google_translate' }"
              class="flex-shrink-0"
            >
              <NextButton
                sm
                faded
                slate
                trailing-icon
                icon="i-lucide-arrow-right"
                :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.CONNECT')"
              />
            </router-link>
          </div>
        </div>
      </div>

      <div
        class="flex gap-4 justify-between items-center p-3 w-full rounded-xl border border-n-weak bg-n-solid-1"
      >
        <div class="flex flex-col gap-0.5 min-w-0">
          <span class="text-body-main text-n-slate-12">
            {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.TITLE') }}
          </span>
          <span
            class="text-body-main"
            :class="
              autoTranslateLockedReason ? 'text-n-amber-11' : 'text-n-slate-11'
            "
          >
            {{
              autoTranslateLockedReason ||
              t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.NOTE')
            }}
          </span>
        </div>
        <Switch
          v-model="isAutoTranslateOn"
          :disabled="!!autoTranslateLockedReason"
          @change="toggleAutoTranslate"
        />
      </div>
    </div>
  </div>
</template>
