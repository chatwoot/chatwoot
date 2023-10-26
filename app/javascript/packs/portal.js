import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import '../portal/application.scss';
import Vue from 'vue';
import { InitializationHelpers } from '../portal/portalHelpers';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';

Vue.use(VueDOMPurifyHTML, domPurifyConfig);

Rails.start();
Turbolinks.start();

document.addEventListener('turbolinks:load', InitializationHelpers.onLoad);
