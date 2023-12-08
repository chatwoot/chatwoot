<template>
  <div class="flex flex-col bg-slate-25 flex-1 review-container">
    <div class="p-4 h-16 fixed top-0 w-full border-b border-slate-100 bg-white">
      <h1 class="text-base font-semibold leading-6 text-gray-900">
        Conversations
        <span v-if="conversationsToDisplay.length" class="text-sm">
          ({{ conversationsToDisplay.length }})
        </span>
      </h1>
    </div>
    <div class="flex-1 pt-16 flex overflow-hidden">
      <virtual-list
        :keeps="100"
        :data-key="'id'"
        :data-sources="conversationsToDisplay"
        :data-component="itemComponent"
        class="w-full overflow-auto"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ReviewItem from './ReviewItem.vue';
import VirtualList from 'vue-virtual-scroll-list';
// import ReviewFilters from './ReviewFilters.vue';

export default {
  components: {
    VirtualList,
    // ReviewFilters,
  },
  data() {
    return {
      itemComponent: ReviewItem,
    };
  },

  computed: {
    ...mapGetters({
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
      accountLabels: 'labels/getLabels',
      conversations: 'reviewConversations/getAll',
      contacts: 'reviewContacts/getAll',
      messages: 'reviewMessages/getGroupedAll',
    }),
    conversationsToDisplay() {
      return this.conversations.map(conversation => {
        const labels = this.accountLabels.filter(({ title }) =>
          conversation.labels.includes(title)
        );
        const contact = this.contacts[conversation.contactId];
        const assignee = this.agents.find(
          agent => agent.id === conversation.assigneeId
        );
        const lastMessage = this.messages[conversation.id];
        return {
          ...conversation,
          assignee,
          contact,
          labels,
          lastMessage,
        };
      });
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('agents/get');
    this.$store.dispatch('teams/get');
    this.$store.dispatch('labels/get');
    this.$store.dispatch('reviewConversations/bootstrap');
    this.$store.dispatch('reviewConversations/labelsBootstrap');
    this.$store.dispatch('reviewContacts/bootstrap');
    this.$store.dispatch('reviewMessages/bootstrap');
  },
  methods: {},
};
</script>

<style>
.review-container {
  font-family:
    Inter,
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    Oxygen,
    Ubuntu,
    Cantarell,
    'Open Sans',
    'Helvetica Neue',
    sans-serif;
}
</style>
