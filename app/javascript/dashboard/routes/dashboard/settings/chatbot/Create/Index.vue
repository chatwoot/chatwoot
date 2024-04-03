<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" rel="stylesheet">
    <back-button class="absolute top-[17px] left-[420px]" />
    <!-- sidebar icons -->
    <div class="sidebar">
      <div class="icon" @click="showUploader('file')" :class="{ 'active': showFileUploader }">
        <img width="30" height="30" src="https://img.icons8.com/ios/50/000000/file--v1.png" alt="file--v1"/>
        <span>{{ $t('CHATBOT_SETTINGS.UPLOAD.FILE') }}</span>
      </div>
      <div class="icon" @click="showText()" :class="{ 'active': showTextInput }">
        <img width="30" height="30" src="https://img.icons8.com/ios/50/000000/edit-text-file.png" alt="edit-text-file"/>
        <span>{{ $t('CHATBOT_SETTINGS.UPLOAD.TEXT') }}</span>
      </div>
      <div class="icon" @click="showUploader('website')" :class="{ 'active': showWebsiteUploader }">
        <img width="30" height="30" src="https://img.icons8.com/ios/50/000000/domain--v1.png" alt="domain--v1"/>
        <span>{{ $t('CHATBOT_SETTINGS.UPLOAD.WEBSITE') }}</span>
      </div>
    </div>
    <!-- content: [file , text, website] -->
    <div class="content">
      <!-- file uploader component -->
      <div v-if="showFileUploader" class="uploader">
        <file-uploader />
        <div v-if="botFiles.length > 0" class="file-names-container">
          <ul class="file-names">
            <li v-for="(file, index) in botFiles" :key="index" class="file-item">
              <input type="text" :value="file.name" readonly />
              <span class="delete-icon" @click="deleteFile(index)"><i class="fas fa-trash-alt"></i></span>
            </li>
          </ul>
        </div>
      </div>
      <!-- input field component -->
      <div class="text-input" v-if="showTextInput">
        <textarea v-model="textInput" @input="setText" @focus="isTextInputFocused = true" @blur="isTextInputFocused = false" placeholder="Enter your text here"></textarea>
      </div>
      <!-- website field component -->
      <div v-if="showWebsiteUploader" class="website-input">
        <input type="text" placeholder="Enter website URL" v-model="websiteInput" />
        <button class="button" @click="addWebsite">
          {{ $t('CHATBOT_SETTINGS.FORM.ADD_URL') }}
        </button>
        <div class="website-urls-container">
          <ul class="website-urls">
            <li v-for="(url, index) in websiteUrls" :key="index" class="url-item">
              <input type="text" :value="url" readonly />
              <span class="delete-icon" @click="deleteUrl(index)"><i class="fas fa-trash-alt"></i></span>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <router-link :to="addAccountScoping(`settings/chatbot/create/connect_inbox`)">
        <woot-button
          class-names="button--fixed-top"
          :button-text="$t('CHATBOT_SETTINGS.FORM.CONNECT_INBOX')"
        >
          {{ $t('CHATBOT_SETTINGS.FORM.CONNECT_INBOX') }}
        </woot-button>
      </router-link>
  </div>
</template>

<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from '../../../../../mixins/account';
import BackButton from '../../../../../components/widgets/BackButton.vue';
import FileUploader from './FileUploader.vue';

