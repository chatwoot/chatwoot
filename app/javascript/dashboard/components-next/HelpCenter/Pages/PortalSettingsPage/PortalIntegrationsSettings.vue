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

// Mirrors Portal::GTM_CONTAINER_ID_FORMAT on the backend.
const GTM_CONTAINER_ID_FORMAT = /^GTM-[A-Z0-9]+$/;

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
  gtmContainerId: '',
});
const originalState = reactive({ ...state });

const resetFromPortal = () => {
  state.liveChatWidgetInboxId = props.activePortal?.inbox?.id || '';
  state.gtmContainerId = portalConfig.value.gtm_container_id || '';
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

const trimmedGtmId = computed(() => state.gtmContainerId.trim());

const isGtmInvalid = computed(
  () =>
    trimmedGtmId.value !== '' &&
    !GTM_CONTAINER_ID_FORMAT.test(trimmedGtmId.value)
);

const hasChanges = computed(
  () =>
    state.liveChatWidgetInboxId !== originalState.liveChatWidgetInboxId ||
    trimmedGtmId.value !== originalState.gtmContainerId
);

const handleSave = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    inbox_id: state.liveChatWidgetInboxId,
    config: { gtm_container_id: trimmedGtmId.value },
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
      class="flex flex-col gap-4 p-4 rounded-xl outline outline-1 outline-n-weak"
    >
      <div class="flex items-start gap-3">
        <div
          class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-12"
        >
          <Icon icon="i-ri-google-fill" class="size-5" />
        </div>
        <div class="flex flex-col gap-0.5">
          <h6 class="text-sm font-medium text-n-slate-12">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.GTM.TITLE') }}
          </h6>
          <span class="text-sm text-n-slate-11">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.GTM.DESCRIPTION') }}
          </span>
        </div>
      </div>
      <Input
        v-model="state.gtmContainerId"
        :placeholder="
          t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.GTM.PLACEHOLDER')
        "
        :message="
          isGtmInvalid
            ? t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.GTM.INVALID')
            : t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.GTM.HELP')
        "
        :message-type="isGtmInvalid ? 'error' : 'info'"
      />
    </div>

    <div class="flex justify-end">
      <Button
        :label="t('HELP_CENTER.PORTAL_SETTINGS.INTEGRATIONS.SAVE')"
        :disabled="!hasChanges || isGtmInvalid || isFetching"
        @click="handleSave"
      />
    </div>
  </div>
</template>
