<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="flex flex-row gap-4">
      <div class="w-[50%] m-auto">
        <h5 class="text-xl text-slate-800 dark:text-slate-100">
          {{ $t('CSAT_SETTINGS.CARD.HEADER') }}
          <woot-switch
            class="mt-6 mx-1 mb-0 float-right"
            :value="csatTemplateEnabled"
            @input="updateCustomCsatEnabled"
          />
        </h5>
        <div>
          <p class="csat-description">
            {{ $t('CSAT_SETTINGS.CARD.SETTING_DESCRIPTION') }}
          </p>
        </div>
        <hr class="my-2" />
        <h5 class="text-sm text-slate-800 dark:text-slate-100">
          CSAT Triggers
          <select v-model="csatTrigger" class="mt-5 mb-0" v-on:change="changeCsatTrigger">
            <option value="conversation_all_reply">Send CSAT with all replies</option>
            <option value="conversation_resolved">Send CSAT when conversation is closed</option>
          </select>
        </h5>
        <div class="mb-5">
          <p class="csat-description">
            Configurate the triggers for Customer Satisfaction (CSAT)
          </p>
        </div>
        <hr class="my-2" />
        <h5 class="text-sm text-slate-800 dark:text-slate-100">
          {{ $t('CSAT_SETTINGS.TEMPLATE.TITLE') }}
          <div class="float-right mt-5">
            <woot-button
              size="small"
              color-scheme="success"
              @click.prevent="openAddCsatTemplatesModal"
            >
              {{ $t('CSAT_SETTINGS.TEMPLATE.ADD') }}
            </woot-button>
          </div>
        </h5>
        <div>
          <p class="csat-description">
            {{ $t('CSAT_SETTINGS.TEMPLATE.DESCRIPTION') }}
          </p>
        </div>
        <div
          class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4 mt-4"
        >
          <table>
            <thead>
              <tr>
                <th>{{ $t('CSAT_SETTINGS.TABLE.HEADERS.QUESTIONS') }}</th>
                <th>{{ $t('CSAT_SETTINGS.TABLE.HEADERS.INBOX') }}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              <tr v-for="csatTemplate in records" :key="csatTemplate.id">
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
      csatTrigger: 'conversation_resolved',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      records: 'csatTemplates/records',
      csatTemplateEnabled: 'csatTemplates/csatTemplateEnabled',
      currentTemplateId: 'csatTemplates/getCurrentTemplateId',
      currentCsatTrigger: 'csatTemplates/getCsatTrigger'
    }),
  },
  mounted() {
    this.$store.dispatch('csatTemplates/get');
    this.$store.dispatch('csatTemplates/getStatus');
    this.$store.dispatch('csatTemplates/getCsatTrigger')
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
    updateCustomCsatEnabled(enabled) {
      this.$store.dispatch('csatTemplates/toggleSetting', enabled);
    },
    changeCsatTrigger(){
      this.$store.dispatch('csatTemplates/updateCsatTrigger', this.csatTrigger);
      this.showAlert('Successfully updated.');
    },
  },
  watch: {
    currentCsatTrigger(){
      if (this.currentCsatTrigger){
        this.csatTrigger = this.currentCsatTrigger;
      }
    },
  }
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
