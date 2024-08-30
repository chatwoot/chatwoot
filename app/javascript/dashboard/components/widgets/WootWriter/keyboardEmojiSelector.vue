<script setup>
import { ref, computed, onMounted } from 'vue';
import emojis from 'shared/components/emoji/emojisGroup.json';
import { picoSearch } from '@scmmishra/pico-search';
import MentionBox from '../mentions/MentionBox.vue';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click']);

const allEmojis = ref([]);

const items = computed(() => {
  const searchTerm = props.searchKey.toLowerCase();
  return picoSearch(allEmojis.value, searchTerm, ['slug', 'name']);
});

function loadEmojis() {
  allEmojis.value = emojis.flatMap(group => group.emojis);
}

function handleMentionClick(item = {}) {
  emit('click', item.emoji);
}

onMounted(() => {
  loadEmojis();
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <MentionBox
    v-if="items.length"
    type="emoji"
    :items="items"
    @mentionSelect="handleMentionClick"
  >
    <template #default="{ item, selected }">
      <span
        class="max-w-full inline-flex items-center gap-0.5 min-w-0 mb-0 text-sm font-medium text-slate-900 dark:text-slate-100 group-hover:text-woot-500 dark:group-hover:text-woot-500 truncate"
      >
        {{ item.emoji }}
        <p
          class="relative mb-0 truncate bottom-px"
          :class="{
            'text-woot-500 dark:text-woot-500': selected,
            'font-normal': !selected,
          }"
        >
          :{{ item.slug }}
        </p>
      </span>
    </template>
  </MentionBox>
</template>
