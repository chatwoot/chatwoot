<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';

export default {
  components: { MentionBox },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      cannedMessages: 'getCannedResponses',
    }),
    items() {
      return this.cannedMessages.map(cannedMessage => ({
        label: cannedMessage.short_code,
        key: cannedMessage.short_code,
        description: cannedMessage.content,
      }));
    },
  },
  watch: {
    searchKey() {
      this.fetchCannedResponses();
    },
  },
  mounted() {
    this.fetchCannedResponses();
  },
  methods: {
    fetchCannedResponses() {
      this.$store.dispatch('getCannedResponse', { searchKey: this.searchKey });
    },
    handleMentionClick(item = {}) {
      this.$emit('click', item.description);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <MentionBox
    v-if="items.length"
    :items="items"
    @mentionSelect="handleMentionClick"
  />
</template>
