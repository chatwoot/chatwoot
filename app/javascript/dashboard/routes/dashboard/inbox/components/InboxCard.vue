<template>
  <div
    role="button"
    class="flex flex-col pl-5 pr-3 gap-2.5 py-3 w-full bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800/50 hover:bg-slate-25 dark:hover:bg-slate-800 cursor-pointer"
    @contextmenu="openContextMenu($event)"
    @click="openConversation(notificationItem)"
  >
    <div class="flex relative items-center justify-between w-full">
      <div
        v-if="isUnread"
        class="absolute -left-3.5 flex w-2 h-2 rounded bg-woot-500 dark:bg-woot-500"
      />
      <InboxNameAndId :inbox="inbox" :conversation-id="primaryActor.id" />

      <div class="flex gap-2">
        <PriorityIcon :priority="primaryActor.priority" />
        <StatusIcon :status="primaryActor.status" />
      </div>
    </div>

    <div class="flex flex-row justify-between items-center w-full">
      <div class="flex gap-1.5 items-center max-w-[calc(100%-70px)]">
        <Thumbnail
          v-if="assigneeMeta"
          :src="assigneeMeta.thumbnail"
          :username="assigneeMeta.name"
          size="20px"
        />
        <div class="flex min-w-0">
          <span
            class="font-medium text-slate-800 dark:text-slate-50 text-sm overflow-hidden text-ellipsis whitespace-nowrap"
          >
            <span class="font-normal text-sm">
              {{ pushTitle }}
            </span>
          </span>
        </div>
      </div>
      <span
        class="font-medium max-w-[60px] text-slate-600 dark:text-slate-300 text-xs whitespace-nowrap"
      >
        {{ lastActivityAt }}
      </span>
    </div>
    <inbox-context-menu
      v-if="isContextMenuOpen"
      :context-menu-position="contextMenuPosition"
      @close="closeContextMenu"
    />
  </div>
</template>
<script>
import PriorityIcon from './PriorityIcon.vue';
import StatusIcon from './StatusIcon.vue';
import InboxNameAndId from './InboxNameAndId.vue';
import InboxContextMenu from './InboxContextMenu.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import timeMixin from 'dashboard/mixins/time';
export default {
  components: {
    PriorityIcon,
    InboxContextMenu,
    StatusIcon,
    InboxNameAndId,
    Thumbnail,
  },
  mixins: [timeMixin],
  props: {
    notificationItem: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      isContextMenuOpen: false,
      contextMenuPosition: { x: null, y: null },
    };
  },
  computed: {
    primaryActor() {
      return this.notificationItem?.primary_actor;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](
        this.primaryActor.inbox_id
      );
    },
    isUnread() {
      return !this.notificationItem?.read_at;
    },
    meta() {
      return this.primaryActor?.meta;
    },
    assigneeMeta() {
      return this.meta?.assignee;
    },
    pushTitle() {
      return this.$t(
        `INBOX.TYPES.${this.notificationItem.notification_type.toUpperCase()}`
      );
    },
    lastActivityAt() {
      const dynamicTime = this.dynamicTime(
        this.notificationItem?.last_activity_at
      );
      return this.shortTimestamp(dynamicTime, true);
    },
  },
  unmounted() {
    this.closeContextMenu();
  },
  methods: {
    openConversation(notification) {
      this.$emit('open-conversation', notification);
    },
    closeContextMenu() {
      this.isContextMenuOpen = false;
      this.contextMenuPosition = { x: null, y: null };
    },
    openContextMenu(e) {
      this.closeContextMenu();
      e.preventDefault();
      this.contextMenuPosition = {
        x: e.pageX || e.clientX,
        y: e.pageY || e.clientY,
      };
      this.isContextMenuOpen = true;
    },
  },
};
</script>
