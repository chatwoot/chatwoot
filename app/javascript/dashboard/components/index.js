/* eslint no-plusplus: 0 */
/* eslint-env browser */
import AvatarUploader from './widgets/forms/AvatarUploader.vue';
import Bar from './widgets/chart/BarChart';
import Button from './ui/WootButton';
import Code from './Code';
import ColorPicker from './widgets/ColorPicker';
import DeleteModal from './widgets/modal/DeleteModal.vue';
import ConfirmDeleteModal from './widgets/modal/ConfirmDeleteModal.vue';
import DropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import DropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';
import Input from './widgets/forms/Input.vue';
import Label from './ui/Label';
import LoadingState from './widgets/LoadingState';
import Modal from './Modal';
import ModalHeader from './ModalHeader';
import ReportStatsCard from './widgets/ReportStatsCard';
import SidemenuIcon from './SidemenuIcon';
import Spinner from 'shared/components/Spinner';
import SubmitButton from './buttons/FormSubmitButton';
import Tabs from './ui/Tabs/Tabs';
import TabsItem from './ui/Tabs/TabsItem';
import Thumbnail from './widgets/Thumbnail.vue';

const WootUIKit = {
  AvatarUploader,
  Bar,
  Button,
  Code,
  ColorPicker,
  DeleteModal,
  DropdownItem,
  DropdownMenu,
  Input,
  LoadingState,
  Label,
  Modal,
  ModalHeader,
  ReportStatsCard,
  SidemenuIcon,
  Spinner,
  SubmitButton,
  Tabs,
  TabsItem,
  Thumbnail,
  ConfirmDeleteModal,
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
