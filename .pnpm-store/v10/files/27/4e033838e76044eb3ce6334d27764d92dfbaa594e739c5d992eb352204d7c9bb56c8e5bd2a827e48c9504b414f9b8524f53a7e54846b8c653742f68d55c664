import Vue from 'vue';

declare class VueHcaptcha extends Vue {
    sitekey: string;
    theme?: string;
    size?: string;
    tabindex?: string;
    language?: string;
    reCaptchaCompat?: boolean;
    challengeContainer?: string;
    rqdata?: string;
    sentry?: boolean;
    custom?: boolean;
    endpoint?: string;
    reportapi?: string;
    assethost?: string;
    imghost?: string;

    execute(): void;
    executeAsync(): Promise<{ response: string, key: string }>;
    reset(): void;
}

export default VueHcaptcha;
