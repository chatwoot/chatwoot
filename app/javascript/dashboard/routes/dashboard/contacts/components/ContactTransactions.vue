<template>
  <div class="contact-conversation--panel">
    <div
      v-if="!uiFlags.isFetchingTransactions"
      class="contact-conversation__wrap"
    >
      <div v-if="!transactions.length" class="no-label-message">
        <span>
          {{ $t('CONTACT_PANEL.TRANSACTIONS.NO_RECORDS_FOUND') }}
        </span>
      </div>
      <div v-else class="contact-conversation--list">
        <div
          v-for="transaction in transactions"
          :key="transaction.id"
          class="px-0 py-3 border-b group-hover:border-transparent flex-1 border-slate-50 dark:border-slate-800/75 w-[calc(100%-40px)]"
        >
          <div class="flex justify-between">
            <div
              class="inbox--name inline-flex items-center py-0.5 px-0 leading-3 whitespace-nowrap font-medium bg-none text-slate-600 dark:text-slate-500 text-xs my-0 mx-2.5"
            >
              {{ moreInformation(transaction) }}
            </div>
          </div>
          <h4
            class="conversation--user text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis font-medium overflow-hidden whitespace-nowrap w-[calc(100%-70px)] text-slate-900 dark:text-slate-100"
          >
            {{ transaction.product.name }}
          </h4>
          <h4
            v-if="transaction.po_value || transaction.po_note"
            class="conversation--message my-0 mx-2 leading-6 h-6 max-w-[96%] w-[16.875rem] text-sm text-slate-700 dark:text-slate-200"
          >
            {{ `${transaction.po_value} / ${transaction.po_note || ''}` }}
          </h4>
        </div>
      </div>
    </div>
    <spinner v-else />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    transactions() {
      return this.$store.getters['contacts/getTransactions'](this.contactId);
    },
  },
  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.$store.dispatch('contacts/fetchTransactions', newContactId);
      }
    },
  },
  mounted() {
    this.$store.dispatch('contacts/fetchTransactions', this.contactId);
  },
  methods: {
    moreInformation(transaction) {
      let shortName = transaction.product.short_name;
      if (
        !transaction.custom_attributes.branch &&
        !transaction.custom_attributes.expected_time
      )
        return shortName;
      return `${shortName} / ${transaction.custom_attributes.branch} / ${transaction.custom_attributes.expected_time}`;
    },
  },
};
</script>
