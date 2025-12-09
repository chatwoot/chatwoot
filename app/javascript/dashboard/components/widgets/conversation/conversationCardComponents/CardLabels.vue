<script setup>
import { ref, computed, watch, onMounted, nextTick, useSlots } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  conversationLabels: {
    type: Array,
    required: true,
  },
  conversationId: {
    type: Number,
    default: null,
  },
});

const slots = useSlots();
const store = useStore();
const accountLabels = useMapGetter('labels/getLabels');

const activeLabels = computed(() => {
  return accountLabels.value.filter(({ title }) =>
    props.conversationLabels.includes(title)
  );
});

const showAllLabels = ref(false);
const showExpandLabelButton = ref(false);
const labelPosition = ref(-1);
const labelContainer = ref(null);
const deleteDialogRef = ref(null);
const labelToRemove = ref(null);
const isRemoving = ref(false);

const computeVisibleLabelPosition = () => {
  const beforeSlot = slots.before ? 100 : 0;
  if (!labelContainer.value) {
    return;
  }

  const labels = Array.from(labelContainer.value.querySelectorAll('.label'));
  let labelOffset = 0;
  showExpandLabelButton.value = false;
  labels.forEach((label, index) => {
    labelOffset += label.offsetWidth + 8;

    if (labelOffset < labelContainer.value.clientWidth - beforeSlot) {
      labelPosition.value = index;
    } else {
      showExpandLabelButton.value = labels.length > 1;
    }
  });
};

watch(activeLabels, () => {
  nextTick(() => computeVisibleLabelPosition());
});

onMounted(() => {
  computeVisibleLabelPosition();
});

const onShowLabels = e => {
  e.stopPropagation();
  showAllLabels.value = !showAllLabels.value;
  nextTick(() => computeVisibleLabelPosition());
};

const onRemoveLabel = labelTitle => {
  labelToRemove.value = labelTitle;
  nextTick(() => {
    deleteDialogRef.value?.open();
  });
};

const confirmRemoveLabel = async () => {
  if (!labelToRemove.value || !props.conversationId) return;

  isRemoving.value = true;

  const updatedLabels = activeLabels.value
    .map(label => label.title)
    .filter(title => title !== labelToRemove.value);

  try {
    await store.dispatch('conversationLabels/update', {
      conversationId: props.conversationId,
      labels: updatedLabels,
    });

    // Atualizar a conversa no store para refletir imediatamente na UI
    const conversation = store.getters['conversations/getConversationById'](
      props.conversationId
    );
    if (conversation) {
      store.commit('conversations/UPDATE_CONVERSATION', {
        ...conversation,
        labels: updatedLabels,
      });
    }
  } catch (error) {
    // Error is handled by the store
  } finally {
    isRemoving.value = false;
    labelToRemove.value = null;
  }
};

const cancelRemoveLabel = () => {
  labelToRemove.value = null;
  isRemoving.value = false;
};
</script>

<template>
  <div ref="labelContainer" v-resize="computeVisibleLabelPosition">
    <div
      v-if="activeLabels.length || $slots.before"
      class="flex items-end flex-shrink min-w-0 gap-y-1"
      :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
    >
      <slot name="before" />
      <woot-label
        v-for="(label, index) in activeLabels"
        :key="label ? label.id : index"
        :title="label.title"
        :description="label.description"
        :color="label.color"
        variant="smooth"
        class="!mb-0 max-w-[calc(100%-0.5rem)]"
        small
        :show-close="!!conversationId"
        :class="{
          'invisible absolute': !showAllLabels && index > labelPosition,
        }"
        @remove="onRemoveLabel"
      />
      <button
        v-if="showExpandLabelButton"
        :title="
          showAllLabels
            ? $t('CONVERSATION.CARD.HIDE_LABELS')
            : $t('CONVERSATION.CARD.SHOW_LABELS')
        "
        class="h-5 py-0 px-1 flex-shrink-0 mr-6 ml-0 rtl:ml-6 rtl:mr-0 rtl:rotate-180 text-n-slate-11 border-n-strong dark:border-n-strong"
        @click="onShowLabels"
      >
        <fluent-icon
          :icon="showAllLabels ? 'chevron-left' : 'chevron-right'"
          size="12"
        />
      </button>
    </div>

    <Dialog
      v-if="labelToRemove"
      ref="deleteDialogRef"
      type="alert"
      :title="$t('CONVERSATION.CARD.REMOVE_LABEL_TITLE')"
      :description="
        $t('CONVERSATION.CARD.REMOVE_LABEL_DESCRIPTION', {
          label: labelToRemove,
        })
      "
      :cancel-button-label="$t('CONVERSATION.CARD.REMOVE_LABEL_CANCEL')"
      :confirm-button-label="$t('CONVERSATION.CARD.REMOVE_LABEL_CONFIRM')"
      :is-loading="isRemoving"
      :disable-confirm-button="isRemoving"
      @confirm="confirmRemoveLabel"
      @close="cancelRemoveLabel"
    />
  </div>
</template>
