<template>
  <div class="row content-box full-height">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-add-circle"
      @click="openAddPopup()"
    >
      {{ `Add new ${integration.id}` }}
    </woot-button>

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
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.$route.params.integration_id
      );
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
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    inboxName(hook) {
      if (hook.inbox) {
        return hook.inbox.name;
      }
      return '';
    },
    async confirmDeletion() {
      try {
        await this.$store.dispatch(
          'integrations/deleteHook',
          this.selectedHook.id
        );
        this.showAlert('Hooke deleted succssfully');
        this.closeDeletePopup();
      } catch (error) {
        this.showAlert('Something went wrong');
      }
    },
  },
};
</script>
<style scoped lang="scss">
.webhook-link {
  word-break: break-word;
}
</style>
