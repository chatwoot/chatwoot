// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so that it will be compiled.

import Vue from 'vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import PublicArticleSearch from '../portal/components/PublicArticleSearch.vue';

import { navigateToLocalePage } from '../portal/portalHelpers';

import '../portal/application.scss';

Rails.start();
Turbolinks.start();

const initPageSetUp = () => {
  navigateToLocalePage();
  const isSearchContainerAvailable = document.querySelector('#search-wrap');
  if (isSearchContainerAvailable) {
    new Vue({
      components: { PublicArticleSearch },
      template: '<PublicArticleSearch />',
    }).$mount('#search-wrap');
  }
};

document.addEventListener('DOMContentLoaded', () => {
  initPageSetUp();
});

document.addEventListener('turbolinks:load', () => {
  initPageSetUp();
});
