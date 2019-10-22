<template>
  <div class="conv-header">
    <div class="user">
      <Thumbnail
        :src="chat.meta.sender.thumbnail"
        size="40px"
        :badge="chat.meta.sender.channel"
      />
      <h3 class="user--name">{{chat.meta.sender.name}}</h3>
    </div>
    <div class="flex-container">
      <div class="multiselect-box ion-headphone">
        <multiselect
          v-model="currentChat.meta.assignee"
          :options="agentList"
          label="name"
          @select="assignAgent"
          :allow-empty="true"
          deselect-label="Remove"
          placeholder="Select Agent"
          selected-label=''
          select-label="Assign"
          track-by="id"
          @remove="removeAgent"
        />
      </div>
      <ResolveButton />
    </div>
  </div>


</template>
<script>

/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
/* global bus */

import { mapGetters } from 'vuex';
import Thumbnail from '../Thumbnail';
import ResolveButton from '../../buttons/ResolveButton';
import EmojiInput from '../emoji/EmojiInput';

export default {
  props: [
    'chat',
  ],

  data() {
    return {
      currentChatAssignee: null,
    };
  },

  computed: {
    ...mapGetters({
      agents: 'getVerifiedAgents',
      currentChat: 'getSelectedChat',
    }),
    agentList() {
      return [
        {
          confirmed: true,
          name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...this.agents,
      ];
    },
  },

  methods: {
    assignAgent(agent) {
      this.$store.dispatch('assignAgent', [this.currentChat.id, agent.id]).then((response) => {
        console.log('assignAgent', response);
        bus.$emit('newToastMessage', this.$t('CONVERSATION.CHANGE_AGENT'));
      });
    },

    removeAgent(agent) {
      console.log(agent.email);
    },
  },

  components: {
    Thumbnail,
    ResolveButton,
    EmojiInput,
  },
};
</script>
