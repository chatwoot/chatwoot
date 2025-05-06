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
  emits: ['replace'],
  computed: {
    ...mapGetters({
      quickReplies: 'quickReplies/quickReplies', 
    }),
    items() {
      return this.quickReplies.map(reply => ({
        label: reply.name,   
        key: reply.name,
        description: reply.content, 
      }));
    },
  },
  watch: {
    searchKey() {
      this.fetchQuickReplies();
    },
  },
  mounted() {
    this.fetchQuickReplies();
  },
  methods: {
    fetchQuickReplies() {
      const keyword = this.searchKey.startsWith('/') ? this.searchKey.slice(1) : this.searchKey;
      this.$store.dispatch('quickReplies/get', { search: keyword });
    },
    handleMentionClick(item = {}) {
      this.$emit('replace', item.description);
    },
  },
};
</script>

<template>
  <MentionBox
    v-if="items.length"
    :items="items"
    @mention-select="handleMentionClick"
  />
</template>
