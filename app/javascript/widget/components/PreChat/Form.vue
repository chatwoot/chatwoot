<template>
  <form
    class="flex flex-1 flex-col p-6 overflow-y-auto smsp-form"
    @submit.prevent="onSubmit"
  >
    <div
      v-if="shouldShowHeaderMessage"
      class="text-black-800 text-sm leading-5"
    >
      {{ headerMessage }}
    </div>
    <form-input
      v-if="options.requireEmail"
      v-model="fullName"
      class="mt-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.PLACEHOLDER')"
      type="text"
      :error="
        $v.fullName.$error ? $t('PRE_CHAT_FORM.FIELDS.FULL_NAME.ERROR') : ''
      "
    />
    <form-input
      v-if="options.requireEmail"
      v-model="emailAddress"
      class="mt-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.PLACEHOLDER')"
      type="email"
      :error="
        $v.emailAddress.$error
          ? $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.ERROR')
          : ''
      "
    />
    <form-input
      v-model="phoneNumber"
      class="mt-5"
      :label="$t('Phone Number')"
      :placeholder="$t('ex: +62821234567890')"
      type="text"
      :error="
        $v.emailAddress.$error
          ? ''
          : ''
      "
    />
    <select v-model="cities" class="mt-5">
      <option v-for="(city, index) in courses" :value="city"
              v-bind:key="index">{{ city }}
      </option>
    </select>
    <!-- :error="$v.phoneNumber.$error ? $t('Please input with +62 format.') : ''" -->
    <form-text-area
      v-if="!hasActiveCampaign"
      v-model="message"
      class="my-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.PLACEHOLDER')"
      :error="$v.message.$error ? $t('PRE_CHAT_FORM.FIELDS.MESSAGE.ERROR') : ''"
    />
    <custom-button
      class="font-medium my-5"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      :disabled="isCreating"
    >
      <spinner v-if="isCreating" class="p-0" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </form>
</template>

