<template>
  <div class="contact-conversation--panel">
    <contact-details-item
      icon="ion-pricetags"
      :title="$t('CONTACT_PANEL.LABELS.TITLE')"
    />
    <div v-if="!uiFlags.isFetching">
      <i v-if="!labels.length">
        {{ $t('CONTACT_PANEL.LABELS.NO_RECORDS_FOUND') }}
      </i>
      <div v-else class="contact-conversation--list">
        <span
          v-for="label in labels"
          :key="label"
          class="conversation--label label primary"
        >
          {{ label }}
        </span>
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';

export default {
  components: {
    ContactDetailsItem,
    Spinner,
  },
  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    labels() {
      return this.$store.getters['conversationLabels/getConversationLabels'](
        this.conversationId
      );
    },
    ...mapGetters({
      uiFlags: 'contactConversations/getUIFlags',
    }),
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.$store.dispatch('conversationLabels/get', newConversationId);
      }
    },
  },
  mounted() {
    this.$store.dispatch('conversationLabels/get', this.conversationId);
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact-conversation--panel {
  @include border-normal-top;
  padding: $space-medium;
}

.contact-conversation--list {
  margin-top: -$space-normal;
}

.conversation--label {
  color: $color-white;
  margin-right: $space-small;
  font-size: $font-size-small;
  padding: $space-smaller;
}
</style>
