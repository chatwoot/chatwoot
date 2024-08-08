<!-- eslint-disable vue/no-mutating-props -->
<template>
  <div class="conversation--form w-full">
    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PRODUCT') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="product"
            track-by="id"
            placeholder=""
            selected-label=""
            select-label=""
            deselect-label=""
            :custom-label="productLabel"
            :options="products"
            @select="onProductSelected"
            @input="inputChanged"
          >
            <template slot="option" slot-scope="{ option }">
              <span>{{ option.short_name }} - {{ option.name }}</span>
            </template>
          </multiselect>
        </div>
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
      </div>
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PO.FORM.PO_NOTE') }}
          <input v-model.trim="poNote" type="text" @input="inputChanged" />
        </label>
      </div>
    </div>
    <div
      v-if="branchAttribute || expectedTimeAttribute"
      class="gap-2 flex flex-row"
    >
      <div v-if="branchAttribute" class="w-[50%]">
        <label>
          {{ branchAttribute.attribute_display_name }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="branch"
            track-by="id"
            label="name"
            placeholder=""
            :max-height="160"
            :close-on-select="true"
            :options="branches"
            @input="inputChanged"
          />
        </div>
      </div>
      <div v-if="expectedTimeAttribute" class="w-[50%]">
        <label>
          {{ expectedTimeAttribute.attribute_display_name }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="expectedTime"
            track-by="id"
            label="name"
            placeholder=""
            :max-height="160"
            :close-on-select="true"
            :options="expectedTimes"
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
import { parseISO } from 'date-fns';

export default {
  components: {
    DatePicker,
  },
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
      branch: null,
      expectedTime: null,
    };
  },
  computed: {
    ...mapGetters({
      products: 'products/getProducts',
    }),
    branchAttribute() {
      return this.$store.getters['attributes/getAttributeByKey']('branch');
    },
    branches() {
      if (!this.branchAttribute) return null;
      return this.branchAttribute.attribute_values.map((value, index) => ({
        id: index + 1,
        name: value,
      }));
    },
    expectedTimeAttribute() {
      return this.$store.getters['attributes/getAttributeByKey'](
        'expected_time'
      );
    },
    expectedTimes() {
      if (!this.expectedTimeAttribute) return null;
      return this.expectedTimeAttribute.attribute_values.map(
        (value, index) => ({
          id: index + 1,
          name: value,
        })
      );
    },
  },
  mounted() {
    this.$store.dispatch('products/get');
    this.setDataObject();
  },
  methods: {
    setDataObject() {
      this.product = this.currentContact.product;
      this.poDate = this.currentContact.po_date
        ? parseISO(this.currentContact.po_date)
        : '';
      this.poValue = this.currentContact.po_value;
      this.poNote = this.currentContact.po_note;
      this.branch = this.branches.find(
        x => x.name === this.currentContact.custom_attributes?.branch
      );
      this.expectedTime = this.expectedTimes.find(
        x => x.name === this.currentContact.custom_attributes?.expected_time
      );
    },
    getDataObject() {
      const contact = {
        id: this.currentContact.id,
        product_id: this.product?.id || null,
        po_value: this.poValue || null,
        po_date: this.poDate || null,
        po_note: this.poNote || null,
      };

      let customAttributes = this.currentContact.custom_attributes;
      if (this.branch) {
        customAttributes = {
          ...customAttributes,
          branch: this.branch.name,
        };
      }
      if (this.expectedTime) {
        customAttributes = {
          ...customAttributes,
          expected_time: this.expectedTime.name,
        };
      }
      contact.custom_attributes = customAttributes;

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
