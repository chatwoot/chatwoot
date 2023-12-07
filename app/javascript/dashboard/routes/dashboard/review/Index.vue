<template>
  <div class="flex flex-col bg-slate-25 flex-1 overflow-auto">
    <div class="p-4 fixed top-0 w-full border-b border-slate-100 bg-white">
      <div class="sm:flex-auto">
        <h1 class="text-base font-semibold leading-6 text-gray-900">
          Conversations
          <span v-if="conversationsToDisplay.length" class="text-sm">
            ({{ conversationsToDisplay.length }})
          </span>
        </h1>
      </div>
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

export default {
  components: {
    VirtualList,
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
    }),
    conversationsToDisplay() {
      return this.conversations.map(conversation => {
        const labels = this.accountLabels.filter(({ title }) =>
          conversation.labels.includes(title)
        );
        return {
          ...conversation,
          labels,
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
  },
  methods: {},
};
</script>
