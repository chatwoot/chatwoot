// [NOTE][DEPRECATED] This method is to be deprecated, please do not add new components to this file.
/* eslint no-plusplus: 0 */
import AvatarUploader from './widgets/forms/AvatarUploader.vue';
import Code from './Code.vue';
import ColorPicker from './widgets/ColorPicker.vue';
import ConfirmDeleteModal from './widgets/modal/ConfirmDeleteModal.vue';
import ConfirmModal from './widgets/modal/ConfirmationModal.vue';
import DeleteModal from './widgets/modal/DeleteModal.vue';
import DropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import DropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import FeatureToggle from './widgets/FeatureToggle.vue';
import Input from './widgets/forms/Input.vue';
import PhoneInput from './widgets/forms/PhoneInput.vue';
import Label from './ui/Label.vue';
import LoadingState from './widgets/LoadingState.vue';
import ModalHeader from './ModalHeader.vue';
import Modal from './Modal.vue';
import SidemenuIcon from './SidemenuIcon.vue';
import Spinner from 'shared/components/Spinner.vue';
import Tabs from './ui/Tabs/Tabs.vue';
import TabsItem from './ui/Tabs/TabsItem.vue';
import Thumbnail from './widgets/Thumbnail.vue';
import DatePicker from './ui/DatePicker/DatePicker.vue';

const WootUIKit = {
  AvatarUploader,
  Code,
  ColorPicker,
  ConfirmDeleteModal,
  ConfirmModal,
  DeleteModal,
  DropdownItem,
  DropdownMenu,
  FeatureToggle,
  Input,
  PhoneInput,
  Label,
  LoadingState,
  Modal,
  ModalHeader,
  SidemenuIcon,
  Spinner,
  Tabs,
  TabsItem,
  Thumbnail,
  DatePicker,
  install(Vue) {
    const keys = Object.keys(this);
    keys.pop(); // remove 'install' from keys
    let i = keys.length;
    while (i--) {
      Vue.component(`woot${keys[i]}`, this[keys[i]]);
    }
  },
};

if (typeof window !== 'undefined' && window.Vue) {
  window.Vue.use(WootUIKit);
}

export default WootUIKit;
