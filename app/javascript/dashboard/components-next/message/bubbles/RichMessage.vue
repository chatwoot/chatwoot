<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import AttachmentChips from '../chips/AttachmentChips.vue';
import ProductCard from '../catalog/ProductCard.vue';
import OrderCard from '../catalog/OrderCard.vue';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { useMessageContext } from '../provider.js';

const { contentAttributes, attachments } = useMessageContext();

// content_attributes keys are deep-camelized by MessageList (useCamelCase), so the
// rich payload arrives as { type, title, body, footer, buttons: [{ text, url, phone }] }.
const rich = computed(() => contentAttributes.value?.rich ?? {});

// A catalog product or order is a card of its own kind, drawn from its data and not
// from the connector's English title and footer. An empty product still is one.
const product = computed(() =>
  rich.value.type === 'product' && rich.value.product
    ? rich.value.product
    : null
);
const order = computed(() =>
  rich.value.type === 'order' && rich.value.order ? rich.value.order : null
);
// The product's photo arrives as the message's image once the connector delivers it.
const productImage = computed(
  () =>
    attachments.value?.find(attachment => attachment.fileType === 'image') ??
    null
);

const formattedBody = computed(() =>
  rich.value.body ? new MessageFormatter(rich.value.body).formattedMessage : ''
);

// Webhook-derived URLs: only accept well-formed http(s) so an unsafe scheme
// (e.g. javascript:) never reaches the link. Mirrors ReferralCard.
const toHttpUrl = url => {
  if (!url) return null;
  try {
    return ['http:', 'https:'].includes(new URL(url).protocol) ? url : null;
  } catch {
    return null;
  }
};

const buttons = computed(() => {
  const list = Array.isArray(rich.value.buttons) ? rich.value.buttons : [];
  return list
    .filter(button => button && typeof button === 'object')
    .map(button => {
      const url = toHttpUrl(button.url);
      if (url) {
        return {
          text: button.text,
          href: url,
          isLink: true,
          icon: 'i-lucide-external-link',
        };
      }
      if (typeof button.phone === 'string' && button.phone) {
        return {
          text: button.text,
          href: `tel:${button.phone}`,
          isLink: false,
          icon: 'i-lucide-phone',
        };
      }
      return { text: button.text, href: null, isLink: false, icon: null };
    });
});
</script>

<template>
  <BaseBubble class="px-4 py-3 text-sm" data-bubble-name="rich">
    <ProductCard v-if="product" :product="product" :attachment="productImage" />
    <OrderCard v-else-if="order" :order="order" :note="rich.body || ''" />
    <div v-else class="flex flex-col gap-2">
      <AttachmentChips
        v-if="attachments?.length"
        :attachments="attachments"
        class="gap-2"
      />
      <p v-if="rich.title" class="mb-0 font-medium">{{ rich.title }}</p>
      <div
        v-if="formattedBody"
        v-dompurify-html="formattedBody"
        class="prose prose-bubble"
      />
      <p v-if="rich.footer" class="mb-0 text-xs text-n-slate-11">
        {{ rich.footer }}
      </p>
      <div v-if="buttons.length" class="flex flex-col gap-1 pt-1">
        <component
          :is="button.href ? 'a' : 'div'"
          v-for="(button, index) in buttons"
          :key="`${button.text}-${index}`"
          :href="button.href || undefined"
          :target="button.isLink ? '_blank' : undefined"
          :rel="button.isLink ? 'noopener noreferrer' : undefined"
          class="flex items-center justify-center gap-1 px-3 py-1.5 text-sm font-medium text-center no-underline rounded-lg bg-n-alpha-black1"
          :class="
            button.href
              ? 'cursor-pointer hover:bg-n-alpha-black2 text-n-slate-12'
              : 'text-n-slate-11'
          "
        >
          <Icon
            v-if="button.icon"
            :icon="button.icon"
            class="size-3 shrink-0"
          />
          <span>{{ button.text }}</span>
        </component>
      </div>
    </div>
  </BaseBubble>
</template>
