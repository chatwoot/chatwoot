<template>
  <div class="resolve-actions relative flex items-center justify-end">
    <div class="button-group">
      <woot-button
        :is-disabled="isDisabled"
        v-if="showReplyAndResolve"
        size="small"
        color-scheme="primary"
        icon="checkmark"
        emoji="✅"
        @click="onReplyAndResolve"
      >
        Reply And Resolve
      </woot-button>

      <woot-button
        :is-disabled="isDisabled"
        v-else-if="showReplyAsPending"
        color-scheme="primary"
        size="small"
        icon="book-clock"
        emoji="👀"
        @click="onReplyAsPending"
      >
        Reply as pending
      </woot-button>

      <woot-button
        :is-disabled="isDisabled"
        ref="arrowDownButton"
        color-scheme="primary"
        size="small"
        icon="chevron-down"
        emoji="🔽"
        @click="openDropdown"
      />
    </div>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item>
          <woot-button 
            variant="clear"
            color-scheme="primary"
            size="small"
            icon="checkmark-circle"
            @click="() => setSelectedAction('reply_and_resolve')"
          >
            Reply And Resolve
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="primary"
            size="small"
            icon="book-clock"
            @click="() => setSelectedAction('reply_as_pending')"
          >
            Reply as pending
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </div>
</template>
<script>
  import { mapGetters } from 'vuex';
  import wootConstants from 'dashboard/constants/globals';
  import { mixin as clickaway } from 'vue-clickaway';
  import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
  import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
  import alertMixin from 'shared/mixins/alertMixin';

  export default {
    name: 'ReplyTopMultipleAction',
    components: {
      WootDropdownItem,
      WootDropdownMenu,
    },
    mixins: [clickaway, alertMixin],
    props: {
      onSend: {
        type: Function,
        default: () => {},
      },
      onSendAsSurvey: {
        type: Function,
        default: () => {},
      },
      inbox: {
        type: Object,
        default: () => ({}),
      },
      conversationId: {
        type: Number,
        required: true,
      },
      message: {
        type: String,
        default: '',
      },
      isDisabled: {
        type: Boolean,
        default: false,
      }
    },
    data() {
      return {
        isLoading: false,
        showActionsDropdown: false,
        selectedAction: '',
        STATUS_TYPE: wootConstants.STATUS_TYPE,
        currentConversationId: 0,
      };
    },
    computed: {
      ...mapGetters({ 
        currentChat: 'getSelectedChat'
      }),
      isOpen() {
        return this.currentChat.status === wootConstants.STATUS_TYPE.OPEN;
      },
      isPending() {
        return this.currentChat.status === wootConstants.STATUS_TYPE.PENDING;
      },
      isResolved() {
        return this.currentChat.status === wootConstants.STATUS_TYPE.RESOLVED;
      },
      defaultRepyAction() {
        return this.inbox.default_reply_action || 'reply_and_resolve';
      },
      showReplyAndResolve(){
        if (this.getSelectedAction) {
          return this.selectedAction == 'reply_and_resolve';
        }

        return this.defaultRepyAction == 'reply_and_resolve';
      },
      showReplyAsPending(){
        if (this.getSelectedAction) {
          return this.selectedAction == 'reply_as_pending';
        }

        return this.defaultRepyAction == 'reply_as_pending';
      },
      buttonClass() {
        if (this.isPending) return 'primary';
        if (this.isOpen) return 'success';
        if (this.isResolved) return 'warning';
        return '';
      },
      getSelectedAction(){
        if (this.currentConversationId != this.conversationId){
          this.currentConversationId = this.conversationId;
          this.selectedAction = '';
        }
        return this.selectedAction;
      }
    },
    methods: {
      setSelectedAction(action){
        this.selectedAction = action;
        this.closeDropdown()
      },
      onReplyAndResolve(){
        this.onSend();
        setTimeout(() => {
          this.toggleStatus(this.STATUS_TYPE.RESOLVED);
        }, 1000)
      },
      onReplyAsPending(){
        this.onSend();
        setTimeout(() => {
          this.toggleStatus(this.STATUS_TYPE.PENDING);
        }, 1000)
      },
      openDropdown(){
        this.showActionsDropdown = true
      },
      closeDropdown(){
        this.showActionsDropdown = false
      },
      toggleStatus(status, snoozedUntil) {
        this.closeDropdown();
        this.isLoading = true;
        this.$store
          .dispatch('toggleStatus', {
            conversationId: this.currentChat.id,
            status,
            snoozedUntil,
          })
          .then(() => {
            this.showAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
            this.isLoading = false;
          });
      }
    },
  }
</script>

<style scoped>
.resolve-actions{
  margin-right: 5px;
  margin-left: 5px;
}
.button-group button{
  font-size: 12px;
}
.dropdown-pane{
  bottom: 3.5em
}
</style>