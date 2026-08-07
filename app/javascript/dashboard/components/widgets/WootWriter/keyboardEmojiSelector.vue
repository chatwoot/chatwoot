<script setup>
import { computed, ref, shallowRef, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import emojiGroups from 'shared/components/emoji/emojisGroup.json';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectEmoji', 'close']);

const { t } = useI18n();

const allEmojis = shallowRef([]);
// The trigger can already be followed by text, from a draft or a caret moved back onto it
const searchQuery = ref(props.searchKey);

const searchTerm = computed(() => searchQuery.value.trim().toLowerCase());

const items = computed(() => {
  if (!searchTerm.value) return [];

  return allEmojis.value
    .filter(emoji => emoji.searchString.includes(searchTerm.value))
    .map(({ emoji, name, slug, category }) => ({
      id: slug,
      emoji,
      category,
      label: name,
      title: name,
      subtitle: `:${slug}:`,
    }));
});

onMounted(() => {
  allEmojis.value = emojiGroups.flatMap(({ name: category, emojis }) =>
    emojis.map(({ name, slug, ...rest }) => ({
      ...rest,
      name,
      slug,
      category,
      searchString: `${name.replace(/\s+/g, '')} ${slug}`.toLowerCase(),
    }))
  );
});

const onSelect = item => emit('selectEmoji', item.emoji);
</script>

<template>
  <CaretAnchoredPicker
    v-model:search="searchQuery"
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('CONVERSATION.PICKER.EMOJI.SEARCH_PLACEHOLDER')"
    :empty-label="
      searchTerm
        ? t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm })
        : t('CONVERSATION.PICKER.EMOJI.EMPTY_STATE')
    "
    @select="onSelect"
    @close="emit('close')"
  >
    <template #leading="{ item }">
      <span class="text-base leading-none">{{ item.emoji }}</span>
    </template>
    <template #preview="{ item }">
      <div v-if="item" class="flex items-start gap-3 px-4 py-3">
        <span class="text-4xl leading-none">{{ item.emoji }}</span>
        <div class="flex flex-col min-w-0 gap-1">
          <span class="text-sm font-medium capitalize text-n-slate-12">
            {{ item.label }}
          </span>
          <span class="text-xs break-all text-n-slate-11">
            {{ item.subtitle }}
          </span>
          <span class="text-xs text-n-slate-10">{{ item.category }}</span>
        </div>
      </div>
    </template>
  </CaretAnchoredPicker>
</template>
