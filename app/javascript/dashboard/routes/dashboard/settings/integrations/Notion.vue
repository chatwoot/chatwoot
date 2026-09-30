<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import ButtonNext from 'next/button/Button.vue';
import notionClient from 'dashboard/api/notion_auth.js';
import IntegrationsAPI from 'dashboard/api/integrations.js';

import Integration from './Integration.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();
const store = useStore();
const integrationLoaded = ref(false);
const parentTargetInput = ref('');
const isSavingParentTarget = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'notion');

const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }

  return '';
});

const notionHook = computed(() => integration.value.hooks?.[0] || null);

const parentTarget = computed(() => {
  if (!notionHook.value) {
    return '';
  }

  return (
    notionHook.value.settings?.parent_page_id ||
    notionHook.value.settings?.parent_database_id ||
    ''
  );
});

const parseParentTarget = value => {
  const raw = value.trim();
  if (!raw) {
    return null;
  }
  // Accept a Notion URL or a raw page/database id.
 The id is the last 32-char segment of the URL.
 const match = raw.match(/([a-f0-9]{32})$/i) || raw.match(/^([a-f0-9]{32})$/i);
  return match ? { id: match[1], url: raw } : null;
};

const saveParentTarget = async () => {
  const parsed = parseParentTarget(parentTargetInput.value);
  if (!parsed) {
    return;
  }
  isSavingParentTarget.value = true;
  const settings = {
    ...notionHook.value.settings,
    parent_page_id: parsed.id,
  };
  try {
    await IntegrationsAPI.updateHook(notionHook.value.id, { settings });
    await store.dispatch('integrations/get', 'notion');
  } finally {
    isSavingParentTarget.value = false;
  }
};

const authorize = async () => {
  const response = await notionClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};

const initializeNotionIntegration = async () => {
  await store.dispatch('integrations/get', 'notion');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeNotionIntegration();
});

watch(parentTarget, value => {
  if (value && !parentTargetInput.value) {
    parentTargetInput.value = value;
  }
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || uiFlags.isCreatingNotion">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.NOTION.HEADER')"
        description=""
        feature-name="notion_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: t('INTEGRATION_SETTINGS.NOTION.DELETE.TITLE'),
          message: t('INTEGRATION_SETTINGS.NOTION.DELETE.MESSAGE'),
        }"
      >
        <template #action>
          <ButtonNext
            faded
            blue
            :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            @click="authorize"
          />
        </template>
        <template v-if="integration.enabled" #default>
          <div class="mt-4 rounded-md bg-slate-50 p-4">
            <p class="mb-2 text-sm text-slate-700">
              {{ $t('INTEGRATION_SETTINGS.NOTION.PARENT_TARGET_LABEL') }}
            </p>
            <div class="flex gap-2">
              <input
                v-model="parentTargetInput"
                type="text"
                class="input"
                :placeholder="$t('INTEGRATION_SETTINGS.NOTION.PARENT_TARGET_PLACEHOLDER')"
              />
              <ButtonNext
                faded
                green
                :label="$t('INTEGRATION_SETTINGS.NOTION.SAVE_BUTTON')"
                :is-loading="isSavingParentTarget"
                @click="saveParentTarget"
              />
            </div>
          </div>
        </template>
      </Integration>
    </template>
  </SettingsLayout>
</template>
