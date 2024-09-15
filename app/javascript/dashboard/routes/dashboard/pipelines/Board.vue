<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900 overflow-x-auto overflow-y-hidden"
  >
    <Kanban
      :statuses="statuses"
      :blocks="blocks"
      @update-block="updateStage"
      @fetch-more-data="fetchMoreData"
    >
      <div v-for="stage in stages" :slot="stage.code" :key="stage.code">
        <h2>
          <span v-tooltip.top-end="stage.description">
            {{ stageCount(stage) }}
          </span>
          <a
            v-tooltip.top-end="$t('PIPELINE_PAGE.ADD_CONTACT_TOOLTIP')"
            href=""
            @click.prevent="() => addContact(stage.id)"
            >+
          </a>
        </h2>
      </div>
      <div
        v-for="item in blocks"
        :slot="item.id"
        :key="item.id"
        @dblclick="onClickContact(item.id)"
      >
        <contact-card
          :card-data="item"
          :display-options="displayOptions"
          :selected-contact-id="selectedContactId"
        />
      </div>
    </Kanban>
    <contact-po-modal
      v-if="showContactPoModal"
      :show="showContactPoModal"
      :contact-id="movingContactId"
      @cancel="contactPoModalClosed"
      @success="contactPoModalClosed"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Kanban from '../../../components/Kanban.vue';
import timeMixin from '../../../mixins/time.js';
import contactMixin from 'dashboard/mixins/contactMixin';
import ContactPoModal from '../contacts/components/ContactPoModal.vue';
import ContactCard from './ContactCard.vue';

export default {
  components: {
    Kanban,
    ContactPoModal,
    ContactCard,
  },
  mixins: [timeMixin, contactMixin],
  props: {
    stages: {
      type: Array,
      default: null,
    },
    contacts: {
      type: Array,
      default: null,
    },
    selectedContactId: {
      type: [String, Number],
      default: '',
    },
    displayOptions: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      movingContactId: '',
      showContactPoModal: false,
      statuses: [],
      blocks: [],
    };
  },
  computed: {
    ...mapGetters({
      stageMeta: 'contacts/getStageMeta',
    }),
  },
  watch: {
    stages() {
      this.loadStatuses();
    },
    contacts() {
      this.syncBlockItems();
    },
  },
  methods: {
    fetchMoreData(status) {
      this.$emit('fetch-more-data', status);
    },
    loadStatuses() {
      this.statuses = this.stages.map(item => item.code);
    },
    stageCount(stage) {
      const count = this.stageMeta[stage.code]?.count;
      return count ? `${stage.name} (${count})` : stage.name;
    },
    syncBlockItems() {
      this.contacts.forEach(contact => {
        if (!contact.stage?.id) return;

        const stage = this.stages.find(item => item.id === contact.stage.id);
        if (!stage) return;

        const contactInBlock = {
          id: contact.id,
          status: stage.code,
          title: contact.name,
          assignee: contact.assignee?.name,
          product: contact.product?.name,
          productShortName: contact.product?.short_name,
          lastNote: contact.last_note,
          currentActionText: this.currentConversationPlanText(
            contact.conversation_plans
          ),
          lastActivityAt: contact.last_activity_at,
          formattedStageChangedAt: contact.last_stage_changed_at
            ? this.dynamicTime(contact.last_stage_changed_at)
            : null,
          formattedLastActivityAt: contact.last_activity_at
            ? this.dynamicTime(contact.last_activity_at)
            : null,
        };

        const index = this.blocks.findIndex(item => item.id === contact.id);
        if (index >= 0) this.blocks.splice(index, 1);
        this.blocks.push(contactInBlock);
      });
      this.blocks = this.blocks.filter(block =>
        this.contacts.some(contact => contact.id === block.id)
      );
    },

    onClickContact(contactId) {
      this.$emit('on-selected-contact', contactId);
    },

    updateStage(id, status) {
      this.movingContactId = id;
      const stage = this.stages.find(item => item.code === status);
      const contactItem = { id, stage_id: stage.id };

      if (stage.code === 'Won') this.showContactPoModal = true;
      else this.$store.dispatch('contacts/update', contactItem);
    },

    addContact(stageId) {
      this.$emit('add-contact-click', stageId);
    },

    contactPoModalClosed() {
      const stage = this.stages.find(item => item.code === 'Won');
      const contactItem = { id: this.movingContactId, stage_id: stage.id };
      this.$store.dispatch('contacts/update', contactItem);

      this.showContactPoModal = !this.showContactPoModal;
    },
  },
};
</script>

<style lang="scss">
@import '../../../assets/scss/kanban.scss';

* {
  box-sizing: border-box;
}

.drag-item-selection {
  @apply bg-white dark:bg-black-600;
}

.drag-column {
  .drag-column-header > div {
    width: 100%;
    h2 > a {
      float: right;
    }
  }

  .drag-column-footer > div {
    margin-left: 10px;
    a {
      text-decoration: none;
      color: white;
      &:hover {
        text-decoration: underline;
      }
    }
  }

  $status-colors: (
    New: #c89e07,
    Contacting: #bbc807,
    Converted: #78c807,
    Unqualified: #5b4b1f,
    Prospecting: #c89e07,
    Qualified: #478ad1,
    Working: #2a92bf,
    Closure: #09918f,
    Won: #00b961,
    Lost: #5b4b1f,
    Care: #ef7538,
    Old: #c89e07,
  );

  @each $status, $color in $status-colors {
    &-#{$status} {
      .drag-column-header,
      .is-moved,
      .drag-options {
        background: $color;
      }
    }
  }
}

.section {
  padding: 20px;
  text-align: center;

  a {
    color: white;
    text-decoration: none;
    font-weight: 300;
  }

  h4 {
    font-weight: 400;
    a {
      font-weight: 600;
    }
  }
}
</style>
