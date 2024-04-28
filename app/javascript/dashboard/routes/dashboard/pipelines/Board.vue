<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <Kanban :statuses="statuses" :blocks="blocks" @update-block="updateBlock">
      <div v-for="stage in stages" :slot="stage.code" :key="stage.code">
        <h2>
          {{ stage.name }}
          <a href="" @click.prevent="() => addBlock(stage.code)">+</a>
        </h2>
      </div>
      <div v-for="item in blocks" :slot="item.id" :key="item.id">
        <div>
          <div>
            <strong>{{ item.title }}</strong>
          </div>
          <div>{{ item.lastActivityAt }}</div>
          id: {{ item.id }}
        </div>
      </div>
    </Kanban>
  </div>
</template>

<script>
import faker from 'faker';
import { debounce } from 'lodash';
import Kanban from '../../../components/Kanban.vue';
import boardsAPI from '../../../api/boards.js';
import { format } from 'date-fns';

export default {
  components: {
    Kanban,
  },
  props: {
    selectedStageType: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      statuses: [],
      stages: [],
      blocks: [],
    };
  },
  watch: {
    selectedStageType() {
      this.loadBoard();
    },
  },

  methods: {
    loadBoard() {
      const stageType = this.selectedStageType.value;
      boardsAPI.get().then(response => {
        const stagesByType = response.data.filter(
          item =>
            stageType === 'both' ||
            item.stage_type === 'both' ||
            item.stage_type === stageType
        );
        this.stages = stagesByType;
        this.statuses = stagesByType.map(item => item.code);

        this.blocks = [];
        boardsAPI.search(stageType).then(searchResponse => {
          const contacts = searchResponse.data;
          this.blocks = contacts.map(item => {
            return {
              id: item.id,
              status: item.code,
              title: item.name,
              lastActivityAt: format(
                new Date(item.last_activity_at),
                'dd/MM HH:mm'
              ),
            };
          });
        });
      });
    },
    updateBlock: debounce(function find(id, status) {
      this.blocks.find(b => b.id === Number(id)).status = status;
    }, 500),
    addBlock: debounce(function push(status) {
      this.blocks.push({
        id: this.blocks.length,
        status: status,
        title: faker.company.bs(),
      });
    }, 500),
  },
};
</script>

<style lang="scss">
@import '../../../assets/scss/kanban.scss';

* {
  box-sizing: border-box;
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
        background: map-get($status-colors, $status);
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