<script>
import CustomButton from 'shared/components/Button';
import FormInput from '../Form/Input';
import FormTextArea from '../Form/TextArea';
import Spinner from 'shared/components/Spinner';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { required, minLength, email } from 'vuelidate/lib/validators';
import { isEmptyObject } from 'widget/helpers/utils';
import routerMixin from 'widget/mixins/routerMixin';
export default {
  components: {
    FormInput,
    FormTextArea,
    CustomButton,
    Spinner,
  },
  mixins: [routerMixin],
  props: {
    options: {
      type: Object,
      default: () => ({}),
    },
  },
  validations() {
    const identityValidations = {
      fullName: {
        required,
      },
      emailAddress: {
        required,
        email,
      },
    };

    const messageValidation = {
      message: {
        required,
        minLength: minLength(1),
      },
    };
    // For campaign, message field is not required
    if (this.hasActiveCampaign) {
      return identityValidations;
    }
    if (this.options.requireEmail) {
      return {
        ...identityValidations,
        ...messageValidation,
      };
    }
    return messageValidation;
  },
  data() {
    return {
      fullName: '',
      emailAddress: '',
      phoneNumber: '',
      message: '',
      cities:[
        'Kabupaten Aceh Barat',
        'Kabupaten Aceh Barat Daya',
        'Kabupaten Aceh Besar',
        'Kabupaten Aceh Jaya',
        'Kabupaten Aceh Selatan',
        'Kabupaten Aceh Singkil',
        'Kabupaten Aceh Tamiang',
        'Kabupaten Aceh Tengah',
        'Kabupaten Aceh Tenggara',
        'Kabupaten Aceh Timur',
        'Kabupaten Aceh Utara',
        'Kabupaten Bener Meriah',
        'Kabupaten Bireuen',
        'Kabupaten Gayo Lues',
        'Kabupaten Nagan Raya',
        'Kabupaten Pidie',
        'Kabupaten Pidie Jaya',
        'Kabupaten Simeulue',
        'Kota Banda Aceh',
        'Kota Langsa',
        'Kota Lhokseumawe',
        'Kota Sabang',
        'Kota Subulussalam',
        'Kabupaten Badung',
        'Kabupaten Bangil',
        'Kabupaten Buleleng',
        'Kabupaten Gianyar',
        'Kabupaten Jembrana',
        'Kabupaten Karangasem',
        'Kabupaten Klungkung',
        'Kabupaten Tabanan',
        'Kota Denpasar',
        'Kabupaten Lebak',
        'Kabupaten Pandeglang',
        'Kabupaten Serang',
        'Kabupaten Tangerang',
        'Kota Cilegon',
        'Kota Serang',
        'Kota Tangerang',
        'Kota Tangerang selatan',
        'Kabupaten Bengkulu Selatan',
        'Kabupaten Bemgkulu Tengah',
        'Kabupaten Bengkulu Utara',
        'Kabupaten Kaur',
        'Kabupaten kapahiang',
        'Kabupaten Lebong',
        'Kabupaten Mukomuko',
        'Kabupaten Rejang Lebong',
        'Kabupaten seluma',
        'Kota Bengkulu',
        'Kabupaten Bantul',
        'Kabupaten Gunung kildul',
        'Kabupaten Kulon Progo',
        'Kabupaten Sleman',
        'Kota Yogyakarta',
        'Kabupaten Kepulauan Seribu',
        'Kota Jakarta Barat',
        'Kota Jakarta Pusat',
        'Kota Jakarta Selatan',
        'Kota Jakarta Timur',
        'Kota Jakarta Utara',
        'Kabupaten Boalemo',
        'Kabupaten Bone Bolango',
        'Kabupaten Gorontalo',
        'Kabupaten gorontalo Utara',
        'Kabupaten Pahuwato',
        'Kota Gorontalo',
        'Kabupaten Batanghari',
        'Kabupaten Bungo',
        'Kabupaten Kerinci',
        'Kabupaten Merangin',
        'Kabupaten Muaro Jambi',
        'Kabupaten Sarolangun',
        'Kabupaten Tanjung Jabung Barat',
        'Kabupaten Tanjung Jabung Timur',
        'Kabupaten Tebo',
        'Kota Jambi',
        'Kota Sungai Penuh',
        'Kabupaten Bandung',
        'Kabupaten Bandung Barat',
        'Kabupaten Bekasi',
        'Kabupaten Bogor',
        'Kabupaten Ciamis',
        'Kabupaten Cianjur',
        'Kabupaten Cirebon',
        'Kabupaten Garut',
        'Kabupaten Indramayu',
        'Kabupaten Karawang',
        'Kabupaten Kuningan',
        'Kabupaten Majalengka',
        'Kabupaten Pangandaran',
        'Kabupaten Purwakarta',
        'Kabupaten Subang',
        'Kabupaten Sukabumi',
        'Kabupaten Sumedang',
        'Kabupaten Tasikmalaya',
        'Kota Bandung',
        'Kota Banjar',
        'Kota Bekasi',
        'Kota Bogor',
        'Kota Cimahi',
        'Kota Cirebon',
        'Kota Depok',
        'Kota Sukabumi',
        'Kota Tasikmalaya',
        'Kabupaten Banjarnegara',
        'Kabupaten Banyumas',
        'Kabupaten Batang',
        'Kabupaten Blora',
        'Kabupaten Boyolali',
        'Kabupaten Brebes',
        'Kabupaten Cilacap',
        'Kabupaten Demak',
        'Kabupaten Grobogan',
        'Kabupaten Jepara',
        'Kabupaten Karanganyar',
        'Kabupaten Kebumen',
        'Kabupaten Kendal',
        'Kabupaten Klaten',
        'Kabupaten Kudus',
        'Kabupaten Magelang',
        'Kabupaten Pati',
        'Kabupaten Pekalongan',
        'Kabupaten Pemalang',
        'Kabupaten Purbalingga',
        'Kabupaten Purworejo',
        'Kabupaten Rembang',
        'Kabupaten Semarang',
        'Kabupaten Sragen',
        'Kabupaten Sukoharjo',
        'Kabupaten Tegal',
        'Kabupaten Temanggung',
        'Kabupaten Wonogiri',
        'Kabupaten Wonosobo',
        'Kota Magelang',
        'Kota Pekalongan',
        'Kota Salatiga',
        'Kota Semarang',
        'Kota Surakarta',
        'Kota Tegal',
        'Kabupaten Bangkalan',
        'Kabupaten Banyuwangi',
        'Kabupaten Blitar',
        'Kabupaten Bojonegoro',
        'Kabupaten Bondowoso',
        'Kabupaten Gresik',
        'Kabupaten Jember',
        'Kabupaten Jombang',
        'Kabupaten Kediri',
        'Kabupaten Lamongan',
        'Kabupaten Lumajang',
        'Kabupaten Madiun',
        'Kabupaten Magetan',
        'Kabupaten Malang',
        'Kabupaten Mojokerto',
        'Kabupaten Nganjuk',
        'Kabupaten Ngawi',
        'Kabupaten Pacitan',
        'Kabupaten Pamekasan',
        'Kabupaten Pasuruan',
        'Kabupaten Ponorogo',
        'Kabupaten Probolinggo',
        'Kabupaten Sampang',
        'Kabupaten Sidoarjo',
        'Kabupaten Situbondo',
        'Kabupaten Sumenep',
        'Kabupaten Trenggalek',
        'Kabupaten Tuban',
        'Kabupaten Tulungagung',
        'Kota Batu',
        'Kota Blitar',
        'Kota Kediri',
        'Kota Madiun',
        'Kota Malang',
        'Kota Mojokerto',
        'Kota Pasuruan',
        'Kota Probolinggo',
        'Kota Surabaya',
        'Kabupaten Bengkayang',
        'Kabupaten Kapuas Hulu',
        'Kabupaten Kayong Utara',
        'Kabupaten Ketapang',
        'Kabupaten Kubu Raya',
        'Kabupaten Landak',
        'Kabupaten Melawi',
        'Kabupaten Pontianak',
        'Kabupaten Sambas',
        'Kabupaten Sanggau',
        'Kabupaten Sekadau',
        'Kabupaten Sintang',
        'Kota Pontianak',
        'Kota Singkawang',
        'Kabupaten Balangan',
        'Kabupaten Banjar',
        'Kabupaten Barito Kuala',
        'Kabupaten Hulu Sungai Selatan',
        'Kabupaten Hulu Sungai Tengah',
        'Kabupaten Hulu Sungai Utara',
        'Kabupaten Kotabaru',
        'Kabupaten Tabalong',
        'Kabupaten Tanah Bumbu',
        'Kabupaten Tanah Laut',
        'Kabupaten Tapin',
        'Kota Banjarbaru',
        'Kota Banjarmasin',
        'Kabupaten Barito Selatan',
        'Kabupaten Barito Timur',
        'Kabupaten Barito Utara',
        'Kabupaten Gunung Mas',
        'Kabupaten Kapuas',
        'Kabupaten Katingan',
        'Kabupaten Kotawaringin Barat',
        'Kabupaten Kotawaringin Timur',
        'Kabupaten Lamandau',
        'Kabupaten Murung Raya',
        'Kabupaten Pulang Pisau',
        'Kabupaten Sukamara',
        'Kabupaten Seruyan',
        'Kota Palangka Raya',
        'Kabupaten Berau',
        'Kabupaten Kutai Barat',
        'Kabupaten Kutai Kartanegara',
        'Kabupaten Kutai Timur',
        'Kabupaten Paser',
        'Kabupaten Penajam Paser Utara',
        'Kabupaten Mahakam Ulu',
        'Kota Balikpapan',
        'Kota Bontang',
        'Kota Samarinda',
        'Kabupaten Bulungan',
        'Kabupaten Malinau',
        'Kabupaten Nunukan',
        'Kabupaten Tana Tidung',
        'Kota Tarakan',
        'Kabupaten Bangka',
        'Kabupaten Bangka Barat',
        'Kabupaten Bangka Selatan',
        'Kabupaten Bangka Tengah',
        'Kabupaten Belitung',
        'Kabupaten Belitung Timur',
        'Kota Pangkal Pinang',
        'Kabupaten Bintan',
        'Kabupaten Karimun',
        'Kabupaten Kepulauan Anambas',
        'Kabupaten Lingga',
        'Kabupaten Natuna',
        'Kota Batam',
        'Kota Tanjung Pinang',
        'Kabupaten Lampung Barat',
        'Kabupaten Lampung Selatan',
        'Kabupaten Lampung Tengah',
        'Kabupaten Lampung Timur',
        'Kabupaten Lampung Utara',
        'Kabupaten Mesuji',
        'Kabupaten Pesawaran',
        'Kabupaten Pringsewu',
        'Kabupaten Tanggamus',
        'Kabupaten Tulang Bawang',
        'Kabupaten Tulang Bawang Barat',
        'Kabupaten Way Kanan',
        'Kabupaten Pesisir Barat',
        'Kota Bandar Lampung',
        'Kota Kotabumi',
        'Kota Liwa',
        'Kota Metro',
        'Kabupaten Buru',
        'Kabupaten Buru Selatan',
        'Kabupaten Kepulauan Aru',
        'Kabupaten Maluku Barat Daya',
        'Kabupaten Maluku Tengah',
        'Kabupaten Maluku Tenggara',
        'Kabupaten Maluku Tenggara Barat',
        'Kabupaten Seram Bagian Barat',
        'Kabupaten Seram Bagian Timur',
        'Kota Ambon',
        'Kota Tual',
        'Kabupaten Halmahera Barat',
        'Kabupaten Halmahera Tengah',
        'Kabupaten Halmahera Utara',
        'Kabupaten Halmahera Selatan',
        'Kabupaten Halmahera Timur',
        'Kabupaten Kepulauan Sula',
        'Kabupaten Pulau Morotai',
        'Kabupaten Pulau Taliabu',
        'Kota Ternate',
        'Kota Tidore Kepulauan',
        'Kabupaten Bima',
        'Kabupaten Dompu',
        'Kabupaten Lombok Barat',
        'Kabupaten Lombok Tengah',
        'Kabupaten Lombok Timur',
        'Kabupaten Lombok Utara',
        'Kabupaten Sumbawa',
        'Kabupaten Sumbawa Barat',
        'Kota Bima',
        'Kota Mataram',
        'Kabupaten Alor',
        'Kabupaten Belu',
        'Kabupaten Ende',
        'Kabupaten Flores Timur',
        'Kabupaten Kupang',
        'Kabupaten Lembata',
        'Kabupaten Manggarai',
        'Kabupaten Manggarai Barat',
        'Kabupaten Manggarai Timur',
        'Kabupaten Ngada',
        'Kabupaten Nagekeo',
        'Kabupaten Rote Ndao',
        'Kabupaten Sabu Raijua',
        'Kabupaten Sikka',
        'Kabupaten Sumba Barat',
        'Kabupaten Sumba Barat Daya',
        'Kabupaten Sumba Tengah',
        'Kabupaten Sumba Timur',
        'Kabupaten Timor Tengah Selatan',
        'Kabupaten Timor Tengah Utara',
        'Kota Kupang',
        'Kabupaten Asmat',
        'Kabupaten Biak Numfor',
        'Kabupaten Boven Digoel',
        'Kabupaten Deiyai',
        'Kabupaten Dogiyai',
        'Kabupaten Intan Jaya',
        'Kabupaten Jayapura',
        'Kabupaten Jayawijaya',
        'Kabupaten Keerom',
        'Kabupaten Kepulauan Yapen',
        'Kabupaten Lanny Jaya',
        'Kabupaten Mamberamo Raya',
        'Kabupaten Mamberamo Tengah',
        'Kabupaten Mappi',
        'Kabupaten Merauke',
        'Kabupaten Mimika',
        'Kabupaten Nabire',
        'Kabupaten Nduga',
        'Kabupaten Paniai',
        'Kabupaten Pegunungan Bintang',
        'Kabupaten Puncak',
        'Kabupaten Puncak Jaya',
        'Kabupaten Sarmi',
        'Kabupaten Supiori',
        'Kabupaten Tolikara',
        'Kabupaten Waropen',
        'Kabupaten Yahukimo',
        'Kabupaten Yalimo',
        'Kota Jayapura',
        'Kabupaten Fakfak',
        'Kabupaten Kaimana',
        'Kabupaten Manokwari',
        'Kabupaten Manokwari Selatan',
        'Kabupaten Maybrat',
        'Kabupaten Pegunungan Arfak',
        'Kabupaten Raja Ampat',
        'Kabupaten Sorong',
        'Kabupaten Sorong Selatan',
        'Kabupaten Tambrauw',
        'Kabupaten Teluk Bintuni',
        'Kabupaten Teluk Wondama',
        'Kota Sorong',
        'Kabupaten Bengkalis',
        'Kabupaten Indragiri Hilir',
        'Kabupaten Indragiri Hulu',
        'Kabupaten Kampar',
        'Kabupaten Kuantan Singingi',
        'Kabupaten Pelalawan',
        'Kabupaten Rokan Hilir',
        'Kabupaten Rokan Hulu',
        'Kabupaten Siak',
        'Kabupaten Kepulauan Meranti',
        'Kota Dumai',
        'Kota Pekanbaru',
        'Kabupaten Majene',
        'Kabupaten Mamasa',
        'Kabupaten Mamuju',
        'Kabupaten Mamuju Utara',
        'Kabupaten Polewali Mandar',
        'Kabupaten Mamuju Tengah',
        'Kabupaten Bantaeng',
        'Kabupaten Barru',
        'Kabupaten Bone	Watampone',
        'Kabupaten Bulukumba',
        'Kabupaten Enrekang',
        'Kabupaten Gowa',
        'Kabupaten Jeneponto',
        'Kabupaten Kepulauan Selayar',
        'Kabupaten Luwu',
        'Kabupaten Luwu Timur',
        'Kabupaten Luwu Utara',
        'Kabupaten Maros',
        'Kabupaten Pangkajene dan Kepulauan',
        'Kabupaten Pinrang',
        'Kabupaten Sidenreng Rappang',
        'Kabupaten Sinjai',
        'Kabupaten Soppeng',
        'Kabupaten Takalar',
        'Kabupaten Tana Toraja',
        'Kabupaten Toraja Utara',
        'Kabupaten Wajo',
        'Kota Makassar',
        'Kota Palopo',
        'Kota Parepare',
        'Kabupaten Banggai',
        'Kabupaten Banggai Kepulauan',
        'Kabupaten Banggai Laut',
        'Kabupaten Buol',
        'Kabupaten Donggala',
        'Kabupaten Morowali',
        'Kabupaten Parigi Moutong',
        'Kabupaten Poso',
        'Kabupaten Sigi',
        'Kabupaten Tojo Una-Una',
        'Kabupaten Tolitoli',
        'Kota Palu',
        'Kabupaten Bombana',
        'Kabupaten Buton',
        'Kabupaten Buton Utara',
        'Kabupaten Kolaka',
        'Kabupaten Kolaka Timur',
        'Kabupaten Kolaka Utara',
        'Kabupaten Konawe',
        'Kabupaten Konawe Selatan',
        'Kabupaten Konawe Utara',
        'Kabupaten Konawe Kepulauan',
        'Kabupaten Muna',
        'Kabupaten Wakatobi',
        'Kota Bau-Bau',
        'Kota Kendari',
        'Kabupaten Bolaang Mongondow',
        'Kabupaten Bolaang Mongondow Selatan',
        'Kabupaten Bolaang Mongondow Timur',
        'Kabupaten Bolaang Mongondow Utara',
        'Kabupaten Kepulauan Sangihe',
        'Kabupaten Kepulauan Siau Tagulandang Biaro',
        'Kabupaten Kepulauan Talaud',
        'Kabupaten Minahasa',
        'Kabupaten Minahasa Selatan',
        'Kabupaten Minahasa Tenggara',
        'Kabupaten Minahasa Utara',
        'Kota Bitung',
        'Kota Kotamobagu',
        'Kota Manado',
        'Kota Tomohon',
        'Kabupaten Agam',
        'Kabupaten Dharmasraya',
        'Kabupaten Kepulauan Mentawai',
        'Kabupaten Lima Puluh Kota',
        'Kabupaten Padang Pariaman',
        'Kabupaten Pasaman',
        'Kabupaten Pasaman Barat',
        'Kabupaten Pesisir Selatan',
        'Kabupaten Sijunjung',
        'Kabupaten Solok',
        'Kabupaten Solok Selatan',
        'Kabupaten Tanah Datar',
        'Kota Bukittinggi',
        'Kota Padang',
        'Kota Padangpanjang',
        'Kota Pariaman',
        'Kota Payakumbuh',
        'Kota Sawahlunto',
        'Kota Solok',
        'Kabupaten Banyuasin',
        'Kabupaten Empat Lawang',
        'Kabupaten Lahat',
        'Kabupaten Muara Enim',
        'Kabupaten Musi Banyuasin',
        'Kabupaten Musi Rawas',
        'Kabupaten Ogan Ilir',
        'Kabupaten Ogan Komering Ilir',
        'Kabupaten Ogan Komering Ulu',
        'Kabupaten Ogan Komering Ulu Selatan',
        'Kabupaten Penukal Abab Lematang Ilir',
        'Kabupaten Ogan Komering Ulu Timur',
        'Kota Lubuklinggau',
        'Kota Pagar Alam',
        'Kota Palembang',
        'Kota Prabumulih',
        'Kabupaten Asahan',
        'Kabupaten Batubara',
        'Kabupaten Dairi',
        'Kabupaten Deli Serdang',
        'Kabupaten Humbang Hasundutan',
        'Kabupaten Karo	Kabanjahe',
        'Kabupaten Labuhanbatu',
        'Kabupaten Labuhanbatu Selatan',
        'Kabupaten Labuhanbatu Utara',
        'Kabupaten Langkat',
        'Kabupaten Mandailing Natal',
        'Kabupaten Nias',
        'Kabupaten Nias Barat',
        'Kabupaten Nias Selatan',
        'Kabupaten Nias Utara',
        'Kabupaten Padang Lawas',
        'Kabupaten Padang Lawas Utara',
        'Kabupaten Pakpak Bharat',
        'Kabupaten Samosir',
        'Kabupaten Serdang Bedagai',
        'Kabupaten Simalungun',
        'Kabupaten Tapanuli Selatan',
        'Kabupaten Tapanuli Tengah',
        'Kabupaten Tapanuli Utara',
        'Kabupaten Toba Samosir',
        'Kota Binjai',
        'Kota Gunungsitoli',
        'Kota Medan',
        'Kota Padangsidempuan',
        'Kota Pematangsiantar',
        'Kota Sibolga',
        'Kota Tanjungbalai',
        'Kota Tebing Tinggi',
      ]
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      isCreating: 'conversation/getIsCreating',
      activeCampaign: 'campaign/getActiveCampaign',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    hasActiveCampaign() {
      return !isEmptyObject(this.activeCampaign);
    },
    shouldShowHeaderMessage() {
      return this.hasActiveCampaign || this.options.preChatMessage;
    },
    headerMessage() {
      if (this.hasActiveCampaign) {
        return this.$t('PRE_CHAT_FORM.CAMPAIGN_HEADER');
      }
      return this.options.preChatMessage;
    },
  },
  methods: {
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      if (this.phoneNumber.charAt(0) === '0') {
        this.phoneNumber = this.phoneNumber.replace('0', '+62');
      }
      // window.dataLayer.push({
      //   'event': "ChatwootFormSubmit", 
      //   'formSubmit': "chatwoot form submitted",
      // })
      let payload = {
        fullName: this.fullName,
        emailAddress: this.emailAddress,
        phoneNumber: this.phoneNumber,
        message: this.message,
        //location: this.cities
      }
      console.log("hehe", payload)
      //send prechat form data to parent window - smsp main website
      window.parent.postMessage({ message: "getPrechatData", value: payload, event:'chatwootFormSubmit' }, "*");
      this.$emit('submit', {
        fullName: this.fullName,
        emailAddress: this.emailAddress,
        phoneNumber: this.phoneNumber,
        message: this.message,
        activeCampaignId: this.activeCampaign.id,
      });
    },
  },
};
</script>
