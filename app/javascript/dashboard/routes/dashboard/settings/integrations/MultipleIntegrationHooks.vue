<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import { useI18n } from 'vue-i18n';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  integrationId: {
    type: String,
    required: true,
  },
  showAddButton: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['delete', 'add']);
const { t } = useI18n();

const { integration, isHookTypeInbox, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const globalConfig = useMapGetter('globalConfig/get');
const searchQuery = ref('');

const hookHeaders = computed(() => {
  const headers = [...(integration.value.visible_properties || [])];
  if (isHookTypeInbox.value) {
    headers.push(t('INTEGRATION_APPS.LIST.INBOX'));
  }
  headers.push(t('INTEGRATION_APPS.LIST.ACTIONS'));
  return headers;
});

const hooks = computed(() => {
  if (!hasConnectedHooks.value) {
    return [];
  }
  const { hooks: integrationHooks } = integration.value;
  const visibleProperties = integration.value.visible_properties || [];
  return integrationHooks.map(hook => ({
    ...hook,
    id: hook.id,
    properties: visibleProperties.map(property =>
      hook.settings[property] ? hook.settings[property] : '--'
    ),
  }));
});

const filteredHooks = computed(() => {
  const query = searchQuery.value?.trim() || '';
  if (!query) return hooks.value;
  const lowerQuery = query.toLowerCase();
  return (
    hooks.value?.filter(hook =>
      hook.properties?.some(prop => prop?.toLowerCase().includes(lowerQuery))
    ) || []
  );
});

const inboxName = hook => (hook.inbox ? hook.inbox.name : '');
</script>

<template>
  <div class="flex flex-col flex-1 gap-4 overflow-auto">
    <BaseSettingsHeader
      v-model:search-query="searchQuery"
      :title="integration.name || ''"
      :description="
        $t(
          `INTEGRATION_APPS.SIDEBAR_DESCRIPTION.${integration.name.toUpperCase()}`,
          { installationName: globalConfig.installationName }
        )
      "
      :feature-name="integrationId"
      :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      :search-placeholder="$t('INTEGRATION_APPS.SEARCH_PLACEHOLDER')"
    >
      <template v-if="hooks?.length" #count>
        <span class="text-body-main text-n-slate-11">
          {{ $t('INTEGRATION_APPS.COUNT', { n: hooks.length }) }}
        </span>
      </template>
      <template #actions>
        <NextButton
          v-if="showAddButton"
          :label="$t('INTEGRATION_APPS.ADD_BUTTON')"
          size="sm"
          @click="$emit('add')"
        />
      </template>
    </BaseSettingsHeader>
    <div class="w-full">
      <BaseTable
        v-if="hasConnectedHooks"
        :headers="hookHeaders"
        :items="filteredHooks"
        :no-data-message="searchQuery ? $t('INTEGRATION_APPS.NO_RESULTS') : ''"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="hook in items" :key="hook.id" :item="hook">
            <template #default>
              <BaseTableCell
                v-for="property in hook.properties"
                :key="property"
              >
                <span class="text-body-main text-n-slate-12">
                  {{ property }}
                </span>
              </BaseTableCell>

              <BaseTableCell v-if="isHookTypeInbox">
                <span class="text-body-main text-n-slate-11 break-words">
                  {{ inboxName(hook) }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end" class="w-12">
                <div class="flex justify-end gap-3 flex-shrink-0">
                  <NextButton
                    v-tooltip.top="
                      $t('INTEGRATION_APPS.LIST.DELETE.BUTTON_TEXT')
                    "
                    icon="i-woot-bin"
                    slate
                    sm
                    @click="$emit('delete', hook)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
      <p v-else class="flex flex-col items-center justify-center h-full">
        {{
          $t('INTEGRATION_APPS.NO_HOOK_CONFIGURED', {
            integrationId: integration.id,
          })
        }}
      </p>
    </div>
  </div>
</template>
