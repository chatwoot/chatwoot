<template>
  <div class="flex-1 overflow-auto">
    <router-link
      :to="addAccountScoping('settings/macros/new')"
      class="button success button--fixed-top button success button--fixed-top px-3.5 py-1 rounded-[5px] flex gap-2"
    >
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ $t('MACROS.HEADER_BTN_TXT') }}
      </span>
    </router-link>
    <div class="flex flex-row gap-4 p-8">
      <div class="w-full lg:w-3/5">
        <div v-if="!uiFlags.isFetching && !records.length" class="p-3">
          <p class="flex h-full items-center flex-col justify-center">
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
      <div class="hidden lg:block w-1/3">
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
import { useAlert } from 'dashboard/composables';
import accountMixin from 'dashboard/mixins/account.js';
import MacrosTableRow from './MacrosTableRow.vue';
export default {
  components: {
    MacrosTableRow,
  },
  mixins: [accountMixin],
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
        useAlert(this.$t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
        this.loading[this.selectedResponse.id] = false;
      } catch (error) {
        useAlert(this.$t('MACROS.DELETE.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
