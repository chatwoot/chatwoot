<template>
  <div class="row ">
    <div class="small-8 columns">
      <p v-if="isHooksAreEmpty" class="no-items-error-message">
        {{ emptyMessage }}
      </p>

      <table v-if="!isHooksAreEmpty" class="woot-table">
        <thead>
          <th v-for="hookHeader in hookHeaders" :key="hookHeader">
            {{ hookHeader }}
          </th>
          <th v-if="checkHookTypeIsInbox">
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
            <td v-if="checkHookTypeIsInbox" class="hook-item">
              {{ inboxName(hook) }}
            </td>
            <td class="button-wrapper">
              <woot-button
                variant="link"
                color-scheme="secondary"
                icon="ion-close-circled"
                class-names="grey-btn"
                @click="deleteHook(hook)"
              >
                {{ $t('INTEGRATION.LIST.DELETE.BUTTON_TEXT') }}
              </woot-button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="small-4 columns">
      <span>
        <p>
          <b>{{ integration.name }}</b>
        </p>
        <p>
          {{ integration.description }}
        </p>
      </span>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    deleteHook: {
      type: Function,
      required: true,
    },
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
      const items = [];
      if (this.integration.hooks.length) {
        this.integration.hooks.forEach(hook => {
          let item = {
            ...hook,
            id: hook.id,
            properties: [],
          };
          this.integration.visible_properties.forEach(property => {
            item.properties.push(
              hook.settings[property] ? hook.settings[property] : '--'
            );
          });
          items.push(item);
        });
      }
      return items;
    },
    checkHookTypeIsInbox() {
      return this.integration.hook_type === 'inbox';
    },
    isHooksAreEmpty() {
      return !this.integration.hooks.length;
    },
    emptyMessage() {
      return `There are no ${this.integration.id}s configured for this account.`;
    },
  },
  methods: {
    inboxName(hook) {
      if (hook.inbox) {
        return hook.inbox.name;
      }
      return '';
    },
  },
};
</script>
<style scoped lang="scss">
.hook-item {
  word-break: break-word;
}
</style>