export default {
  components: {
    BackButton,
    FileUploader,
  },
  mixins: [alertMixin, accountMixin],
  data() {
    return {
      enabledFeatures: {},
      showFileUploader: false,
      showTextInput: false,
      showWebsiteUploader: false,
      textInput: '',
      websiteInput: '',
      isTextInputFocused: false,
      isLoading: false,
    };
  },
  computed: {
    ...mapState({
      botText: state => state.chatbot.botText,
    }),
    ...mapGetters('chatbot', ['getBotFiles', 'getBotUrls']),
    botFiles() {
      return this.getBotFiles;
    },
    websiteUrls() {
      return this.getBotUrls;
    },
  },
  created() {
    this.showFileUploader = true;
  },
  methods: {
    ...mapActions('chatbot', ['addBotUrl', 'setBotText', 'addBotFiles', 'deleteBotFile', 'deleteBotUrl']),
    showUploader(type) {
      if (type === 'file') {
        this.showFileUploader = true;
        this.showTextInput = false;
        this.showWebsiteUploader = false;
      } else if (type === 'website') {
        this.showFileUploader = false;
        this.showTextInput = false;
        this.showWebsiteUploader = true;
      }
    },
    showText() {
      this.showFileUploader = false;
      this.showTextInput = true;
      this.showWebsiteUploader = false;
    },
    addWebsite() {
      const websiteUrl = this.websiteInput.trim();
      if (websiteUrl) {
        this.addBotUrl(websiteUrl);
        this.websiteInput = '';
      } else {
        console.error('Empty website URL');
      }
    },
    setText() {
      const text = this.textInput;
      this.setBotText(text);
    },
    deleteFile(index) {
      this.deleteBotFile(index);
    },
    deleteUrl(index) {
      this.deleteBotUrl(index);
    },
  },
};
</script>

<style scoped>
.file-item,
.url-item {
  display: flex;
  align-items: center;
}

.delete-icon {
  cursor: pointer;
  margin-left: 10px;
  color: red;
  margin-top: -17px;
}
.icon.active span {
  color: #488aec;
}
.file-names-container {
  margin-top: 50px;
  max-height: 330px;
  overflow-y: auto; /* Enable vertical scrolling */
  background-color: #ffffff;
}

input{
  border: 1px solid #000000;
  background-color: #ffffff;

}
.website-urls-container {
  margin-top: 65px;
  max-height: 500px;
  overflow-y: auto; /* Enable vertical scrolling */
}

.website-urls,
.file-names {
  margin-top: 5px;
  padding-right: 10px; /* Add some padding to prevent content from sticking to the scrollbar */
}

.button {
  border: none;
  display: flex;
  padding: 0.75rem 1.5rem;
  background-color: #488aec;
  color: #ffffff;
  font-size: 0.75rem;
  line-height: 1rem;
  font-weight: 700;
  text-align: center;
  text-transform: uppercase;
  vertical-align: middle;
  align-items: center;
  border-radius: 0.5rem;
  user-select: none;
  gap: 0.75rem;
  box-shadow: 0 4px 6px -1px #488aec31, 0 2px 4px -1px #488aec17;
  transition: all .6s ease;
  width: auto;
  max-width: 100%;
  margin: 0 auto; 
  position: fixed;
  z-index: 999;
}

.button:hover {
  box-shadow: 0 10px 15px -3px #488aec4f, 0 4px 6px -2px #488aec17;
}

.button:focus,
.button:active {
  opacity: .85;
  box-shadow: none;
}

.button svg {
  width: 1.25rem;
  height: 1.25rem;
}

.wizard-body {
  display: flex;
}

.sidebar {
  width: 200px;
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.icon {
  cursor: pointer;
  display: flex;
  align-items: center;
  margin-bottom: 40px;
}

.icon img {
  width: 30px;
  height: 30px;
  margin-right: 10px;
}

.content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.text-input,
.website-input {
  width: 100%;
  margin: 0 auto;
}

.website-input button {
  margin-left: 17%;
}

.text-input textarea {
  width: 100%;
  height: 300px;
  overflow: auto; /* Enable scrolling with automatic scrollbar display */
  scrollbar-width: none; /* Hide scrollbar for Firefox */
  -ms-overflow-style: none; /* Hide scrollbar for Internet Explorer and Edge */
}
.text-input textarea::-webkit-scrollbar {
  display: none; /* Hide scrollbar for Webkit browsers (Chrome, Safari) */
}

.uploader input,
.website-input input {
  width: 100%;
  height: 40px;
  padding: 0.5rem;
}
/* Hide scrollbar for webkit browsers (Chrome, Safari, etc.) */
.file-names-container::-webkit-scrollbar,
.website-urls-container::-webkit-scrollbar {
  display: none;
}

/* Hide scrollbar for Firefox */
.website-urls-container {
  scrollbar-width: none;
}
</style>
