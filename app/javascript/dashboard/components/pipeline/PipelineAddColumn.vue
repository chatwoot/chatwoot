<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  storeModule: {
    type: String,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const isCreating = computed(
  () => store.getters[`${props.storeModule}/getUiFlags`].isCreating
);

const emit = defineEmits(['newColumn']);
</script>

<template>
  <div>
    <Button
      :label="t('PIPELINE.ADD_COLUMN')"
      icon="i-lucide-plus"
      :disabled="isCreating"
      @click="$emit('newColumn')"
    />
  </div>
</template>
