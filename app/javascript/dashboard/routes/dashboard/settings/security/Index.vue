<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
import SamlPaywall from './components/SamlPaywall.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const { t } = useI18n();
const { shouldShow, shouldShowPaywall } = usePolicy();

const helpURL = computed(() => getHelpUrlForFeature('saml'));

const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);

const isSamlSsoEnabled = computed(() =>
  allowedLoginMethods.value.includes('saml')
);

const shouldShowSaml = computed(() => {
  const hasPermission = shouldShow(
    FEATURE_FLAGS.SAML,
    ['administrator'],
    [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE]
  );
  return hasPermission && isSamlSsoEnabled.value;
});

const showPaywall = computed(() => shouldShowPaywall('saml'));
</script>

<template>
  <SettingsLayout class="mx-auto w-full max-w-6xl">
    <template #header>
      <div class="flex flex-col gap-6 pb-2">
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('SECURITY_SETTINGS.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('SECURITY_SETTINGS.TITLE') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('SECURITY_SETTINGS.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('SECURITY_SETTINGS.LINK_TEXT') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
      </div>
    </template>
    <template #body>
      <SamlPaywall v-if="showPaywall" />
      <SamlSettings v-else-if="shouldShowSaml" />
      <div
        v-else
        class="rounded-2xl border border-outline-variant/10 bg-surface-container-low px-6 py-8 text-center shadow-xl"
      >
        <p class="mb-0 text-sm text-on-surface-variant">
          {{ t('SECURITY_SETTINGS.SAML_DISABLED_MESSAGE') }}
        </p>
      </div>
    </template>
  </SettingsLayout>
</template>
