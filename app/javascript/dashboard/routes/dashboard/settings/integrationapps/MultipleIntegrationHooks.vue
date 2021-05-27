<template>
  <div class="row integration-hooks">
    <div class="small-8 columns">
      <woot-loading-state v-if="uiFlags.isFetching" :message="loadingMessage" />
      <p v-if="isHooksEmpty" class="no-items-error-message">
        {{ emptyMessage }}
      </p>

      <table v-if="isHooksExist" class="woot-table">
        <thead>
          <th v-for="thHeader in headerItems" :key="thHeader">
            {{ thHeader }}
          </th>
          <th v-if="checkHookTypeIsInbox">
            Inbox Id
          </th>
        </thead>
        <tbody>
          <tr v-for="hook in tableItems" :key="hook.id">
            <td
              v-for="property in hook.properties"
              :key="property"
              class="webhook-link"
            >
              {{ property }}
            </td>
            <td v-if="checkHookTypeIsInbox" class="webhook-link">
              {{ inboxName(hook) }}
            </td>
            <td class="button-wrapper">
              <!-- <woot-button
                  variant="link"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="ion-edit"
                >
                  Edit
                </woot-button> -->
              <woot-button
                variant="link"
                color-scheme="secondary"
                icon="ion-close-circled"
                class-names="grey-btn"
                @click="openDeletePopup(hook)"
              >
                Delete
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
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';

export default {
  props: {
    openDeletePopup: {
      type: Function,
      required: true,
    },
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
      selectedHook: {},
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),
    isIntegrationLoaded() {
      return !this.uiFlags.isFetching && !isEmptyObject(this.integration);
    },
    integrationType() {
      return this.integration.allow_multiple_hooks ? 'multiple' : 'single';
    },
    isIntegrationMultiple() {
      return this.integrationType === 'multiple';
    },
    isIntegrationSingle() {
      return this.integrationType === 'single';
    },

    showAddButton() {
      if (
        this.uiFlags.isFetching ||
        isEmptyObject(this.integration) ||
        (this.integration &&
          !this.integration.allow_multiple_hooks &&
          this.integration.hooks.length >= 1)
      ) {
        return false;
      }
      return true;
    },
    headerItems() {
      return this.integration.visible_properties;
    },
    tableItems() {
      const items = [];
      if (this.integration && this.integration.hooks.length) {
        // TODO: Please change this logic
        this.integration.hooks.forEach(hook => {
          let item = {
            ...hook,
            id: hook.id,
            properties: [],
          };
          this.integration.visible_properties.forEach(property => {
            // eslint-disable-next-line no-prototype-builtins
            if (hook.settings.hasOwnProperty(property)) {
              item.properties.push(hook.settings[property]);
            }
          });
          items.push(item);
        });
      }

      return items;
    },
    checkHookTypeIsInbox() {
      return this.integration.hook_type === 'inbox';
    },
    isHooksEmpty() {
      return (
        !this.uiFlags.isFetching &&
        !isEmptyObject(this.integration) &&
        !this.integration.hooks.length
      );
    },
    isHooksExist() {
      return (
        !this.uiFlags.isFetching &&
        !isEmptyObject(this.integration) &&
        this.integration.hooks.length
      );
    },
    emptyMessage() {
      return `There are no ${this.integration.id}s configured for this account.`;
    },
    loadingMessage() {
      return `Fetching hooks`;
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
.webhook-link {
  word-break: break-word;
}
.integration-hooks {
  width: 100%;
}
</style>
