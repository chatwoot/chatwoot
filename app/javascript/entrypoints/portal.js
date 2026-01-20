import Rails from '@rails/ujs';
import { Turbo } from '@hotwired/turbo-rails';
import '../portal/application.scss';
import { InitializationHelpers } from '../portal/portalHelpers';

Rails.start();
Turbo.start();

document.addEventListener('turbo:load', InitializationHelpers.onLoad);
