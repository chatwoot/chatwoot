// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so that it will be compiled.

import Vue from 'vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import PublicArticleSearch from '../portal/components/PublicArticleSearch.vue';
import TableOfContents from '../portal/components/TableOfContents.vue';
import slugifyWithCounter from '@sindresorhus/slugify';

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

const setupTOC = () => {
  const isOnArticlePage = document.querySelector('#cw-hc-toc');
  if (isOnArticlePage) {
    const rows = [];
    const articleElement = document.getElementById('cw-article-content');
    articleElement.querySelectorAll('h1, h2, h3').forEach(element => {
      const slug = slugifyWithCounter(element.innerText);
      element.id = slug;
      element.className = 'scroll-mt-24 heading';
      element.innerHTML += `<a class="invisible text-slate-600 ml-3" href="#${slug}" title="${element.innerText}" data-turbolinks="false">#</a>`;
      rows.push({
        slug,
        title: element.innerText,
        tag: element.tagName.toLowerCase(),
      });
    });
    new Vue({
      components: { TableOfContents },
      data: { rows },
      template: '<table-of-contents :rows="rows" />',
    }).$mount('#cw-hc-toc');
  }
};

document.addEventListener('DOMContentLoaded', () => {
  initPageSetUp();
  setupTOC();
});

document.addEventListener('turbolinks:load', () => {
  initPageSetUp();
  setupTOC();
});
