<template>
  <div class="flex flex-1 items-center h-full bg-black-25 justify-center">
    {{ JSON.stringify(allConversations) }}
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  name: 'Conversations',
  components: {},
  props: {},
  data() {
    return {};
  },
  mountd() {
    this.$store.dispatch('contactV2/get', { inboxIdentifier: '', user: {} });
  },
  computed: {
    ...mapGetters({
      allConversations: 'conversationV2/allConversations',
    }),
  },
  mounted() {},
};
</script>
