<script setup>
import TextKnowledgeSources from './knowledge-sources/TextKnowledgeSources.vue';
import FileKnowledgeSources from './knowledge-sources/FileKnowledgeSources.vue';
import WebKnowledgeSources from './knowledge-sources/WebKnowledgeSources.vue';
import QnaKnowledgeSources from './knowledge-sources/QnaKnowledgeSources.vue';

import { ref } from 'vue';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});
const tabs = [
  {
    key: '0',
    index: 0,
    name: 'Text',
  },
  {
    key: '1',
    index: 1,
    name: 'Website',
  },
  {
    key: '2',
    index: 2,
    name: 'File',
  },
  {
    key: '3',
    index: 3,
    name: 'QnA',
  },
];
const activeIndex = ref(0);
</script>

<template>
  <div class="flex flex-col justify-stretch gap-2">
    <woot-tabs
      :index="activeIndex"
      class="mb-3 tabs-rm-margin-2"
      @change="
        i => {
          activeIndex = i;
        }
      "
    >
      <woot-tabs-item
        v-for="tab in tabs"
        :key="tab.key"
        :index="tab.index"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>

    <div v-show="activeIndex === 0">
      <TextKnowledgeSources :data="data" />
    </div>
    <div v-show="activeIndex === 1">
      <WebKnowledgeSources :data="data" />
    </div>
    <div v-show="activeIndex === 2">
      <FileKnowledgeSources :data="data" />
    </div>
    <div v-show="activeIndex === 3">
      <QnaKnowledgeSources :data="data" />
    </div>
  </div>
</template>

<style lang="css">
.tabs-rm-margin-2 .tabs {
  padding-left: 0px !important;
}

.tabs-rm-margin-2 .tabs .tabs-title a {
  font-size: 18px;
  font-weight: 500;
}
</style>
