<template>
  <unread-message-list :messages="messages" />
</template>

<script>
import { mapGetters } from 'vuex';
import UnreadMessageList from '../components/UnreadMessageList.vue';

export default {
  name: 'UnreadMessages',
  components: {
    UnreadMessageList,
  },
  computed: {
    ...mapGetters({
      messages: 'conversation/getUnreadTextMessages',
    }),
  },
};
</script>
