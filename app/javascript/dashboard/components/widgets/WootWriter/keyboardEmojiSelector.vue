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

const emit = defineEmits(['selectEmoji', 'close', 'removeTrigger']);

const { t } = useI18n();

const allEmojis = shallowRef([]);

const searchQuery = ref(props.searchKey);

// Names are spaced and shortcodes are underscored, so both sides drop the separators
// and `grinning face`, `grinningface` and `grinning_face` all reach the same emoji.
const stripSeparators = value => value.toLowerCase().replace(/[\s_-]+/g, '');

const searchTerm = computed(() => searchQuery.value.trim());

const normalizedTerm = computed(() => stripSeparators(searchTerm.value));

const items = computed(() => {
  if (!normalizedTerm.value) return [];

  return allEmojis.value
    .filter(emoji => emoji.searchString.includes(normalizedTerm.value))
    .map(({ emoji, name, slug }) => ({
      id: slug,
      emoji,
      label: name,
      title: name,
      subtitle: `:${slug}:`,
    }));
});

onMounted(() => {
  allEmojis.value = emojiGroups.flatMap(({ emojis }) =>
    emojis.map(({ name, slug, ...rest }) => ({
      ...rest,
      name,
      slug,
      searchString: `${stripSeparators(name)} ${stripSeparators(slug)}`,
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
    @remove-trigger="emit('removeTrigger')"
  >
    <template #leading="{ item }">
      <span class="text-base leading-none">{{ item.emoji }}</span>
    </template>
  </CaretAnchoredPicker>
</template>
