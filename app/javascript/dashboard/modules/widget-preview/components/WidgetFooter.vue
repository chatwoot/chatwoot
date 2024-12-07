<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

const props = defineProps({
  config: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const isInputFocused = ref(false);

const getStatusText = computed(() => {
  return props.config.isOnline
    ? t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.ONLINE')
    : t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.OFFLINE');
});
</script>

<template>
  <div class="relative flex flex-col w-full px-4">
    <div
      v-if="config.isDefaultScreen"
      class="p-4 bg-white rounded-md shadow-sm dark:bg-slate-700"
    >
      <div class="flex items-center justify-between">
        <div>
          <div
            class="text-sm font-medium leading-4 text-slate-700 dark:text-slate-50"
          >
            {{ getStatusText }}
          </div>
          <div class="mt-1 text-xs text-slate-500 dark:text-slate-100">
            {{ config.replyTime }}
          </div>
        </div>
        <Thumbnail username="C" size="34px" />
      </div>
      <button
        v-if="config.isDefaultScreen"
        class="inline-flex items-center justify-between px-2 py-1 mt-1 -ml-2 font-medium leading-6 bg-transparent rounded-md text-slate-800 dark:bg-transparent dark:text-slate-50 hover:bg-slate-25 dark:hover:bg-slate-800"
        :style="{ color: config.color }"
      >
        <span class="pr-2 text-xs">
          {{
            $t(
              'INBOX_MGMT.WIDGET_BUILDER.FOOTER.START_CONVERSATION_BUTTON_TEXT'
            )
          }}
        </span>
        <FluentIcon icon="arrow-right" size="14" />
      </button>
    </div>
    <div
      v-else
      class="flex items-center h-10 bg-white rounded-md dark:bg-slate-700"
      :class="{ 'ring-2 ring-woot-500 dark:ring-woot-400': isInputFocused }"
    >
      <ResizableTextArea
        id="chat-input"
        :rows="1"
        :placeholder="
          $t('INBOX_MGMT.WIDGET_BUILDER.FOOTER.CHAT_INPUT_PLACEHOLDER')
        "
        class="flex-grow !bg-white border-0 border-none h-8 text-sm dark:!bg-slate-700 pb-0 !pt-1.5 resize-none px-3 !mb-0 focus:outline-none rounded-md"
        @focus="isInputFocused = true"
        @blur="isInputFocused = false"
      />
      <div class="flex items-center gap-2 px-2">
        <FluentIcon icon="emoji" />
        <FluentIcon class="icon-send" icon="send" />
      </div>
    </div>
  </div>
</template>
