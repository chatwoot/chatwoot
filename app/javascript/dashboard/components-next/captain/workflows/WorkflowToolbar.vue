<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  workflow: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['save', 'back']);
const { t } = useI18n();

const name = ref('');
const description = ref('');
const enabled = ref(false);

watch(
  () => props.workflow,
  val => {
    if (val && val.id) {
      name.value = val.name || '';
      description.value = val.description || '';
      enabled.value = val.enabled || false;
    }
  },
  { immediate: true }
);

const save = () => {
  emit('save', {
    name: name.value,
    description: description.value,
    enabled: enabled.value,
  });
};
</script>

<template>
  <div
    class="flex items-center gap-3 px-4 py-2.5 border-b border-n-weak bg-n-solid-2"
  >
    <Button icon="i-lucide-arrow-left" xs ghost slate @click="emit('back')" />
    <span class="w-px h-4 bg-n-weak" />
    <Input
      v-model="name"
      class="max-w-xs"
      :placeholder="t('CAPTAIN.ASSISTANTS.WORKFLOWS.TOOLBAR.NAME_PLACEHOLDER')"
    />
    <div class="flex items-center gap-2.5 ml-auto">
      <span class="text-xs text-n-slate-11">
        {{ t('CAPTAIN.ASSISTANTS.WORKFLOWS.TOOLBAR.ENABLED') }}
      </span>
      <Switch v-model="enabled" />
      <span class="w-px h-4 bg-n-weak" />
      <Button
        :label="t('CAPTAIN.ASSISTANTS.WORKFLOWS.TOOLBAR.SAVE')"
        sm
        @click="save"
      />
    </div>
  </div>
</template>
