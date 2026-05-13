import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import '../portal/application.scss';
import { InitializationHelpers } from '../portal/portalHelpers';

Rails.start();
Turbolinks.start();

document.addEventListener('turbolinks:load', InitializationHelpers.onLoad);
