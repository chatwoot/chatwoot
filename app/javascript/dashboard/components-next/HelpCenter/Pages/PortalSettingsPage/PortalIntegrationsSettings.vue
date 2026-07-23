<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useBranding } from 'shared/composables/useBranding';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();
const store = useStore();
const { replaceInstallationName } = useBranding();

// Mirrors Portal::ANALYTICS_CONFIG_FORMATS on the backend.
const ANALYTICS_PROVIDERS = [
  {
    key: 'gtm_container_id',
    i18nKey: 'GTM',
    icon: 'i-logos-google-tag-manager',
    format: /^GTM-[A-Z0-9]+$/,
  },
  {
    key: 'ga4_measurement_id',
    i18nKey: 'GA4',
    icon: 'i-logos-google-analytics',
    format: /^G-[A-Z0-9]+$/,
  },
  {
    key: 'hotjar_site_id',
    i18nKey: 'HOTJAR',
    icon: 'i-logos-hotjar-icon',
    format: /^\d+$/,
  },
  {
    key: 'plausible_domain',
    i18nKey: 'PLAUSIBLE',
    icon: 'i-woot-plausible',
    format: /^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/i,
  },
  {
    key: 'amplitude_api_key',
    i18nKey: 'AMPLITUDE',
    icon: 'i-logos-amplitude-icon',
    format: /^[a-z0-9]+$/i,
  },
  {
    key: 'clarity_project_id',
    i18nKey: 'CLARITY',
    icon: 'i-woot-microsoft-clarity',
    format: /^[a-z0-9]+$/i,
  },
  {
    key: 'meta_pixel_id',
    i18nKey: 'META_PIXEL',
    icon: 'i-logos-meta-icon',
    format: /^\d+$/,
  },
];

const portalConfig = computed(() => props.activePortal?.config || {});

const liveChatWidgets = computed(() => {
  const widgetOptions = store.getters['inboxes/getInboxes']
    .filter(inbox => inbox.channel_type === 'Channel::WebWidget')
    .map(inbox => ({ value: inbox.id, label: inbox.name }));

  return [
    {
      value: '',
      label: t(
        'HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.LIVE_CHAT.NONE_OPTION'
      ),
    },
    ...widgetOptions,
  ];
});

const state = reactive({
  liveChatWidgetInboxId: '',
  ...Object.fromEntries(ANALYTICS_PROVIDERS.map(({ key }) => [key, ''])),
});
const originalState = reactive({ ...state });

const resetFromPortal = () => {
  state.liveChatWidgetInboxId = props.activePortal?.inbox?.id || '';
  ANALYTICS_PROVIDERS.forEach(({ key }) => {
    state[key] = portalConfig.value[key] || '';
  });
  Object.assign(originalState, state);
};

watch(() => props.activePortal, resetFromPortal, {
  immediate: true,
  deep: true,
});

const liveChatTitle = computed(() =>
  replaceInstallationName(
    t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.LIVE_CHAT.TITLE')
  )
);

const trimmedAnalyticsValues = computed(() =>
  Object.fromEntries(
    ANALYTICS_PROVIDERS.map(({ key }) => [key, state[key].trim()])
  )
);

const invalidAnalyticsKeys = computed(() =>
  ANALYTICS_PROVIDERS.filter(({ key, format }) => {
    const value = trimmedAnalyticsValues.value[key];
    return value !== '' && !format.test(value);
  }).map(({ key }) => key)
);

const isInvalid = key => invalidAnalyticsKeys.value.includes(key);

const hasChanges = computed(
  () =>
    state.liveChatWidgetInboxId !== originalState.liveChatWidgetInboxId ||
    ANALYTICS_PROVIDERS.some(
      ({ key }) => trimmedAnalyticsValues.value[key] !== originalState[key]
    )
);

const handleSave = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    inbox_id: state.liveChatWidgetInboxId,
    config: { ...trimmedAnalyticsValues.value },
  });
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.HEADER') }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.DESCRIPTION') }}
      </span>
    </div>

    <div
      class="flex flex-col gap-4 p-4 rounded-xl outline outline-1 outline-n-weak"
    >
      <div class="flex items-start gap-3">
        <div
          class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-12"
        >
          <Icon icon="i-lucide-messages-square" class="size-5" />
        </div>
        <div class="flex flex-col gap-0.5">
          <h6 class="text-sm font-medium text-n-slate-12">
            {{ liveChatTitle }}
          </h6>
          <span class="text-sm text-n-slate-11">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.LIVE_CHAT.DESCRIPTION'
              )
            }}
          </span>
        </div>
      </div>
      <ComboBox
        v-model="state.liveChatWidgetInboxId"
        :options="liveChatWidgets"
        :placeholder="
          t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.LIVE_CHAT.PLACEHOLDER')
        "
        class="[&>div>button:not(.focused)]:!outline-n-weak"
      />
    </div>

    <div
      v-for="provider in ANALYTICS_PROVIDERS"
      :key="provider.key"
      class="flex flex-col gap-4 p-4 rounded-xl outline outline-1 outline-n-weak"
    >
      <div class="flex items-start gap-3">
        <div
          class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-12"
        >
          <Icon :icon="provider.icon" class="size-5" />
        </div>
        <div class="flex flex-col gap-0.5">
          <h6 class="text-sm font-medium text-n-slate-12">
            {{
              t(
                `HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.${provider.i18nKey}.TITLE`
              )
            }}
          </h6>
          <span class="text-sm text-n-slate-11">
            {{
              t(
                `HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.${provider.i18nKey}.DESCRIPTION`
              )
            }}
          </span>
        </div>
      </div>
      <Input
        v-model="state[provider.key]"
        :placeholder="
          t(
            `HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.${provider.i18nKey}.PLACEHOLDER`
          )
        "
        :message="
          isInvalid(provider.key)
            ? t(
                `HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.${provider.i18nKey}.INVALID`
              )
            : t(
                `HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.${provider.i18nKey}.HELP`
              )
        "
        :message-type="isInvalid(provider.key) ? 'error' : 'info'"
      />
    </div>

    <div class="flex justify-end">
      <Button
        :label="t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.SAVE')"
        :disabled="!hasChanges || invalidAnalyticsKeys.length > 0 || isFetching"
        @click="handleSave"
      />
    </div>
  </div>
</template>
