<template>
  <div class="relative items-center w-full p-4 bg-white dark:bg-slate-900">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <div class="flex flex-row justify-between">
        <div class="flex gap-3 items-center">
          <thumbnail
            v-if="showAvatar"
            :src="contact.thumbnail"
            size="40px"
            :username="contact.full_name"
          />
          <h3
            class="flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-slate-800 dark:text-slate-100"
          >
            {{ contact.full_name }}
          </h3>
        </div>
        <woot-button
          v-if="showCloseButton"
          :icon="closeIconName"
          class="clear secondary rtl:rotate-180"
          @click="onPanelToggle"
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full mt-2">
        <div class="flex flex-col items-start w-full gap-2">
          <contact-info-row
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="mail"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />
          <contact-info-row
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
          />
          <contact-info-row
            v-if="contact.document"
            :value="contact.document"
            icon="contact-identify"
            emoji="🪪"
            :title="$t('CONTACT_PANEL.IDENTIFIER')"
          />
        </div>
      </div>
      <div class="flex items-center w-full mt-2 gap-2">
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
          title="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="merge"
          variant="smooth"
          size="small"
          color-scheme="secondary"
          :disabled="false"
          @click="openMergeModal"
        />
      </div>

      <contact-merge-modal
        v-if="showMergeModal"
        :primary-contact="contact"
        :show="showMergeModal"
        @close="toggleMergeModal"
      />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ContactInfoRow from 'dashboard/routes/dashboard/conversation/contact/ContactInfoRow.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import { getCountryFlag } from 'dashboard/helper/flag';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';

export default {
  components: {
    ContactInfoRow,
    Thumbnail,
    ContactMergeModal,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },

    showAvatar: {
      type: Boolean,
      default: true,
    },
    showCloseButton: {
      type: Boolean,
      default: true,
    },
    closeIconName: {
      type: String,
      default: 'chevron-right',
    },
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      showMergeModal: false,
    };
  },

  methods: {
    toggleMergeModal() {
      this.showMergeModal = !this.showMergeModal;
    },

    onPanelToggle() {
      this.$emit('toggle-panel');
    },

    openMergeModal() {
      this.toggleMergeModal();
    },
  },
};
</script>
