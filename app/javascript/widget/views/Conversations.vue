<template>
  <div class="home">
    <div class="p-4">
      <div class="flex flex-col my-2">
        <header-back-button @click="onBackButtonClick" />
        <h1 class="text-xl font-semibold text-slate-900">
          All conversations
        </h1>
        <p class="text-sm text-slate-700">
          Your previous converations with chatwoot
        </p>
      </div>
      <conversation-list :conversations="allConversations" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ConversationList from 'widget/components/ConversationList';
import HeaderBackButton from 'widget/components/HeaderBackButton';

export default {
  name: 'Conversations',
  components: {
    ConversationList,
    HeaderBackButton,
  },
  props: {},
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      user: 'contactV2/getCurrentUser',
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
