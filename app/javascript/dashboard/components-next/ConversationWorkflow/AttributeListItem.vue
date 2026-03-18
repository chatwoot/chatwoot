<script setup>
import { computed } from 'vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import AttributeBadge from 'dashboard/components-next/CustomAttributes/AttributeBadge.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  badges: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['edit', 'delete']);

const iconByType = {
  text: 'i-lucide-menu',
  checkbox: 'i-lucide-circle-check-big',
  list: 'i-lucide-list',
  date: 'i-lucide-calendar',
  link: 'i-lucide-link',
  number: 'i-lucide-hash',
};

const attributeIcon = computed(() => {
  const typeKey = props.attribute.type?.toLowerCase();
  return iconByType[typeKey] || 'i-lucide-menu';
});
</script>

<template>
  <div class="flex flex-col py-4 min-w-0">
    <div class="flex justify-between flex-row items-center gap-4 min-w-0">
      <div class="flex items-center gap-4 min-w-0">
        <div
          class="flex items-center flex-shrink-0 size-10 justify-center rounded-xl outline outline-1 outline-n-weak -outline-offset-1"
        >
          <Icon :icon="attributeIcon" class="size-4 text-n-slate-11" />
        </div>
        <div class="flex flex-col gap-1.5 items-start min-w-0 overflow-hidden">
          <div class="flex items-center gap-2 min-w-0">
            <h4 class="text-heading-3 truncate text-n-slate-12 min-w-0">
              {{ attribute.label }}
            </h4>
            <div class="flex items-center gap-1.5">
              <Label :label="attribute.type" compact />
              <AttributeBadge
                v-for="badge in badges"
                :key="badge.type"
                :type="badge.type"
              />
            </div>
          </div>
          <div class="grid grid-cols-[auto_1fr] items-center gap-1.5">
            <Icon icon="i-lucide-key-round" class="size-3.5 text-n-slate-11" />
            <div class="flex items-center gap-2 min-w-0">
              <span class="text-body-main text-n-slate-11 truncate">
                {{ attribute.value }}
              </span>
              <template
                v-if="attribute.attribute_description || attribute.description"
              >
                <div class="w-px h-3 rounded-lg bg-n-weak flex-shrink-0" />
                <span class="text-body-main text-n-slate-11 truncate">
                  {{ attribute.attribute_description || attribute.description }}
                </span>
              </template>
            </div>
          </div>
        </div>
      </div>
      <div class="flex gap-3 justify-end flex-shrink-0">
        <Button
          icon="i-woot-edit-pen"
          slate
          sm
          @click="emit('edit', attribute)"
        />
        <Button
          icon="i-woot-bin"
          slate
          sm
          class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
          @click="emit('delete', attribute)"
        />
      </div>
    </div>
  </div>
</template>
