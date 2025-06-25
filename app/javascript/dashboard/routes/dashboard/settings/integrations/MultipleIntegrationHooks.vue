<script>
import { mapGetters } from 'vuex';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
  },
  props: {
    integrationId: {
      type: String,
      required: true,
    },
    showAddButton: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['delete', 'add'],
  setup(props) {
    const { integration, isHookTypeInbox, hasConnectedHooks } =
      useIntegrationHook(props.integrationId);
    return { integration, isHookTypeInbox, hasConnectedHooks };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    hookHeaders() {
      return this.integration.visible_properties;
    },
    hooks() {
      if (!this.hasConnectedHooks) {
        return [];
      }
      const { hooks } = this.integration;
      return hooks.map(hook => ({
        ...hook,
        id: hook.id,
        properties: this.hookHeaders.map(property =>
          hook.settings[property] ? hook.settings[property] : '--'
        ),
      }));
    },
  },
  mounted() {},
  methods: {
    inboxName(hook) {
      return hook.inbox ? hook.inbox.name : '';
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <BaseSettingsHeader
      :title="integration.name"
      :description="
        $t(
          `INTEGRATION_APPS.SIDEBAR_DESCRIPTION.${integration.name.toUpperCase()}`,
          { installationName: globalConfig.installationName }
        )
      "
      :feature-name="integrationId"
      :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
    >
      <template #actions>
        <NextButton
          v-if="showAddButton"
          icon="i-lucide-circle-plus"
          :label="$t('INTEGRATION_APPS.ADD_BUTTON')"
          @click="$emit('add')"
        />
      </template>
    </BaseSettingsHeader>
    <div class="w-full">
      <table v-if="hasConnectedHooks" class="woot-table">
        <thead>
          <th
            v-for="hookHeader in hookHeaders"
            :key="hookHeader"
            class="ltr:!pl-0 rtl:!pr-0"
          >
            {{ hookHeader }}
          </th>
          <th v-if="isHookTypeInbox">
            {{ $t('INTEGRATION_APPS.LIST.INBOX') }}
          </th>
        </thead>
        <tbody>
          <tr v-for="hook in hooks" :key="hook.id">
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
