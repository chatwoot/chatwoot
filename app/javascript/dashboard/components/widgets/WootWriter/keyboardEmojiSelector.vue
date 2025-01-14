<script setup>
import { shallowRef, computed, onMounted } from 'vue';
import emojiGroups from 'shared/components/emoji/emojisGroup.json';
import MentionBox from '../mentions/MentionBox.vue';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectEmoji']);

const allEmojis = shallowRef([]);

const items = computed(() => {
  if (!props.searchKey) return [];
  const searchTerm = props.searchKey.toLowerCase();
  return allEmojis.value.filter(emoji =>
    emoji.searchString.includes(searchTerm)
  );
});

function loadEmojis() {
  allEmojis.value = emojiGroups.flatMap(({ emojis }) =>
    emojis.map(({ name, slug, ...rest }) => ({
      ...rest,
      name,
      slug,
      searchString: `${name.replace(/\s+/g, '')} ${slug}`.toLowerCase(), // Remove all whitespace and convert to lowercase
    }))
  );
}

function handleMentionClick(item = {}) {
  emit('selectEmoji', item.emoji);
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
    @mention-select="handleMentionClick"
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
          :{{ item.name }}
        </p>
      </span>
    </template>
  </MentionBox>
</template>
