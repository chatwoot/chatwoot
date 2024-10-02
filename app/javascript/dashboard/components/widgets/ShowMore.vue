<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  text: {
    type: String,
    default: '',
  },
  limit: {
    type: Number,
    default: 120,
  },
});
const { t } = useI18n();
const showMore = ref(false);

const textToBeDisplayed = computed(() => {
  if (showMore.value || props.text.length <= props.limit) {
    return props.text;
  }

  return props.text.slice(0, props.limit) + '...';
});
const buttonLabel = computed(() => {
  const i18nKey = !showMore.value ? 'SHOW_MORE' : 'SHOW_LESS';
  return t(`COMPONENTS.SHOW_MORE_BLOCK.${i18nKey}`);
});

const toggleShowMore = () => {
  showMore.value = !showMore.value;
};
</script>

<template>
  <span>
    {{ textToBeDisplayed }}
    <button
      v-if="text.length > limit"
      class="text-woot-500 !p-0 !border-0 align-top"
      @click="toggleShowMore"
    >
      {{ buttonLabel }}
    </button>
  </span>
</template>
