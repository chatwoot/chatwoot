<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="flex flex-row gap-4">
      <div class="w-[50%] m-auto">
        <h5 class="text-sm text-slate-800 dark:text-slate-100">
          {{ $t('CSAT_TEMPLATES.TEMPLATE.TITLE') }}
          <div class="float-right mt-5">
            <woot-button
              size="small"
              color-scheme="success"
              @click.prevent="openAddCsatTemplatesModal"
            >
              {{ $t('CSAT_TEMPLATES.TEMPLATE.ADD') }}
            </woot-button>
          </div>
        </h5>
        <div>
          <p class="csat-description">
            {{ $t('CSAT_TEMPLATES.TEMPLATE.DESCRIPTION') }}
          </p>
        </div>
        <div
          class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4 mt-4"
        >
          <table>
            <thead>
              <tr>
                <th>{{ $t('CSAT_TEMPLATES.FORM.NAME') }}</th>
                <th>{{ $t('CSAT_TEMPLATES.TABLE.HEADERS.QUESTIONS') }}</th>
                <th>{{ $t('CSAT_TEMPLATES.TABLE.HEADERS.INBOXES') }}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              <tr v-for="csatTemplate in records" :key="csatTemplate.id">
                <td>{{ csatTemplate.name }}</td>
                <td>{{ csatTemplate.questions_count }} questions</td>
                <td>{{ csatTemplate.inboxes_names }}</td>
                <td class="text-right">
                  <more-option
                    :template-id="csatTemplate.id"
                    @on-edit="openEditPopup"
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <woot-modal
      :show.sync="showAddCsatTemplatesPopup"
      :on-close="closeAddCsatTemplatesModal"
      size="small"
    >
      <add-csat-template :on-close="closeAddCsatTemplatesModal" />
    </woot-modal>

    <woot-modal
      :show.sync="showEditPopup"
      :on-close="closeEditPopup"
      size="small"
    >
      <edit-csat-template :on-close="closeEditPopup" />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import alertMixin from 'shared/mixins/alertMixin';
import AddCsatTemplate from './AddCsatTemplate.vue';
import MoreOption from './MoreOption.vue';
import EditCsatTemplate from './EditCsatTemplate.vue';

export default {
  components: {
    AddCsatTemplate,
    MoreOption,
    EditCsatTemplate,
  },
  mixins: [adminMixin, accountMixin, alertMixin],
  data() {
    return {
      loading: {},
      showSettings: false,
      showAddCsatTemplatesPopup: false,
      showEditPopup: false,
      customCsatEnabled: false,
      selectedTeam: {},
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      records: 'csatTemplates/records',
      currentTemplateId: 'csatTemplates/getCurrentTemplateId',
    }),
  },
  mounted() {
    this.$store.dispatch('csatTemplates/get');
  },
  methods: {
    openAddCsatTemplatesModal() {
      this.showAddCsatTemplatesPopup = true;
    },
    closeAddCsatTemplatesModal() {
      this.showAddCsatTemplatesPopup = false;
    },
    openEditPopup() {
      this.showEditPopup = true;
    },
    closeEditPopup() {
      this.showEditPopup = false;
    },
  },
};
</script>

<style>
hr:first-child {
  @apply hidden;
}

hr {
  @apply m-1 border-b border-solid border-slate-50 dark:border-slate-800/50;
}

.csat-description {
  font-size: 12px;
  color: #7b7b7b;
}
</style>
