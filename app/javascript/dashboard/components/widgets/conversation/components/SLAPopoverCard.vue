<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue';

import wootConstants from 'dashboard/constants/globals';
import SLAEventItem from './SLAEventItem.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  slaMissedEvents: {
    type: Array,
    required: true,
  },
  conversationCreatedAt: {
    type: Number,
    default: null,
  },
  slaPolicy: {
    type: Object,
    default: () => ({}),
  },
});

const { SLA_MISS_TYPES } = wootConstants;

const shouldShowAllNrts = ref(false);

const frtMisses = computed(() =>
  props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.FRT
  )
);
const nrtMisses = computed(() => {
  const missedEvents = props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.NRT
  );
  return shouldShowAllNrts.value ? missedEvents : missedEvents.slice(0, 6);
});
const rtMisses = computed(() =>
  props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.RT
  )
);

const shouldShowMoreNRTButton = computed(() => nrtMisses.value.length > 6);
const toggleShowAllNRT = () => {
  shouldShowAllNrts.value = !shouldShowAllNrts.value;
};

const modalRef = ref(null);
const positionStyle = ref({});

const calculatePosition = () => {
  nextTick(() => {
    if (modalRef.value) {
      const modal = modalRef.value;
      // Encontrar o botão trigger através do parent container
      const parentContainer = modal.parentElement;
      if (!parentContainer) return;
      
      const triggerButton = parentContainer.querySelector('button, a');
      if (!triggerButton) return;
      
      const buttonRect = triggerButton.getBoundingClientRect();
      const viewportHeight = window.innerHeight;
      const viewportWidth = window.innerWidth;
      const estimatedModalHeight = 600;
      const estimatedModalWidth = 720;
      const spacing = 8;
      const margin = 8;
      
      // Calcular espaço disponível
      const spaceAbove = buttonRect.top;
      const spaceBelow = viewportHeight - buttonRect.bottom;
      
      // Determinar posição horizontal (alinhar à direita do botão, mas garantir que caiba)
      let leftPos = buttonRect.right - estimatedModalWidth;
      if (leftPos < margin) {
        leftPos = margin;
      }
      if (leftPos + estimatedModalWidth > viewportWidth - margin) {
        leftPos = viewportWidth - estimatedModalWidth - margin;
      }
      
      // Determinar posição vertical
      let topPos = null;
      let bottomPos = null;
      let maxHeight = estimatedModalHeight;
      
      if (spaceBelow >= estimatedModalHeight + spacing) {
        // Espaço suficiente embaixo - mostrar abaixo
        topPos = buttonRect.bottom + spacing;
      } else if (spaceAbove >= estimatedModalHeight + spacing) {
        // Espaço suficiente em cima - mostrar acima
        bottomPos = viewportHeight - buttonRect.top + spacing;
      } else {
        // Não há espaço suficiente, escolher o lado com mais espaço e ajustar altura
        if (spaceAbove > spaceBelow) {
          // Mostrar acima com altura limitada
          bottomPos = viewportHeight - buttonRect.top + spacing;
          maxHeight = Math.max(200, spaceAbove - spacing - 16);
        } else {
          // Mostrar abaixo com altura limitada
          topPos = buttonRect.bottom + spacing;
          maxHeight = Math.max(200, spaceBelow - spacing - 16);
        }
      }
      
      // Usar fixed positioning para escapar do overflow-hidden
      positionStyle.value = {
        position: 'fixed',
        left: `${leftPos}px`,
        top: topPos !== null ? `${topPos}px` : 'auto',
        bottom: bottomPos !== null ? `${bottomPos}px` : 'auto',
        right: 'auto',
        maxHeight: `${maxHeight}px`,
        width: `${estimatedModalWidth}px`,
        zIndex: 9999,
      };
    }
  });
};

watch(() => [frtMisses.value, nrtMisses.value, rtMisses.value], () => {
  calculatePosition();
}, { flush: 'post' });

onMounted(() => {
  calculatePosition();
  window.addEventListener('scroll', calculatePosition, true);
  window.addEventListener('resize', calculatePosition);
});

onUnmounted(() => {
  window.removeEventListener('scroll', calculatePosition, true);
  window.removeEventListener('resize', calculatePosition);
});
</script>

<template>
  <div
    ref="modalRef"
    class="flex flex-col items-start border-n-strong bg-n-solid-3 backdrop-blur-[100px] px-6 py-5 shadow rounded-xl gap-4 overflow-auto"
    :style="positionStyle"
  >
    <span class="text-sm font-medium text-n-slate-12">
      {{ $t('SLA.EVENTS.TITLE') }}
    </span>
    <SLAEventItem
      v-if="frtMisses.length"
      :label="$t('SLA.EVENTS.FRT')"
      :items="frtMisses"
      :conversation-created-at="conversationCreatedAt"
      :sla-threshold="slaPolicy.sla_first_response_time_threshold"
    />
    <SLAEventItem
      v-if="nrtMisses.length"
      :label="$t('SLA.EVENTS.NRT')"
      :items="nrtMisses"
      :conversation-created-at="conversationCreatedAt"
      :sla-threshold="slaPolicy.sla_next_response_time_threshold"
    >
      <template #showMore>
        <div
          v-if="shouldShowMoreNRTButton"
          class="flex flex-col items-end w-full"
        >
          <Button
            link
            xs
            slate
            class="hover:!no-underline"
            :icon="!shouldShowAllNrts ? 'i-lucide-plus' : ''"
            :label="
              shouldShowAllNrts
                ? $t('SLA.EVENTS.HIDE', { count: nrtMisses.length })
                : $t('SLA.EVENTS.SHOW_MORE', { count: nrtMisses.length })
            "
            @click="toggleShowAllNRT"
          />
        </div>
      </template>
    </SLAEventItem>
    <SLAEventItem
      v-if="rtMisses.length"
      :label="$t('SLA.EVENTS.RT')"
      :items="rtMisses"
      :conversation-created-at="conversationCreatedAt"
      :sla-threshold="slaPolicy.sla_resolution_time_threshold"
    />
  </div>
</template>
