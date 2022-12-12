import Vue, { VueConstructor } from 'vue';
import { SanitizerOptions } from 'lettersanitizer';

interface ILetter extends Vue {
  className: string;
  html: string;
  text: string;
  useIframe: boolean;
  iframeTitle: string;
  rewriteExternalLinks: (url: string) => string;
  rewriteExternalResources: (url: string) => string;
  allowedSchemas: string[];
  sanitizerOptions: SanitizerOptions;
  sanitizedHtml: string;
  iframeSrc: string;
  preserveCssPriority: boolean;
}

type Letter = VueConstructor<ILetter>;

export default Letter;
