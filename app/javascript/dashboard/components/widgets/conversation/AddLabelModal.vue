<template>
  <div class="flex flex-col" @key.esc="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION.HEADER.CONVERSATION_LABELS.TITLE')"
      :header-content="$t('CONVERSATION.HEADER.CONVERSATION_LABELS.DESC')"
    />
    <form class="w-full" @submit.prevent>
      <!-- to show the labels in the modal -->
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
    </form>
    <div class="flex flex-row justify-end gap-4 w-full pr-2 pb-2">
      <woot-button variant="clear" @click.prevent="onClose">
        {{ $t('CONVERSATION.HEADER.CONVERSATION_LABELS.CANCEL') }}
      </woot-button>
      <woot-button @click.prevent="onSubmit">
        {{ $t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import adminMixin from 'dashboard/mixins/isAdmin';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';

export default {
  name: 'CustomLabelModal',
  components: {
    LabelDropdown,
  },
  mixins: [adminMixin, conversationLabelMixin, eventListenerMixins],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
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
      this.$emit('submit');
    },
  },
};
</script>
