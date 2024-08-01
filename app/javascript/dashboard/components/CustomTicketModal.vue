<template>
  <div class="flex flex-col">
    <woot-modal-header
      :header-title="$t('CONVERSATION.CUSTOM_TICKET.TITLE')"
      :header-content="$t('CONVERSATION.CUSTOM_TICKET.SUBTITLE')"
    />
    <form class="w-full flex flex-col" @submit.prevent="onSubmit">
      <!-- name -->
      <woot-input
        v-model.trim="title"
        class="columns"
        :label="$t('CONVERSATION.CUSTOM_TICKET.NAME')"
        :placeholder="$t('CONVERSATION.CUSTOM_TICKET.NAME_PLACEHOLDER')"
        @blur="title.$touch"
      />
      <!-- description -->
      <woot-input
        v-model.trim="description"
        class="columns"
        :label="$t('CONVERSATION.CUSTOM_TICKET.DESCRIPTION')"
        :placeholder="$t('CONVERSATION.CUSTOM_TICKET.DESCRIPTION_PLACEHOLDER')"
        @blur="description.$touch"
      />
      <!-- labels -->
      <woot-label
        v-for="label in activeLabels"
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :show-close="true"
        :color="label.color"
        variant="smooth"
        @click="removeLabelFromTicket"
      />
      <!-- list of labels to add -->
      <label-dropdown
        :account-labels="accountLabels"
        :selected-labels="savedLabels"
        :allow-creation="isAdmin"
        @add="addLabelToTicket"
        @remove="removeLabelFromTicket"
      />

      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CONVERSATION.CUSTOM_TICKET.CANCEL') }}
        </woot-button>
        <woot-button :is-loading="ticketUIFlags.isCreating">
          {{ $t('CONVERSATION.CUSTOM_TICKET.CREATE') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import adminMixin from 'dashboard/mixins/isAdmin';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  name: 'CustomTicketModal',
  components: {
    LabelDropdown,
  },
  mixins: [adminMixin, conversationLabelMixin, eventListenerMixins, alertMixin],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      description: '',
      priority: '',
    };
  },
  computed: {
    ...mapGetters({
      conversationUiFlags: 'conversationLabels/getUIFlags',
      ticketUIFlags: 'tickets/getUIFlags',
    }),
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSubmit() {
      this.$store
        .dispatch('tickets/create', {
          title: this.title,
          description: this.description,
          conversationId: this.conversationId,
        })
        .then(() => {
          this.showAlert(this.$t('CONVERSATION.CUSTOM_TICKET.SUCCESS_MESSAGE'));
          this.onClose();
        })
        .catch(() => {
          this.showAlert(this.$t('CONVERSATION.CUSTOM_TICKET.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
