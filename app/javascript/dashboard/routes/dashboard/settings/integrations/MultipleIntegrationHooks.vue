<template>
  <div class="flex flex-row gap-4">
    <div class="w-full lg:w-3/5">
      <table v-if="hasConnectedHooks" class="woot-table">
        <thead>
          <th v-for="hookHeader in hookHeaders" :key="hookHeader">
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
              class="break-words"
            >
              {{ property }}
            </td>
            <td v-if="isHookTypeInbox" class="break-words">
              {{ inboxName(hook) }}
            </td>
            <td class="flex justify-end gap-1">
              <woot-button
                v-tooltip.top="$t('INTEGRATION_APPS.LIST.DELETE.BUTTON_TEXT')"
                variant="smooth"
                color-scheme="alert"
                size="tiny"
                icon="dismiss-circle"
                class-names="grey-btn"
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
    <div class="hidden w-1/3 lg:block">
      <p>
        <b>{{ integration.name }}</b>
      </p>
      <p
        v-dompurify-html="
          $t(
            `INTEGRATION_APPS.SIDEBAR_DESCRIPTION.${integration.name.toUpperCase()}`,
            { installationName: globalConfig.installationName }
          )
        "
      />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import hookMixin from './hookMixin';
export default {
  mixins: [hookMixin],
  props: {
    integration: {
      type: Object,
      default: () => ({}),
    },
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
