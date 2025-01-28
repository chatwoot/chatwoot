<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="onClickAway"
      class="left-[120%] rtl:left-auto rtl:right-[120%] top-0 w-56 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-2 px-2 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': show }"
    >
      <woot-dropdown-menu class="mb-0">
        <woot-dropdown-item v-if="isWhatsAppInbox">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="whatsapp"
            @click="handleWhatsAppBroadcastClick"
          >
            {{ 'WhatsApp' }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="mail"
            @click="handleEmailBroadcastClick"
          >
            {{ 'Email' }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </transition>
</template>
<script>
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import { mapGetters } from 'vuex';
import { INBOX_TYPES } from '../../../../shared/mixins/inboxMixin';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      inboxesList: 'inboxes/getInboxes',
    }),
    isWhatsAppInbox() {
      return this.inboxesList.some(
        inbox =>
          inbox.channel_type === INBOX_TYPES.API &&
          !!inbox?.additional_attributes?.message_templates
      );
    },
  },
  methods: {
    handleEmailBroadcastClick() {
      this.$emit('email-broadcast-modal');
    },
    handleWhatsAppBroadcastClick() {
      this.$emit('whatsapp-broadcast-modal');
    },
    onClickAway() {
      if (this.show) this.$emit('close');
    },
  },
};
</script>
