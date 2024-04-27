<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <Kanban :statuses="statuses" :blocks="blocks" @update-block="updateBlock">
      <div
        v-for="stage in stages"
        :slot="stage.short_name"
        :key="stage.short_name"
      >
        <h2>
          {{ stage.name }}
          <a href="" @click.prevent="() => addBlock(stage.short_name)">+</a>
        </h2>
      </div>
      <div v-for="item in blocks" :slot="item.id" :key="item.id">
        <div v-if="item.status === 'Prospecting'">
          {{ item.title }}
        </div>
        <div v-else>
          <strong>id:</strong> {{ item.id }}
          <div>{{ item.title }}</div>
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

export default {
  name: 'app',
  components: {
    Kanban,
  },
  data() {
    return {
      statuses: [],
      stages: [],
      blocks: [],
    };
  },
  mounted() {
    boardsAPI.get().then(response => {
      const stagesByType = response.data.filter(
        item => item.stage_type === 'deals'
      );
      this.stages = stagesByType;
      this.statuses = stagesByType.map(item => item.short_name);

      for (let i = 0; i <= 15; i += 1) {
        this.blocks.push({
          id: i,
          status:
            this.statuses[Math.floor(Math.random() * this.statuses.length)],
          title: faker.company.bs(),
        });
      }
    });
  },

  methods: {
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
    Contacting: #2a92bf,
    Converted: #00b961,
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
