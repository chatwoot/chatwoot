<template>
  <div class="watchers-wrap">
    <div class="watchers--collapsed">
      <div class="content-wrap">
        <div>
          <p v-if="watchersList.length" class="total-watchers message-text">
            <spinner v-if="watchersUiFlas.isFetching" size="tiny" />
            {{ totalWatchersText }}
          </p>
          <p v-else class="text-muted message-text">
            {{ $t('CONVERSATION_PARTICIPANTS.NO_PARTICIPANTS_TEXT') }}
          </p>
        </div>
        <woot-button
          v-tooltip.left="$t('CONVERSATION_PARTICIPANTS.ADD_PARTICIPANTS')"
          :title="$t('CONVERSATION_PARTICIPANTS.ADD_PARTICIPANTS')"
          icon="settings"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          @click="onOpenDropdown"
        />
      </div>
    </div>
    <div class="actions">
      <thumbnail-group
        :more-thumbnails-text="moreThumbnailsText"
        :show-more-thumbnails-count="showMoreThumbs"
        :users-list="thumbnailList"
      />
      <p v-if="isUserWatching" class="text-muted message-text">
        {{ $t('CONVERSATION_PARTICIPANTS.YOU_ARE_WATCHING') }}
      </p>
      <woot-button
        v-else
        icon="arrow-right"
        variant="link"
        size="small"
        @click="onSelfAssign"
      >
        {{ $t('CONVERSATION_PARTICIPANTS.WATCH_CONVERSATION') }}
      </woot-button>
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
          {{ $t('CONVERSATION_PARTICIPANTS.ADD_PARTICIPANTS') }}
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
        :options="agentsList"
        :selected-items="selectedWatchers"
        :has-thumbnail="true"
        @click="onClickItem"
      />
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import Spinner from 'shared/components/Spinner';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import agentMixin from 'dashboard/mixins/agentMixin';
import ThumbnailGroup from 'dashboard/components/widgets/ThumbnailGroup';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems';

export default {
  components: {
    Spinner,
    ThumbnailGroup,
    MultiselectDropdownItems,
  },
  mixins: [alertMixin, agentMixin, clickaway],
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
      selectedWatchers: [],
      showDropDown: false,
    };
  },
  computed: {
    ...mapGetters({
      watchersUiFlas: 'conversationWatchers/getUIFlags',
      currentUser: 'getCurrentUser',
    }),
    watchersFromStore() {
      return this.$store.getters['conversationWatchers/getByConversationId'](
        this.conversationId
      );
    },
    watchersList: {
      get() {
        return this.selectedWatchers;
      },
      set(participants) {
        this.selectedWatchers = [...participants];
        const userIds = participants.map(el => el.id);
        this.updateParticipant(userIds);
      },
    },
    isUserWatching() {
      return this.selectedWatchers.some(
        watcher => watcher.id === this.currentUser.id
      );
    },
    thumbnailList() {
      return this.selectedWatchers.slice(0, 4);
    },
    moreAgentCount() {
      const maxThumbnailCount = 4;
      return this.watchersList.length - maxThumbnailCount;
    },
    moreThumbnailsText() {
      if (this.moreAgentCount > 1) {
        return this.$t('CONVERSATION_PARTICIPANTS.REMANING_PARTICIPANTS_TEXT', {
          count: this.moreAgentCount,
        });
      }
      return this.$t('CONVERSATION_PARTICIPANTS.REMANING_PARTICIPANT_TEXT', {
        count: 1,
      });
    },
    showMoreThumbs() {
      return this.moreAgentCount > 0;
    },
    totalWatchersText() {
      if (this.selectedWatchers.length > 1) {
        return this.$t('CONVERSATION_PARTICIPANTS.TOTAL_PARTICIPANTS_TEXT', {
          count: this.selectedWatchers.length,
        });
      }
      return this.$t('CONVERSATION_PARTICIPANTS.TOTAL_PARTICIPANT_TEXT', {
        count: 1,
      });
    },
  },
  watch: {
    conversationId() {
      this.fetchParticipants();
    },
    watchersFromStore(participants = []) {
      this.selectedWatchers = [...participants];
    },
  },
  mounted() {
    this.fetchParticipants();
    this.$store.dispatch('agents/get');
  },
  methods: {
    fetchParticipants() {
      const conversationId = this.conversationId;
      this.$store.dispatch('conversationWatchers/show', { conversationId });
    },
    async updateParticipant(userIds) {
      const conversationId = this.conversationId;
      let alertMessage = this.$t(
        'CONVERSATION_PARTICIPANTS.API.SUCCESS_MESSAGE'
      );

      try {
        await this.$store.dispatch('conversationWatchers/update', {
          conversationId,
          userIds,
        });
      } catch (error) {
        alertMessage =
          error?.message ||
          this.$t('CONVERSATION_PARTICIPANTS.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(alertMessage);
      }
      this.fetchParticipants();
    },
    onOpenDropdown() {
      this.showDropDown = true;
    },
    onCloseDropdown() {
      this.showDropDown = false;
    },
    onClickItem(agent) {
      const isAgentSelected = this.watchersList.some(
        participant => participant.id === agent.id
      );

      if (isAgentSelected) {
        const updatedList = this.watchersList.filter(
          participant => participant.id !== agent.id
        );

        this.watchersList = [...updatedList];
      } else {
        this.watchersList = [...this.watchersList, agent];
      }
    },
    onSelfAssign() {
      this.watchersList = [...this.selectedWatchers, this.currentUser];
    },
  },
};
</script>
<style lang="scss" scoped>
.watchers-wrap {
  position: relative;
}

.content-wrap {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-bottom: var(--space-smaller);
}

.watchers--collapsed {
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

.actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.message-text {
  margin: 0;
  font-size: var(--font-size-small);
}
</style>
