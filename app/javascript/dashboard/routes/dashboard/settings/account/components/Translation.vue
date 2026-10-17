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
const providerName = computed(() =>
  isCaptainSelected.value
    ? t('GENERAL_SETTINGS.FORM.TRANSLATION.CAPTAIN.TITLE')
    : t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.TITLE')
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
    class="flex flex-col gap-5 items-start px-5 py-4 w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <div class="flex flex-col gap-1">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.NOTE') }}
      </p>
    </div>

    <div class="grid grid-cols-1 gap-3 w-full md:grid-cols-2">
      <RadioCard
        v-if="captainEnabled"
        :id="TRANSLATION_PROVIDERS.CAPTAIN"
        name="translation-provider"
        :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.CAPTAIN.TITLE')"
        :description="t('GENERAL_SETTINGS.FORM.TRANSLATION.CAPTAIN.NOTE')"
        :is-active="isCaptainSelected"
        @select="selectProvider"
      />
      <div class="flex flex-col gap-2">
        <RadioCard
          :id="TRANSLATION_PROVIDERS.GOOGLE"
          name="translation-provider"
          :label="t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.TITLE')"
          :description="t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.NOTE')"
          :is-active="isGoogleSelected"
          :disabled="!googleConnected"
          :disabled-label="
            t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.NOT_CONNECTED')
          "
          @select="selectProvider"
        />
        <router-link
          v-if="!googleConnected"
          :to="{
            name: 'settings_applications_integration',
            params: { integration_id: TRANSLATION_PROVIDERS.GOOGLE },
          }"
          class="text-body-main text-n-blue-11 hover:underline"
        >
          {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.CONNECT') }}
        </router-link>
      </div>
    </div>

    <div class="flex justify-between items-start gap-6 w-full">
      <div class="flex flex-col gap-1 min-w-0">
        <h4 class="text-heading-3 text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.TITLE') }}
        </h4>
        <p class="mb-0 text-body-para text-n-slate-11">
          {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.NOTE') }}
        </p>
        <p v-if="!hasSelection" class="mb-0 text-body-para text-n-amber-11">
          {{ t('GENERAL_SETTINGS.FORM.TRANSLATION.AUTO_TRANSLATE.LOCKED') }}
        </p>
      </div>
      <Switch
        v-model="isAutoTranslateOn"
        :disabled="!hasSelection"
        @change="toggleAutoTranslate"
      />
    </div>

    <p v-if="hasSelection" class="mb-0 text-body-main text-n-slate-11">
      {{
        t('GENERAL_SETTINGS.FORM.TRANSLATION.SERVICE_NOTE', {
          provider: providerName,
        })
      }}
    </p>
  </div>
</template>
