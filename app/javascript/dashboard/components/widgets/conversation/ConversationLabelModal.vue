<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="'Resolve Conversation'"
        :header-content="'Select a label and add label to the conversation to resolve'"
      />
      <div class="w-full form-container">
        <woot-label
          v-for="label in filteredActiveLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :show-close="
            ![
              'calling-nudge',
              'pre-sale-query',
              'support-query',
              'inbound-call',
              'missed-call',
            ].includes(label.title)
          "
          :color="label.color"
          variant="smooth"
          class="max-w-[calc(100%-0.5rem)]"
          @click="removeLabel"
        />
        <label-dropdown
          :account-labels="filteredAccountLabels"
          :selected-labels="filteredSavedLabels"
          :allow-creation="showAddLabel"
          :is-change-style="true"
          @add="addLabel"
          @remove="removeLabel"
        />
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <woot-button @click="onSubmit"> Submit </woot-button>
          <button class="button clear" @click.prevent="onCancel">
            {{ $t('EMAIL_TRANSCRIPT.CANCEL') }}
          </button>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
export default {
  name: 'ConversationLabelModal',
  components: {
    LabelDropdown,
  },
  mixins: [conversationLabelMixin, alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedLabels: [],
    };
  },
  // validations: {
  //   email: {
  //     required,
  //     email,
  //     minLength: minLength(4),
  //   },
  // },
  computed: {
    ...mapGetters({
      conversationUiFlags: 'conversationLabels/getUIFlags',
      labelUiFlags: 'conversationLabels/getUIFlags',
      accountId: 'getCurrentAccountId',
      getAccount: 'accounts/getAccount',
    }),
    filteredActiveLabels() {
      return this.selectedLabels;
    },
    conversationId() {
      return this.currentChat.id;
    },
    filteredAccountLabels() {
      return this.accountLabels.filter(
        label =>
          label.title !== 'calling-nudge' &&
          label.title !== 'pre-sale-query' &&
          label.title !== 'support-query' &&
          label.title !== 'inbound-call' &&
          label.title !== 'missed-call'
      );
    },
    filteredSavedLabels() {
      return this.selectedLabels.filter(
        label =>
          label.title !== 'calling-nudge' &&
          label.title !== 'pre-sale-query' &&
          label.title !== 'support-query' &&
          label.title !== 'inbound-call' &&
          label.title !== 'missed-call'
      );
    },
    showAddLabel() {
      const currentAccount = this.getAccount(this.accountId);
      if (currentAccount?.custom_attributes?.show_label_to_agent) {
        return true;
      }
      return this.isAdmin;
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    removeLabel(value) {
      this.selectedLabels = this.selectedLabels.filter(
        label => label.title !== value
      );
    },
    addLabel(value) {
      if (!this.selectedLabels.includes(value)) {
        this.selectedLabels.push(value);
      }
    },
    async onSubmit() {
      this.isSubmitting = true;
      if (this.selectedLabels.length === 0) {
        this.showAlert(this.$t('Select One Label'));
        return;
      }
      try {
        const result = this.selectedLabels.map(label => label.title);
        await this.onUpdateLabels(result);
        this.showAlert('Conversation Label Added successfully');
        this.onCancel();
        this.$emit('submit');
      } catch (error) {
        this.showAlert('Error Updating Conversation Label');
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<style>
.form-container {
  align-self: center;
  padding-left: 2rem;
  padding-right: 2rem;
  padding-top: 1rem;
  padding-bottom: 2rem;
}
</style>
