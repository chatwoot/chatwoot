<template>
  <div class="column content-box">
    <router-link
      :to="addAccountScoping('settings/macros/new')"
      class="button success button--fixed-right-top"
    >
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ $t('MACROS.HEADER_BTN_TXT') }}
      </span>
    </router-link>
    <div class="row">
      <div class="small-8 columns with-right-space">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="no-items-error-message"
        >
          {{ $t('MACROS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('MACROS.LOADING')"
        />
        <table v-if="!uiFlags.isFetching && records.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t('MACROS.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(macro, index) in records" :key="index">
              <td>{{ macro.name }}</td>
              <td>
                <div class="avatar-container">
                  <thumbnail :username="macro.created_by.name" size="24px" />
                  <span class="ml-2">{{ macro.created_by.name }}</span>
                </div>
              </td>
              <td>
                <div class="avatar-container">
                  <thumbnail :username="macro.updated_by.name" size="24px" />
                  <span class="ml-2">{{ macro.updated_by.name }}</span>
                </div>
              </td>
              <td class="macro-visibility">{{ macro.visibility }}</td>
              <td class="button-wrapper">
                <router-link
                  :to="addAccountScoping(`settings/macros/${macro.id}/edit`)"
                >
                  <woot-button
                    v-tooltip.top="$t('MACROS.FORM.EDIT')"
                    variant="smooth"
                    size="tiny"
                    color-scheme="secondary"
                    class-names="grey-btn"
                    icon="edit"
                  />
                </router-link>
                <woot-button
                  v-tooltip.top="$t('MACROS.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  @click="openDeletePopup(macro, index)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="small-4 columns">
        <span v-dompurify-html="$t('MACROS.SIDEBAR_TXT')" />
      </div>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('MACROS.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import accountMixin from 'dashboard/mixins/account.js';
export default {
  components: {
    Thumbnail,
  },
  mixins: [alertMixin, accountMixin],
  data() {
    return {
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      loading: {},
    };
  },
  computed: {
    ...mapGetters({
      records: ['macros/getMacros'],
      uiFlags: 'macros/getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('MACROS.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.name
      }`;
    },
    deleteRejectText() {
      return `${this.$t('MACROS.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.name
      }`;
    },
    deleteMessage() {
      return ` ${this.selectedResponse.name}?`;
    },
  },
  mounted() {
    this.$store.dispatch('macros/get');
  },
  methods: {
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteMacro(this.selectedResponse.id);
    },
    async deleteMacro(id) {
      try {
        await this.$store.dispatch('macros/delete', id);
        this.showAlert(this.$t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
        this.loading[this.selectedResponse.id] = false;
      } catch (error) {
        this.showAlert(this.$t('MACROS.DELETE.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<style scoped lang="scss">
.avatar-container {
  display: flex;
  align-items: center;

  span {
    margin-left: var(--space-one);
  }
}

.macro-visibility {
  text-transform: capitalize;
}
</style>
