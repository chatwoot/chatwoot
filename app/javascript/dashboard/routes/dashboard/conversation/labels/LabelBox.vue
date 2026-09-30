<script setup>
import { ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Spinner from 'shared/components/Spinner.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SuggestionChip from 'dashboard/components-next/captain/classifier/SuggestionChip.vue';
import SuggestionSkeleton from 'dashboard/components-next/captain/classifier/SuggestionSkeleton.vue';

defineProps({
  suggestedLabels: { type: Array, default: () => [] },
  isSuggestionActive: { type: Boolean, default: false },
  isSuggesting: { type: Boolean, default: false },
});

const emit = defineEmits([
  'acceptSuggestion',
  'rejectSuggestion',
  'acceptAllSuggestions',
]);

const { isAdmin } = useAdmin();
const {
  savedLabels,
  activeLabels,
  accountLabels,
  addLabelToConversation,
  removeLabelFromConversation,
} = useConversationLabels();

const conversationUiFlags = useMapGetter('conversationLabels/getUIFlags');

const showSearchDropdownLabel = ref(false);

const toggleLabels = () => {
  showSearchDropdownLabel.value = !showSearchDropdownLabel.value;
};

const closeDropdownLabel = () => {
  showSearchDropdownLabel.value = false;
};

useKeyboardEvents({
  KeyL: {
    action: e => {
      e.preventDefault();
      toggleLabels();
    },
  },
  Escape: {
    action: () => {
      if (showSearchDropdownLabel.value) {
        toggleLabels();
      }
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <div class="sidebar-labels-wrap">
    <div
      v-if="!conversationUiFlags.isFetching"
      class="contact-conversation--list"
    >
      <div
        v-on-clickaway="closeDropdownLabel"
        class="label-wrap flex flex-wrap"
        @keyup.esc="closeDropdownLabel"
      >
        <AddLabel @add="toggleLabels" />
        <TransitionGroup
          enter-active-class="animate-pop-in"
          leave-active-class="transition duration-150 ease-in absolute"
          leave-to-class="opacity-0 scale-90"
          move-class="transition-transform duration-200"
        >
          <woot-label
            v-for="label in activeLabels"
            :key="label.id"
            :title="label.title"
            :description="label.description"
            show-close
            :color="label.color"
            variant="smooth"
            class="max-w-[calc(100%-0.5rem)]"
            @remove="removeLabelFromConversation"
          />
        </TransitionGroup>
        <template v-if="isSuggestionActive">
          <template v-if="isSuggesting">
            <SuggestionSkeleton
              class="flex-1 h-6 rounded basis-12 max-w-20 mb-0.5 me-1 animate-pop-in"
            />
            <SuggestionSkeleton
              class="flex-1 h-6 rounded basis-12 max-w-28 mb-0.5 me-1 animate-pop-in [animation-delay:70ms]"
            />
          </template>
          <span
            v-else-if="!suggestedLabels.length"
            class="inline-flex items-center h-6 min-w-0 gap-1 mb-0.5 ms-1 grow basis-24 max-w-max text-xs text-n-slate-11 animate-fade-in-up"
          >
            <Icon
              icon="i-ph-sparkle-fill"
              class="flex-shrink-0 size-3 text-n-iris-9"
            />
            <span class="truncate">
              {{ $t('CONVERSATION.SUGGESTIONS.EMPTY') }}
            </span>
          </span>
          <TransitionGroup
            v-else
            leave-active-class="transition duration-150 ease-in absolute"
            leave-to-class="opacity-0 scale-90"
            move-class="transition-transform duration-200"
          >
            <SuggestionChip
              v-for="(label, index) in suggestedLabels"
              :key="label.id"
              :title="label.title"
              :color="label.color"
              :index="index"
              @accept="emit('acceptSuggestion', label)"
              @reject="emit('rejectSuggestion', label)"
            />
            <button
              v-if="suggestedLabels.length > 1"
              key="accept-all"
              class="inline-flex items-center h-6 gap-1 px-2 mb-1 text-xs font-medium transition-all rounded text-n-iris-11 bg-n-iris-3 hover:bg-n-iris-4 hover:text-n-iris-12 active:scale-95 animate-pop-in [animation-delay:210ms]"
              @click="emit('acceptAllSuggestions')"
            >
              <Icon icon="i-lucide-check-check" />
              {{ $t('CONVERSATION.SUGGESTIONS.ACCEPT_ALL') }}
            </button>
          </TransitionGroup>
        </template>
        <div
          :class="{
            'block visible': showSearchDropdownLabel,
            'hidden invisible': !showSearchDropdownLabel,
          }"
          class="border rounded-lg bg-n-alpha-3 top-6 backdrop-blur-[100px] absolute w-full shadow-lg border-n-strong dark:border-n-strong p-2 box-border z-[9999]"
        >
          <LabelDropdown
            v-if="showSearchDropdownLabel"
            :account-labels="accountLabels"
            :selected-labels="savedLabels"
            :allow-creation="isAdmin"
            @add="addLabelToConversation"
            @remove="removeLabelFromConversation"
          />
        </div>
      </div>
    </div>
    <Spinner v-else />
  </div>
</template>

<style lang="scss" scoped>
.sidebar-labels-wrap {
  margin-bottom: 0;
}
.contact-conversation--list {
  width: 100%;

  .label-wrap {
    line-height: 1.5rem;
    position: relative;
  }
}
</style>
