import { ErrorProperties } from '../extensions/exception-autocapture/error-conversion';
declare const posthogErrorWrappingFunctions: {
    wrapOnError: (captureFn: (props: ErrorProperties) => void) => () => void;
    wrapUnhandledRejection: (captureFn: (props: ErrorProperties) => void) => () => void;
    wrapConsoleError: (captureFn: (props: ErrorProperties) => void) => () => void;
};
export default posthogErrorWrappingFunctions;
