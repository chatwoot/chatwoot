<template>
  <div
    v-if="uiFlags.isFetchingList"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size=""></spinner>
  </div>
  <list-view
    v-else-if="!isOnMessageView"
    @toggle-conversation-view="toggleConversationView"
  />
  <message-view v-else @toggle-conversation-view="toggleConversationView" />
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import configMixin from '../mixins/configMixin';
import { mapGetters } from 'vuex';
import ListView from './conversation/ListView.vue';
import MessageView from './conversation/MessageView.vue';
export default {
  name: 'Home',
  components: {
    Spinner,
    ListView,
    MessageView,
  },
  mixins: [configMixin],
  data() {
    return {
      isOnMessageView: false,
      conversationId: null,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'conversations/getUIFlags',
    }),
  },
  methods: {
    toggleConversationView(conversationId) {
      this.isOnMessageView = !this.isOnMessageView;

      if (!this.isOnMessageView) {
        this.conversationId = null;
      } else {
        this.conversationId = conversationId;
      }
    },
  },
};
</script>
