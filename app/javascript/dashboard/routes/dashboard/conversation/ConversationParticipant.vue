<template>
  <div>
    <multiselect
      v-model="participantList"
      :options="agentList"
      track-by="id"
      label="name"
      :multiple="true"
      :close-on-select="false"
      :clear-on-select="false"
      :hide-selected="true"
      placeholder="Choose Participants"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
    >
      <template slot="tag" slot-scope="props">
        <div class="watcher-wrap">
          <thumbnail
            :src="props.option.thumbnail"
            :username="props.option.name"
            size="18px"
            class="margin-right-small"
          />
          <p style="font-size: 12px">{{ props.option.name }}</p>
          <woot-button
            class-names="thumbnail-remove"
            variant="clear"
            size="tiny"
            icon="dismiss"
            color-scheme="secondary"
            @click="props.remove(props.option)"
          />
        </div>
      </template>
    </multiselect>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
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
      user_ids: [],
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
        this.user_ids = participants.map(el => el.id);
        this.updateParticipant();
      },
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
        user_ids: this.user_ids,
      });
      this.fetchParticipants();
    },
  },
};
</script>
<style lang="scss">
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
</style>
