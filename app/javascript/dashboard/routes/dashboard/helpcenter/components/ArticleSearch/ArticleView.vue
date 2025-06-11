<script setup>
import IframeLoader from 'shared/components/IframeLoader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  url: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['back', 'insert']);

const onBack = e => {
  e.stopPropagation();
  emit('back');
};

const onInsert = e => {
  e.stopPropagation();
  emit('insert');
};
</script>

<template>
  <div class="h-full w-full flex flex-col flex-1 overflow-hidden">
    <div class="py-1">
      <Button
        link
        xs
        :label="$t('HELP_CENTER.ARTICLE_SEARCH.BACK_RESULTS')"
        icon="i-lucide-chevron-left"
        @click="onBack"
      />
    </div>
    <div class="-ml-4 h-full overflow-y-auto">
      <div class="w-full h-full min-h-0">
        <IframeLoader :url="url" />
      </div>
    </div>

    <div class="flex justify-end gap-2 py-2">
      <Button
        faded
        slate
        sm
        type="reset"
        icon="i-lucide-chevron-left"
        :label="$t('HELP_CENTER.ARTICLE_SEARCH.BACK')"
        @click="onBack"
      />
      <Button
        sm
        type="submit"
        icon="i-lucide-arrow-down-to-dot"
        :label="$t('HELP_CENTER.ARTICLE_SEARCH.INSERT_ARTICLE')"
        @click="onInsert"
      />
    </div>
  </div>
</template>
