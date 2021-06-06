<template>
  <div class="row ">
    <div class="small-8 columns">
      <table v-if="hasConnectedHooks" class="woot-table">
        <thead>
          <th v-for="hookHeader in hookHeaders" :key="hookHeader">
            {{ hookHeader }}
          </th>
          <th v-if="isHookTypeInbox">
            {{ $t('INTEGRATION.LIST.INBOX') }}
          </th>
        </thead>
        <tbody>
          <tr v-for="hook in hooks" :key="hook.id">
            <td
              v-for="property in hook.properties"
              :key="property"
              class="hook-item"
            >
              {{ property }}
            </td>
            <td v-if="isHookTypeInbox" class="hook-item">
              {{ inboxName(hook) }}
            </td>
            <td class="button-wrapper">
              <woot-button
                variant="link"
                color-scheme="secondary"
                icon="ion-close-circled"
                class-names="grey-btn"
                @click="$emit('delete', hook)"
              >
                {{ $t('INTEGRATION.LIST.DELETE.BUTTON_TEXT') }}
              </woot-button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="no-items-error-message">
        {{
          $t('INTEGRATION.NO_HOOK_CONFIGURED', {
            integrationId: integration.id,
          })
        }}
      </p>
    </div>
    <div class="small-4 columns">
      <p>
        <b>{{ integration.name }}</b>
      </p>
      <p>
        {{ integration.description }}
      </p>
    </div>
  </div>
</template>
<script>
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
  methods: {
    inboxName(hook) {
      return hook.inbox ? hook.inbox.name : '';
    },
  },
};
</script>
<style scoped lang="scss">
.hook-item {
  word-break: break-word;
}
</style>
