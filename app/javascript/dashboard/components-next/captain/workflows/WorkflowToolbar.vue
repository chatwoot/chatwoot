<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  workflow: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['save', 'back']);
const { t } = useI18n();

const name = ref('');
const description = ref('');
const triggerEvent = ref('conversation_created');
const enabled = ref(false);

watch(
  () => props.workflow,
  val => {
    if (val && val.id) {
      name.value = val.name || '';
      description.value = val.description || '';
      triggerEvent.value = val.trigger_event || 'conversation_created';
      enabled.value = val.enabled || false;
    }
  },
  { immediate: true }
);

const TRIGGER_OPTIONS = [
  {
    value: 'conversation_created',
    label: t('CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.CONVERSATION_CREATED'),
  },
  {
    value: 'message_created',
    label: t('CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.MESSAGE_CREATED'),
  },
  {
    value: 'conversation_resolved',
    label: t('CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.CONVERSATION_RESOLVED'),
  },
];

const triggerLabel = () => {
  const option = TRIGGER_OPTIONS.find(o => o.value === triggerEvent.value);
  return option ? option.label : triggerEvent.value;
};

const save = () => {
  emit('save', {
    name: name.value,
    description: description.value,
    trigger_event: triggerEvent.value,
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
    <SelectMenu
      v-model="triggerEvent"
      :options="TRIGGER_OPTIONS"
      :label="triggerLabel()"
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
