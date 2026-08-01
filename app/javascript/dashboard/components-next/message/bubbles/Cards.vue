<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

const bodyText = computed(
  () =>
    contentAttributes.value.bodyText ||
    contentAttributes.value.body_text ||
    content.value ||
    ''
);

const items = computed(() =>
  (contentAttributes.value.items || []).map(item => ({
    ...item,
    mediaUrl: item.mediaUrl || item.media_url || '',
  }))
);

const normalizeActions = actions =>
  (actions || []).map(action => ({
    ...action,
    href: action.uri || action.url || '',
    isLink: ['link', 'url'].includes(action.type),
  }));
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="cards">
    <div class="flex flex-col gap-4">
      <span v-if="bodyText" v-dompurify-html="bodyText" :title="bodyText" />

      <div
        class="flex gap-3 overflow-x-auto snap-x snap-mandatory pb-1"
        data-carousel-track="true"
      >
        <div
          v-for="(item, index) in items"
          :key="`${item.title || 'card'}-${index}`"
          class="min-w-[17rem] max-w-[17rem] shrink-0 snap-start rounded-xl overflow-hidden border border-n-container bg-n-alpha-1"
        >
          <img
            v-if="item.mediaUrl"
            :src="item.mediaUrl"
            :alt="item.title || bodyText"
            class="h-44 w-full object-cover"
          />
          <div class="p-4 flex flex-col gap-3">
            <div class="flex flex-col gap-2">
              <h4 v-if="item.title" class="font-semibold text-base">
                {{ item.title }}
              </h4>
              <p v-if="item.description" class="text-sm text-n-slate-11">
                {{ item.description }}
              </p>
            </div>

            <div
              v-if="item.actions?.length"
              class="flex flex-col gap-2 pt-1 border-t border-n-container"
            >
              <template
                v-for="(action, actionIndex) in normalizeActions(item.actions)"
                :key="`${index}-${action.text}-${actionIndex}`"
              >
                <Button
                  v-if="action.isLink"
                  :label="action.text"
                  slate
                  outline
                  sm
                  :href="action.href"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="w-full"
                />
                <Button
                  v-else
                  :label="action.text"
                  slate
                  faded
                  sm
                  disabled
                  class="w-full"
                />
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
