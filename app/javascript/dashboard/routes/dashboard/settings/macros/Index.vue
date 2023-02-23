<template>
  <div class="column content-box">
    <router-link
      :to="addAccountScoping('settings/macros/new')"
      class="button success button--fixed-top"
    >
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ $t('MACROS.HEADER_BTN_TXT') }}
      </span>
    </router-link>
    <div class="row">
      <div class="small-8 columns with-right-space">
        <div
          v-if="!uiFlags.isFetching && !records.length"
          class="macros__empty-state"
        >
          <p class="no-items-error-message">
            {{ $t('MACROS.LIST.404') }}
          </p>
        </div>
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
            <macros-table-row
              v-for="(macro, index) in records"
              :key="index"
              :macro="macro"
              @delete="openDeletePopup(macro, index)"
            />
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
      :confirm-text="$t('MACROS.DELETE.CONFIRM.YES')"
      :reject-text="$t('MACROS.DELETE.CONFIRM.NO')"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from 'dashboard/mixins/account.js';
import MacrosTableRow from './MacrosTableRow';
export default {
  components: {
    MacrosTableRow,
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

<style scoped>
.macros__empty-state {
  padding: var(--space-slab);
}
</style>
