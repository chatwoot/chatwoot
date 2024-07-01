<template>
  <div class="flex flex-col" @key.esc="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION.HEADER.CONVERSATION_LABELS.TITLE')"
    />
    <form class="w-full" @submit.prevent="addTag">
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
      <woot-button>
        {{ $t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import { mixin as clickaway } from 'vue-clickaway';
import adminMixin from 'dashboard/mixins/isAdmin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';

export default {
  name: 'CustomLabelModal',
  components: {
    LabelDropdown,
  },
  mixins: [clickaway, conversationLabelMixin, adminMixin, eventListenerMixins],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      tag: '',
      selectedLabels: [],
      showSearchDropdownLabel: false,
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
    addTag() {
      this.$emit('add-tag', this.tag);
    },
    removeLabelFromConversation(label) {
      // Implementar a lógica de remoção de label
      // eslint-disable-next-line no-console
      console.log(label);
    },
    addLabelToConversation(label) {
      // Implementar a lógica de adição de label
      // eslint-disable-next-line no-console
      console.log(label);
    },
    handleKeyEvents(e) {
      const keyPattern = buildHotKeys(e);

      if (keyPattern === 'escape') {
        this.onClose();
      }
    },
  },
};
</script>

<style lang="scss" scoped></style>
