<template>
  <div class="subscribers-wrap">
    <div class="subscribers--collapsed">
      <div>
        <ThumbnailGroup
          :more-thumbnails-text="
            $t('CONVERSATION_SUBSCRIBERS.REMANING_SUBSCRIBERS_TEXT', {
              agentCount: moreAgentCount,
            })
          "
          :users-list="participantList"
        />
        <woot-button
          icon="headset-add"
          size="small"
          variant="link"
          @click="onOpenDropdown"
        >
          {{ $t('CONVERSATION_SUBSCRIBERS.ADD_SUBSCRIBERS') }}
        </woot-button>
      </div>
    </div>
    <div>
      <p class="text-muted">{{ `4 people are watching` }}</p>
    </div>
    <div :class="{ 'dropdown-pane--open': showDropDown }" class="dropdown-pane">
      <div class="dropdown__header">
        <h4 class="text-block-title text-truncate">
          {{ $t('CONVERSATION_SUBSCRIBERS.ADD_SUBSCRIBERS') }}
        </h4>
        <woot-button
          icon="dismiss"
          size="tiny"
          color-scheme="secondary"
          variant="clear"
          @click="onCloseDropdown"
        />
      </div>
      <multiselect-dropdown-items
        :options="agentList"
        :selected-items="participantList"
        :has-thumbnail="true"
        @click="onClickItem"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ThumbnailGroup from 'dashboard/components/widgets/ThumbnailGroup';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems';

export default {
  components: {
    ThumbnailGroup,
    MultiselectDropdownItems,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
  },
  data() {
    return {
      selectedParticipant: [],
      userIds: [],
      showDropDown: false,
    };
  },
  computed: {
    ...mapGetters({
      participants: 'getConversationParticipants',
      agentList: 'agents/getAgents',
    }),
    participantList: {
      get() {
        return this.participants;
      },
      set(participants) {
        this.userIds = participants.map(el => el.id);
        this.updateParticipant();
      },
    },
    moreAgentCount() {
      const maxThumbnailCount = 4;
      return this.participantList.length - maxThumbnailCount;
    },
  },
  watch: {
    conversationId() {
      this.$store.dispatch('clearConversationParticipants');
      this.fetchParticipants();
    },
  },
  mounted() {
    this.fetchParticipants();
    this.$store.dispatch('agents/get');
  },
  methods: {
    fetchParticipants() {
      this.$store.dispatch(
        'fetchConversationParticipants',
        this.conversationId
      );
    },
    updateParticipant() {
      this.$store.dispatch('updateConversationParticipants', {
        conversationId: this.conversationId,
        //  Move to camel case
        user_ids: this.userIds,
      });
      this.fetchParticipants();
    },
    onOpenDropdown() {
      this.showDropDown = true;
    },
    onCloseDropdown() {
      this.showDropDown = false;
    },
    onClickItem(agent) {
      const isAgentSelected = this.participantList.some(
        participant => participant.id === agent.id
      );

      if (isAgentSelected) {
        const updatedList = this.participantList.filter(
          participant => participant.id !== agent.id
        );
        this.participantList = updatedList;
      } else {
        this.participantList = [...this.participantList, agent];
      }
    },
  },
};
</script>
<style lang="scss">
.subscribers-wrap {
  position: relative;
}
::v-deep .multiselect__tags-wrap {
  width: 100%;
  display: flex;
  margin-top: var(--zero) !important;
}
.watcher-wrap {
  display: inline-flex;
  align-items: center;
  width: auto;
  padding: 1px;
  padding-left: 5px;
  border-radius: var(--space-one);
  background: var(--s-50);
  margin: 4px 5px 5px 0px;

  p {
    margin-bottom: var(--zero);
  }
}

.thumbnail-remove {
  margin-left: var(--space-small);
}

.subscribers--collapsed {
  display: flex;
  justify-content: space-between;
}

.dropdown-pane {
  box-sizing: border-box;
  top: var(--space-minus-smaller);
  width: 100%;
}
.dropdown__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-smaller);

  .text-block-title {
    margin: 0;
  }
}
</style>
