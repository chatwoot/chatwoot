<template>
  <woot-modal :show="true" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('MERGE_CONTACTS.TITLE')"
      :header-content="$t('MERGE_CONTACTS.DESC')"
    />
    <div class="column content-box">
      <merge-contact
        :primary-contact="primaryContact"
        :on-contact-search="onContactSearch"
      />
    </div>
  </woot-modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import MergeContact from 'dashboard/routes/dashboard/contacts/components/MergeContact';
import ContactAPI from 'dashboard/api/contacts';

import { mapGetters } from 'vuex';

export default {
  components: { MergeContact },
  mixins: [alertMixin],
  props: {
    primaryContact: {
      type: Object,
      required: true,
    },
  },

  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    async onContactSearch(query) {
      const {
        data: { payload },
      } = await ContactAPI.search(query);

      return payload;
    },
  },
};
</script>
<style lang="scss" scoped>
.content-box {
  padding: 1.6rem 3.2rem;
}
</style>
