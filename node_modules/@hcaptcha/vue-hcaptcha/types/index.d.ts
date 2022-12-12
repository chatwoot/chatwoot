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
    endpoint?: string;
    reportapi?: string;
    assethost?: string;
    imghost?: string;

    execute(): void;
    reset(): void;
}

export default VueHcaptcha;
