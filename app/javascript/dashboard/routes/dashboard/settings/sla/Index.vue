<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ $t('SLA.HEADER_BTN_TXT') }}
    </woot-button>
    <div class="flex flex-row gap-4">
      <div class="w-[60%]">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="flex h-full items-center flex-col justify-center"
        >
          {{ $t('SLA.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('SLA.LOADING')"
        />
        <table v-if="!uiFlags.isFetching && records.length" class="woot-table">
          <thead>
            <th v-for="thHeader in $t('SLA.LIST.TABLE_HEADER')" :key="thHeader">
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="sla in records" :key="sla.title">
              <td>
                <span
                  class="inline-block overflow-hidden whitespace-nowrap text-ellipsis"
                >
                  {{ sla.name }}
                </span>
              </td>
              <td>{{ sla.description }}</td>
              <td>
                <span class="flex items-center">
                  {{ sla.first_response_time_threshold }}
                </span>
              </td>
              <td>
                <span class="flex items-center">
                  {{ sla.next_response_time_threshold }}
                </span>
              </td>
              <td>
                <span class="flex items-center">
                  {{ sla.resolution_time_threshold }}
                </span>
              </td>
              <td>
                <span class="flex items-center">
                  {{ sla.only_during_business_hours }}
                </span>
              </td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('SLA.FORM.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  :is-loading="loading[sla.id]"
                  icon="edit"
                  @click="openEditPopup(sla)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="w-[34%]">
        <span v-dompurify-html="$t('SLA.SIDEBAR_TXT')" />
      </div>
    </div>
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-SLA @close="hideAddPopup" />
    </woot-modal>

    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-SLA :selected-response="selectedResponse" @close="hideEditPopup" />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import AddSLA from './AddSLA.vue';
import EditSLA from './EditSLA.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    AddSLA,
    EditSLA,
  },
  mixins: [alertMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      selectedResponse: {},
    };
  },
  computed: {
    ...mapGetters({
      records: 'sla/getSLA',
      uiFlags: 'sla/getUIFlags',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    isSLAEnabled() {
      return this.isFeatureEnabledonAccount(this.accountId, 'sla');
    },
  },
  mounted() {
    this.isSLAfeatureEnabled();
  },
  methods: {
    isSLAfeatureEnabled() {
      if (!this.isSLAEnabled) {
        this.$router.push({
          name: 'general_settings_index',
        });
      } else {
        this.$store.dispatch('sla/get');
      }
    },
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openEditPopup(response) {
      this.showEditPopup = true;
      this.selectedResponse = response;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
  },
};
</script>
