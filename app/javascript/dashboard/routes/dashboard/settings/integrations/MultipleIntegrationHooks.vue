<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
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

const { integration, isHookTypeInbox, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const globalConfig = useMapGetter('globalConfig/get');
const searchQuery = ref('');

const hookHeaders = computed(() => integration.value.visible_properties);

const hooks = computed(() => {
  if (!hasConnectedHooks.value) {
    return [];
  }
  const { hooks: integrationHooks } = integration.value;
  return integrationHooks.map(hook => ({
    ...hook,
    id: hook.id,
    properties: hookHeaders.value.map(property =>
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
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <BaseSettingsHeader
      v-model:search-query="searchQuery"
      :title="integration.name"
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
      <template #actions>
        <NextButton
          v-if="showAddButton"
          :label="$t('INTEGRATION_APPS.ADD_BUTTON')"
          @click="$emit('add')"
        />
      </template>
    </BaseSettingsHeader>
    <div class="w-full">
      <span
        v-if="!filteredHooks.length && searchQuery"
        class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
      >
        {{ $t('INTEGRATION_APPS.NO_RESULTS') }}
      </span>
      <table v-else-if="hasConnectedHooks">
        <thead
          class="[&>th]:font-semibold [&>th]:tracking-[1px] ltr:[&>th]:text-left rtl:[&>th]:text-right [&>th]:px-2.5 [&>th]:uppercase [&>th]:text-n-slate-12"
        >
          <th
            v-for="hookHeader in hookHeaders"
            :key="hookHeader"
            class="ltr:!pl-0 rtl:!pr-0 text-heading-3 text-n-slate-12 text-start"
          >
            {{ hookHeader }}
          </th>
          <th v-if="isHookTypeInbox">
            {{ $t('INTEGRATION_APPS.LIST.INBOX') }}
          </th>
        </thead>
        <tbody>
          <tr
            v-for="hook in filteredHooks"
            :key="hook.id"
            class="border-b border-n-weak [&>td]:p-2.5 [&>td]:text-n-slate-12"
          >
            <td
              v-for="property in hook.properties"
              :key="property"
              class="ltr:!pl-0 rtl:!pr-0"
            >
              {{ property }}
            </td>
            <td v-if="isHookTypeInbox" class="break-words">
              {{ inboxName(hook) }}
            </td>
            <td class="flex justify-end gap-1">
              <NextButton
                v-tooltip.top="$t('INTEGRATION_APPS.LIST.DELETE.BUTTON_TEXT')"
                icon="i-lucide-trash-2"
                xs
                ruby
                faded
                @click="$emit('delete', hook)"
              />
            </td>
          </tr>
        </tbody>
      </table>
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
