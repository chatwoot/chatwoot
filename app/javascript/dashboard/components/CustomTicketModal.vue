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
        @click="removeLabelFromConversation"
      />
      <!-- list of labels to add -->
      <label-dropdown
        :account-labels="accountLabels"
        :selected-labels="savedLabels"
        :allow-creation="isAdmin"
        @add="addLabelToConversation"
        @remove="removeLabelFromConversation"
      />

      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CONVERSATION.CUSTOM_TICKET.CANCEL') }}
        </woot-button>
        <woot-button>
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

export default {
  name: 'CustomTicketModal',
  components: {
    LabelDropdown,
  },
  mixins: [adminMixin, conversationLabelMixin, eventListenerMixins],
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
      labelUiFlags: 'conversationLabels/getUIFlags',
    }),
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSubmit() {
      this.$emit('submit', {
        title: this.title,
        description: this.description,
        priority: this.priority,
      });
    },
  },
};
</script>
