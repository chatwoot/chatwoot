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
  emits: ['replace', 'cannedSelected'],
  data() {
    return {
      selectedCannedResponse: null,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      cannedMessages: 'getCannedResponses',
    }),
    items() {
      return this.cannedMessages.map(cannedMessage => ({
        label: cannedMessage.short_code,
        key: cannedMessage.short_code,
        description: cannedMessage.content,
        id: cannedMessage.id,
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
      const inboxId = this.currentChat.inbox_id;
      this.$store.dispatch('getCannedResponse', {
        searchKey: this.searchKey,
        inboxId,
      });
    },
    handleMentionClick(item = {}) {
      this.selectedCannedResponse = item;
      this.$emit('replace', item.description);
      this.$emit('cannedSelected', item.id);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <MentionBox
    v-if="items.length"
    :items="items"
    @mention-select="handleMentionClick"
  />
</template>
