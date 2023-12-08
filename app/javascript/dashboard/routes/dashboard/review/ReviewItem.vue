<template>
  <div
    class="border-b border-slate-50 flex bg-white px-4 py-3 flex-1 items-center space-x-4"
    @contextmenu="openContextMenu($event)"
  >
    <div class="flex items-center space-x-4">
      <input
        type="checkbox"
        class="h-3 w-3 rounded !border-slate-100 mb-0 text-woot-500 focus:ring-woot-600"
      />
      <div class="whitespace-nowrap text-sm text-slate-600 w-12">
        #{{ source.id }}
      </div>
      <div
        class="whitespace-nowrap text-sm font-medium w-6 flex items-center justify-center"
      >
        <PriorityMark
          v-if="source.priority"
          :priority="source.priority"
          :size="20"
        />
        <div v-else class="text-xxs font-bold text-slate-400 text-center">
          --
        </div>
      </div>
      <span class="text-slate-600 capitalize truncate text-sm flex-1 mw-5">
        {{ source.status }}
      </span>
    </div>
    <div
      v-if="source.contact"
      class="flex items-center overflow-hidden text-ellipsis flex-1 min-w-0"
    >
      <span class="text-sm text-slate-800 font-medium">
        {{ source.contact.name }}
      </span>
      <span class="text-slate-600 mx-3">
        <fluent-icon icon="chevron-right" size="12" />
      </span>
      <span
        class="text-slate-600 text-sm flex-1 text-ellipsis !whitespace-normal line-clamp-1"
      >
        {{
          source.lastMessage ? source.lastMessage.content : 'File Attachment'
        }}
      </span>
      <CardLabelsRenderer
        class="flex-1 max-w-[160px] flex justify-end"
        :conversation-labels="source.labels"
      />
    </div>

    <div class="flex items-center justify-center space-x-4">
      <div class="flex items-center justify-center">
        <thumbnail
          v-if="source.assignee"
          :src="source.assignee.thumbnail"
          class="columns"
          :username="source.assignee.name"
          :status="source.assignee.availability_status"
          size="20px"
        />
        <div v-else class="w-4 h-5" />
      </div>
      <time-ago
        :last-activity-timestamp="source.lastActivityAt"
        :created-at-timestamp="source.createdAt"
      />
    </div>
    <woot-context-menu
      v-if="showContextMenu"
      ref="menu"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <ConversationContextMenu
        :status="source.status"
        :inbox-id="source.inboxId"
        :priority="source.priority"
        :has-unread-messages="false"
      />
    </woot-context-menu>
  </div>
</template>

<script>
import CardLabelsRenderer from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabelsRenderer.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import PriorityMark from 'dashboard/components/widgets/conversation/PriorityMark.vue';
import Thumbnail from '../../../components/widgets/Thumbnail.vue';
import ConversationContextMenu from 'dashboard/components/widgets/conversation/contextMenu/Index.vue';

export default {
  components: {
    ConversationContextMenu,
    CardLabelsRenderer,
    TimeAgo,
    PriorityMark,
    Thumbnail,
  },
  props: {
    source: {
      type: Object,
      default() {
        return {};
      },
    },
  },

  data() {
    return {
      hovered: false,
      showContextMenu: false,
      contextMenu: {
        x: null,
        y: null,
      },
    };
  },
  methods: {
    closeContextMenu() {
      this.showContextMenu = false;
      this.contextMenu.x = null;
      this.contextMenu.y = null;
    },
    openContextMenu(e) {
      e.preventDefault();
      this.$emit('context-menu-toggle', true);
      this.contextMenu.x = e.pageX || e.clientX;
      this.contextMenu.y = e.pageY || e.clientY;
      this.showContextMenu = true;
    },
  },
};
</script>
