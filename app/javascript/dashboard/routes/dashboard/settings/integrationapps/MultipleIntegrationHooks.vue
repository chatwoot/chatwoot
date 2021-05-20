<template>
  <div class="row content-box full-height">
    <button
      class="button nice icon success button--fixed-right-top"
      @click="openAddPopup()"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ `Add new ${integration.id}` }}
    </button>
    <div class="row">
      <div class="small-8 columns">
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="loadingMessage"
        />
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
                {{ hook.inbox_id }}
              </td>
              <td class="button-wrapper">
                <div>
                  <woot-submit-button
                    :button-text="
                      $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
                    "
                    icon-class="ion-close-circled"
                    button-class="link hollow grey-btn"
                  />
                </div>
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

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <new-hook :on-close="hideAddPopup" :integration="integration" />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :message="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import NewHook from './NewHook';

export default {
  components: {
    NewHook,
  },
  props: {
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
      selectedWebHook: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),
    headerItems() {
      return this.integration.visible_properties;
    },
    tableItems() {
      const items = [];
      if (this.integration && this.integration.hooks.length) {
        // TODO: Please change this logic
        this.integration.hooks.forEach(hook => {
          let item = { id: hook.id, inbox_id: hook.inbox_id, properties: [] };
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
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedWebHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {},
  },
};
</script>
<style scoped lang="scss">
.webhook-link {
  word-break: break-word;
}
</style>
