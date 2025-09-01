<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import NextButton from 'next/button/Button.vue';

defineProps({
  fingerprint: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const { accountId } = useAccount();

const acsUrl = computed(() => {
  const currentHost = window.location.origin;
  return `${currentHost}/omniauth/saml/callback?account_id=${accountId.value}`;
});

const handleCopy = async text => {
  await copyTextToClipboard(text);
  useAlert(t('SECURITY_SETTINGS.SAML.COPY_SUCCESS'));
};
</script>

<template>
  <section
    class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
  >
    <div class="pl-4 pr-1 py-1 flex justify-between items-center">
      <div class="flex">
        <span class="text-n-slate-11 w-24">
          {{ t('SECURITY_SETTINGS.SAML.ACS_URL.LABEL') }}
        </span>
        {{ acsUrl }}
      </div>
      <NextButton
        type="button"
        ghost
        sm
        slate
        icon="i-lucide-copy"
        @click="handleCopy(acsUrl)"
      />
    </div>
    <div
      v-if="fingerprint"
      class="pl-4 pr-1 py-1 flex justify-between items-center"
    >
      <div class="flex">
        <span class="text-n-slate-11 w-24">
          {{ t('SECURITY_SETTINGS.SAML.FINGERPRINT.LABEL') }}
        </span>
        {{ fingerprint }}
      </div>
      <NextButton
        type="button"
        ghost
        sm
        slate
        icon="i-lucide-copy"
        @click="handleCopy(fingerprint)"
      />
    </div>
  </section>
</template>
