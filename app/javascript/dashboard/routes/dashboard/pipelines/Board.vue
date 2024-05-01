<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <Kanban :statuses="statuses" :blocks="blocks" @update-block="updateStage">
      <div v-for="stage in stages" :slot="stage.code" :key="stage.code">
        <h2>
          {{ stage.name }}
          <a href="" @click.prevent="() => addContact(stage.id)">+</a>
        </h2>
      </div>
      <div
        v-for="item in blocks"
        :slot="item.id"
        :key="item.id"
        @dblclick="onClickContact(item.id)"
      >
        <div>
          <div
            :class="{
              'text-woot-600 dark:text-woot-600': selectedContactId == item.id,
            }"
          >
            <strong>{{ item.title }}</strong>
          </div>
          <div>{{ item.formattedUpdatedAt }}</div>
          id: {{ item.id }}
        </div>
      </div>
    </Kanban>
  </div>
</template>

<script>
import Kanban from '../../../components/Kanban.vue';
import timeMixin from '../../../mixins/time.js';

export default {
  components: {
    Kanban,
  },
  mixins: [timeMixin],
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
  },
  data() {
    return {
      statuses: [],
      blocks: [],
    };
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
    loadStatuses() {
      this.statuses = this.stages.map(item => item.code);
    },

    syncBlockItems() {
      this.contacts.forEach(contact => {
        if (!contact.stage_id) return;

        const stage = this.stages.find(item => item.id === contact.stage_id);
        if (!stage) return;

        const contactInBlock = {
          id: contact.id,
          status: stage.code,
          title: contact.name,
          updatedAt: contact.updated_at,
          formattedUpdatedAt: this.dateFormat(
            contact.updated_at,
            'dd/MM hh:mm'
          ),
        };

        const index = this.blocks.findIndex(item => item.id === contact.id);
        if (index >= 0) this.blocks.splice(index, 1);
        this.blocks.push(contactInBlock);
      });
      this.blocks = this.blocks.filter(block =>
        this.contacts.some(contact => contact.id === block.id)
      );
      this.blocks.sort((a, b) => {
        return b.updatedAt - a.updatedAt;
      });
    },

    onClickContact(contactId) {
      this.$emit('on-selected-contact', contactId);
    },

    async updateStage(id, status) {
      const stage = this.stages.find(item => item.code === status);
      const contactItem = { id, stage_id: stage.id };
      await this.$store.dispatch('contacts/update', contactItem);
    },

    addContact(stageId) {
      this.$emit('add-contact-click', stageId);
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
