<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <Kanban :stages="statuses" :blocks="blocks" @update-block="updateBlock">
      <div v-for="stage in statuses" :slot="stage" :key="stage">
        <h2>
          {{ stage }}
          <a>+</a>
        </h2>
      </div>
      <div v-for="item in blocks" :slot="item.id" :key="item.id">
        <div v-if="item.status === 'on-hold'">
          {{ item.title }}
        </div>
        <div v-else>
          <strong>id:</strong> {{ item.id }}
          <div>{{ item.title }}</div>
        </div>
      </div>
      <div v-for="stage in statuses" :key="stage" :slot="`footer-${stage}`">
        <a href="" @click.prevent="() => addBlock(stage)">+ Add new block</a>
      </div>
    </Kanban>
  </div>
</template>

<script>
import faker from 'faker';
import { debounce } from 'lodash';
import Kanban from '../../../components/Kanban.vue';

export default {
  name: 'app',
  components: {
    Kanban,
  },
  data() {
    return {
      statuses: ['on-hold', 'in-progress', 'needs-review', 'approved'],
      blocks: [],
    };
  },
  mounted() {
    for (let i = 0; i <= 10; i += 1) {
      this.blocks.push({
        id: i,
        status: this.statuses[Math.floor(Math.random() * 4)],
        title: faker.company.bs(),
      });
    }
  },

  methods: {
    updateBlock: debounce(function find(id, status) {
      this.blocks.find(b => b.id === Number(id)).status = status;
    }, 500),
    addBlock: debounce(function push(stage) {
      this.blocks.push({
        id: this.blocks.length,
        status: stage,
        title: faker.company.bs(),
      });
    }, 500),
  },
};
</script>

<style lang="scss">
@import '../../../assets/scss/kanban.scss';

$on-hold: #fb7d44;
$in-progress: #2a92bf;
$needs-review: #f4ce46;
$approved: #00b961;

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

  &-on-hold {
    .drag-column-header,
    .is-moved,
    .drag-options {
      background: $on-hold;
    }
  }

  &-in-progress {
    .drag-column-header,
    .is-moved,
    .drag-options {
      background: $in-progress;
    }
  }

  &-needs-review {
    .drag-column-header,
    .is-moved,
    .drag-options {
      background: $needs-review;
    }
  }

  &-approved {
    .drag-column-header,
    .is-moved,
    .drag-options {
      background: $approved;
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
