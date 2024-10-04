<template>
  <div class="modal-mask">
    <div
      v-on-clickaway="closeUponClickAway"
      ref="container"
      class="new-ticket-container flex-col h-[90vh] w-[45rem] flex justify-between z-10 rounded-md shadow-md absolute bg-white dark:bg-slate-800 left-14 rtl:left-auto rtl:right-14 m-4"
    >
      <div
        class="flex-row items-center border-b border-solid pt-5 pb-3 px-6 border-slate-50 dark:border-slate-700 w-full flex justify-between"
      >
        <div class="items-center flex">
          <span class="text-xl font-bold text-slate-800 dark:text-slate-100">
            {{ $t('TICKET.NEW.TITLE') }}
          </span>
        </div>
      </div>
      <div class="flex-col py-2 px-2.5 overflow-auto h-full flex">
        <div class="py-4 px-1 ml-0 mr-0">
          <new-ticket-form ref="ticketForm" @close-panel="closePanel"/>
        </div>
        <button type="submit" class="button success mb-5" @click="submitForm">
          <span class="button__content">
            Create
          </span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import NewTicketForm from './NewTicketForm.vue'

export default {
  components: {
    NewTicketForm
  },
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    
  },
  methods: {
    closeUponClickAway(event) {
      if (event.target.classList.contains('modal-mask')) {
        this.closePanel()
      }
    },

    closePanel() {
      this.$emit('close');
    },

    submitForm() {
      this.$refs.ticketForm.submitForm()
    }
  },
};
</script>
<style>
  .new-ticket-container .ProseMirror-menubar{
    margin-left: 5px;
  }
  </style>