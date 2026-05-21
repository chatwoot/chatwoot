<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import NextButton from 'next/button/Button.vue';

const props = defineProps({
  fingerprint: {
    type: String,
    default: '',
  },
  spEntityId: {
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

const allInfoItems = computed(() => [
  {
    key: 'ACS_URL',
    label: t('SECURITY_SETTINGS.SAML.ACS_URL.LABEL'),
    value: acsUrl.value,
    tooltip: t('SECURITY_SETTINGS.SAML.ACS_URL.TOOLTIP'),
    show: true,
  },
  {
    key: 'SP_ENTITY_ID',
    label: t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.LABEL'),
    value: props.spEntityId,
    tooltip: t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.TOOLTIP'),
    show: !!props.spEntityId,
  },
  {
    key: 'FINGERPRINT',
    label: t('SECURITY_SETTINGS.SAML.FINGERPRINT.LABEL'),
    value: props.fingerprint,
    tooltip: t('SECURITY_SETTINGS.SAML.FINGERPRINT.TOOLTIP'),
    show: !!props.fingerprint,
  },
]);

const visibleInfoItems = computed(() =>
  allInfoItems.value.filter(item => item.show)
);

const handleCopy = async text => {
  await copyTextToClipboard(text);
  useAlert(t('SECURITY_SETTINGS.SAML.COPY_SUCCESS'));
};
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center gap-2">
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ t('SECURITY_SETTINGS.SAML.INFO_SECTION.TITLE') }}
      </h3>
      <i
        v-tooltip.top="t('SECURITY_SETTINGS.SAML.INFO_SECTION.TOOLTIP')"
        class="i-lucide-info text-n-slate-10 w-4 h-4 cursor-help"
      />
    </div>
    <section
      class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
    >
      <div
        v-for="item in visibleInfoItems"
        :key="item.key"
        class="ps-4 pe-1 py-1 flex justify-between items-center"
      >
        <div class="flex items-center gap-2">
          <span class="text-n-slate-11 w-32 flex items-center gap-1">
            {{ item.label }}
            <i
              v-tooltip.top="item.tooltip"
              class="i-lucide-info text-n-slate-9 w-3 h-3 cursor-help"
            />
          </span>
          <span class="flex-1">{{ item.value }}</span>
        </div>
        <NextButton
          type="button"
          ghost
          sm
          slate
          icon="i-lucide-copy"
          @click="handleCopy(item.value)"
        />
      </div>
    </section>
  </div>
</template>
