<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

// `pattern` mirrors Portal::ANALYTICS_PROVIDERS to flag bad ids before saving.
const PROVIDERS = computed(() => [
  {
    key: 'ga4',
    name: t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.GA4.LABEL'),
    placeholder: 'G-XXXXXXXXXX',
    pattern: /^G-[A-Z0-9]+$/,
  },
  {
    key: 'gtm',
    name: t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.GTM.LABEL'),
    placeholder: 'GTM-XXXXXXX',
    pattern: /^GTM-[A-Z0-9]+$/,
  },
  {
    key: 'clarity',
    name: t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.CLARITY.LABEL'),
    placeholder: 'abcd1234ef',
    pattern: /^[a-z0-9]+$/,
  },
  {
    key: 'hotjar',
    name: t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.HOTJAR.LABEL'),
    placeholder: '1234567',
    pattern: /^\d+$/,
  },
  {
    key: 'meta_pixel',
    name: t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.META_PIXEL.LABEL'),
    placeholder: '1234567890',
    pattern: /^\d+$/,
  },
]);

const portalConfig = computed(() => props.activePortal?.config || {});
const providerFor = key =>
  PROVIDERS.value.find(provider => provider.key === key);

const state = reactive({ provider: PROVIDERS.value[0].key, id: '' });
let saved = { provider: '', id: '' };

const resetFromPortal = () => {
  const analytics = portalConfig.value.analytics || {};
  const [key, value] = Object.entries(analytics)[0] || [];
  saved = { provider: key || '', id: value || '' };
  state.provider = saved.provider || PROVIDERS.value[0].key;
  state.id = saved.id;
};

watch(() => props.activePortal, resetFromPortal, {
  immediate: true,
  deep: true,
});

// Clear the id when switching to a provider other than the saved one.
watch(
  () => state.provider,
  provider => {
    state.id = provider === saved.provider ? saved.id : '';
  }
);

const providerOptions = computed(() =>
  PROVIDERS.value.map(provider => ({
    value: provider.key,
    label: provider.name,
  }))
);

const currentProvider = computed(() => providerFor(state.provider));

const error = computed(() => {
  const value = state.id.trim();
  if (!value || currentProvider.value.pattern.test(value)) return '';
  return t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.INVALID_ID');
});

const hasChanges = computed(() => {
  const id = state.id.trim();
  if (!id) return saved.id !== '';
  return id !== saved.id || state.provider !== saved.provider;
});

const handleSave = () => {
  const id = state.id.trim();
  const analytics = id ? { [state.provider]: id } : {};
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    config: { analytics },
  });
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.HEADER') }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.DESCRIPTION') }}
      </span>
    </div>

    <section class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.PROVIDER') }}
        </label>
        <Select v-model="state.provider" :options="providerOptions" />
      </div>

      <Input
        v-model="state.id"
        :label="currentProvider.name"
        :placeholder="currentProvider.placeholder"
        :message="error"
        :message-type="error ? 'error' : 'info'"
      />
    </section>

    <div class="flex justify-end">
      <Button
        :label="t('HELP_CENTER.PORTAL_SETTINGS.ANALYTICS.SAVE')"
        :disabled="!hasChanges || Boolean(error) || isFetching"
        @click="handleSave"
      />
    </div>
  </div>
</template>
