<!-- eslint-disable vue/no-mutating-props -->
<template>
  <div class="conversation--form w-full">
    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PRODUCT') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.product.$error }"
        >
          <multiselect
            v-model="product"
            track-by="id"
            :internal-search="false"
            placeholder=""
            selected-label=""
            select-label=""
            deselect-label=""
            :custom-label="productLabel"
            :options="products"
            @select="onProductSelected"
            @input="inputChanged"
            @search-change="searchChange"
          >
            <template slot="option" slot-scope="{ option }">
              <span>{{ option.short_name }} - {{ option.name }}</span>
            </template>
          </multiselect>
        </div>

        <label :class="{ error: $v.product.$error }">
          <span v-if="$v.product.$error" class="message">
            {{ $t('CONTACT_PO.FORM.ERROR') }}
          </span>
        </label>
      </div>
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_VALUE') }}
          <input v-model="poValue" type="number" @input="inputChanged" />
        </label>
      </div>
    </div>
    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_DATE') }}
        </label>
        <div class="date-picker">
          <date-picker
            v-model="poDate"
            type="date"
            :format="'DD/MM/YYYY'"
            @input="inputChanged"
          />
        </div>

        <label :class="{ error: $v.poDate.$error }">
          <span v-if="$v.poDate.$error" class="message">
            {{ $t('CONTACT_PO.FORM.ERROR') }}
          </span>
        </label>
      </div>
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_NOTE') }}
          <input v-model.trim="poNote" type="text" @input="inputChanged" />
        </label>
      </div>
    </div>

    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_AGENT') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.poAgent.$error }"
        >
          <multiselect
            v-model="poAgent"
            placeholder=""
            label="name"
            track-by="id"
            :options="agents"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
            @input="inputChanged"
          />
        </div>

        <label :class="{ error: $v.poAgent.$error }">
          <span v-if="$v.poAgent.$error" class="message">
            {{ $t('CONTACT_PO.FORM.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_TEAM') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="poTeam"
            placeholder=""
            label="name"
            track-by="id"
            :options="teams"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
            @input="inputChanged"
          />
        </div>
      </div>
    </div>

    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.ASSIGNEE') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="assignee"
            placeholder=""
            label="name"
            track-by="id"
            :options="agents"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
            @input="inputChanged"
          />
        </div>
      </div>

      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.TEAM') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="team"
            placeholder=""
            label="name"
            track-by="id"
            :options="teams"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
            @input="inputChanged"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import DatePicker from 'vue2-datepicker';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';

export default {
  components: {
    DatePicker,
  },
  mixins: [alertMixin],
  props: {
    currentContact: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      product: null,
      poValue: null,
      poDate: null,
      poNote: '',
      poAgent: null,
      poTeam: null,
      assignee: null,
      team: null,
      searchTimeout: null,
    };
  },
  validations: {
    product: {
      required,
    },
    poDate: {
      required,
    },
    poAgent: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      products: 'products/getProducts',
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
    }),
  },
  mounted() {
    this.$store.dispatch('products/get');
    this.$store.dispatch('agents/get');
    this.$store.dispatch('teams/get');
    this.setDataObject();
  },
  methods: {
    searchChange(query) {
      clearTimeout(this.searchTimeout);

      this.searchTimeout = setTimeout(() => {
        this.searchProducts(query);
      }, 500);
    },
    searchProducts(searchQuery) {
      let value = '';
      if (searchQuery.charAt(0) === '+') {
        value = searchQuery.substring(1);
      } else {
        value = searchQuery;
      }
      if (!value) {
        this.$store.dispatch('products/get');
      } else {
        this.$store.dispatch('products/search', {
          search: encodeURIComponent(value),
        });
      }
    },
    setDataObject() {
      this.poDate = new Date();
      this.poAgent = this.currentContact.assignee;
      this.poTeam = this.currentContact.team;
      this.assignee = this.currentContact.assignee;
      this.team = this.currentContact.team;
    },
    getDataObject() {
      const contact = {
        id: this.currentContact.id,
        product_id: this.product?.id || null,
        po_value: this.poValue || null,
        po_date: this.poDate || null,
        po_note: this.poNote || null,
        po_agent_id: this.poAgent?.id || null,
        po_team_id: this.poTeam?.id || null,
        assignee_id: this.assignee?.id || null,
        team_id: this.team?.id || null,
      };

      return contact;
    },
    onProductSelected() {
      this.poValue = this.product.price;
    },
    productLabel(product) {
      return `${product.short_name} - ${product.name}`;
    },
    inputChanged() {
      const contactItem = this.getDataObject();
      this.$emit('contact-data-changed', contactItem);
    },
  },
};
</script>
