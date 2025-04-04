<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="h-auto overflow-auto flex flex-col bg-white dark:bg-slate-900">
      <woot-modal-header :header-title="'Add Call Log'" />
      <call-log-form
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import CallLogForm from './CallLogForm.vue';
import ContactAPI from 'dashboard/api/contacts';

export default {
  components: {
    CallLogForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(data) {
      await ContactAPI.createCallLog(data);
    },
  },
};
</script>
