// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so that it will be compiled.

import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';

import { navigateToLocalePage } from '../portal/portalHelpers';

import '../portal/application.scss';

Rails.start();
Turbolinks.start();

document.addEventListener('DOMContentLoaded', navigateToLocalePage);
