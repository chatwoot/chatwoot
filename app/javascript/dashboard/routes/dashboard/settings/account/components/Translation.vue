<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useFunctionGetter, useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  TRANSLATION_PROVIDERS,
  translationProvider,
} from 'dashboard/helper/translationProvider';
import Switch from 'next/switch/Switch.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const { t } = useI18n();
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
  translationProvider(currentAccount.value?.settings, googleConnected.value)
);
const isCaptainSelected = computed(
  () => captainEnabled.value && provider.value === TRANSLATION_PROVIDERS.CAPTAIN
);
const isGoogleSelected = computed(
  () => googleConnected.value && provider.value === TRANSLATION_PROVIDERS.GOOGLE
);
const hasSelection = computed(
  () => isCaptainSelected.value || isGoogleSelected.value
);
watch(
  currentAccount,
  account => {
    isAutoTranslateOn.value = account?.settings?.auto_translate === true;
  },
  { immediate: true, deep: true }
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

    <div class="flex flex-col gap-4 px-5 py-4">
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
        />
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
        />
      </div>
      <router-link
        v-if="!googleConnected"
        :to="{
          name: 'settings_applications_integration',
          params: { integration_id: TRANSLATION_PROVIDERS.GOOGLE },
        }"
        class="self-start text-body-main text-n-blue-11 hover:underline"
      >
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.CONNECT') }}
      </router-link>

      <div
        class="flex gap-4 justify-between items-center p-3 w-full rounded-xl border border-n-weak bg-n-solid-1"
      >
        <div class="flex flex-col gap-0.5 min-w-0">
          <span class="text-body-main text-n-slate-12">
            {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.TITLE') }}
          </span>
          <span
            class="text-body-main"
            :class="hasSelection ? 'text-n-slate-11' : 'text-n-amber-11'"
          >
            {{
              hasSelection
                ? t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.NOTE')
                : t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.LOCKED')
            }}
          </span>
        </div>
        <Switch
          v-model="isAutoTranslateOn"
          :disabled="!hasSelection"
          @change="toggleAutoTranslate"
        />
      </div>
    </div>
  </div>
</template>
