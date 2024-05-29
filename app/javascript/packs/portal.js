import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import '../portal/application.scss';
import Vue from 'vue';
import { InitializationHelpers } from '../portal/portalHelpers';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
import { directive as onClickaway } from 'vue-clickaway';

Vue.use(VueDOMPurifyHTML, domPurifyConfig);
Vue.directive('on-clickaway', onClickaway);

Rails.start();
Turbolinks.start();

document.addEventListener('turbolinks:load', InitializationHelpers.onLoad);
