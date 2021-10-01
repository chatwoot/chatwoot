<template>
  <div class="home">
    <div class="p-4">
      <div class="flex items-center mt-2">
        <button
          type="button"
          class="inline-flex items-center px-2 py-2 border-transparent text-sm leading-4 font-medium rounded-md text-black-900 hover:bg-black-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-woot-200"
          @click="onBackButtonClick"
        >
          <!-- Heroicon name: solid/mail -->
          <svg
            class="w-5 h-5"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M15.5303 4.21967C15.8232 4.51256 15.8232 4.98744 15.5303 5.28033L8.81066 12L15.5303 18.7197C15.8232 19.0126 15.8232 19.4874 15.5303 19.7803C15.2374 20.0732 14.7626 20.0732 14.4697 19.7803L7.21967 12.5303C6.92678 12.2374 6.92678 11.7626 7.21967 11.4697L14.4697 4.21967C14.7626 3.92678 15.2374 3.92678 15.5303 4.21967Z"
              fill="#212121"
            />
          </svg>
        </button>
        <h1 class="text-xl font-semibold ml-1">All conversations</h1>
      </div>
      <conversation-list :conversations="allConversations" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ConversationList from 'widget/components/ConversationList';

export default {
  name: 'Conversations',
  components: {
    ConversationList,
  },
  props: {},
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      user: 'contacts/getCurrentUser',
      allConversations: 'conversationV2/allConversations',
    }),
  },
  methods: {
    onBackButtonClick() {
      this.$router.back();
    },
  },
};
</script>
<style lang="scss" scoped>
.home {
  @apply h-full;
}
</style>
