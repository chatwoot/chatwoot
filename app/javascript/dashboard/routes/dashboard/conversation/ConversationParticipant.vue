<template>
  <div class="subscribers-wrap">
    <div class="subscribers--collapsed">
      <div class="content-wrap">
        <div>
          <ThumbnailGroup
            :more-thumbnails-text="
              $t('CONVERSATION_WATCHERS.REMANING_WATCHERS_TEXT', {
                agentCount: moreAgentCount,
              })
            "
            :users-list="participantList"
          />
        </div>
        <woot-button
          v-tooltip.top-end="$t('CONVERSATION_WATCHERS.ADD_WATCHERS')"
          :title="$t('CONVERSATION_WATCHERS.ADD_WATCHERS')"
          icon="settings"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          @click="onOpenDropdown"
        />
      </div>
    </div>
    <div>
      <p class="total-watchers">
        {{
          $t('CONVERSATION_WATCHERS.TOTAL_WATCHERS_TEXT', {
            count: selectedParticipants.length,
          })
        }}
      </p>
    </div>
    <div
      v-on-clickaway="
        () => {
          onCloseDropdown();
        }
      "
      :class="{ 'dropdown-pane--open': showDropDown }"
      class="dropdown-pane"
    >
      <div class="dropdown__header">
        <h4 class="text-block-title text-truncate">
          {{ $t('CONVERSATION_WATCHERS.ADD_WATCHERS') }}
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
        :selected-items="selectedParticipants"
        :has-thumbnail="true"
        @click="onClickItem"
      />
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import ThumbnailGroup from 'dashboard/components/widgets/ThumbnailGroup';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems';

export default {
  components: {
    ThumbnailGroup,
    MultiselectDropdownItems,
  },
  mixins: [clickaway],
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
      selectedParticipants: [],
      showDropDown: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
    participantsFromStore() {
      return this.$store.getters['conversationWatchers/getByConversationId'](
        this.conversationId
      );
    },
    participantList: {
      get() {
        return this.selectedParticipants;
      },
      set(participants) {
        this.selectedParticipants = [...participants];
        const userIds = participants.map(el => el.id);
        this.updateParticipant(userIds);
      },
    },
    moreAgentCount() {
      const maxThumbnailCount = 4;
      return this.participantList.length - maxThumbnailCount;
    },
  },
  watch: {
    conversationId() {
      this.$store.dispatch('conversationWatchers/clear');
      this.fetchParticipants();
    },
    participantsFromStore(participants) {
      this.selectedParticipants = [...participants];
    },
  },
  mounted() {
    this.fetchParticipants();
    this.$store.dispatch('agents/get');
  },
  methods: {
    fetchParticipants() {
      this.$store.dispatch('conversationWatchers/show', this.conversationId);
    },
    async updateParticipant(userIds) {
      await this.$store.dispatch('conversationWatchers/update', {
        conversationId: this.conversationId,
        //  Move to camel case
        user_ids: userIds,
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

        this.participantList = [...updatedList];
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

.content-wrap {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-bottom: var(--space-smaller);
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

.total-watchers {
  font-size: var(--font-size-small);
  color: var(--s-600);
}
.subscribers--collapsed {
  display: flex;
  justify-content: space-between;
}

.dropdown-pane {
  box-sizing: border-box;
  top: var(--space-large);
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
