type Mode = "binary" | "metric" | "decimal" | "compatibility" | "jedec";
type BinaryUnit = "B" | "kiB" | "MiB" | "GiB" | "TiB" | "PiB" | "EiB" | "ZiB" | "YiB";
type DecimalUnit = "B" | "kB" | "MB" | "GB" | "TB" | "PB" | "EB" | "ZB" | "YB";

interface ParseOptions {
    mode?: Mode;
}

declare function parse(value: number | string, options?: ParseOptions): number | null;

interface FormatOptions {
    decimalPlaces?: number;
    fixedDecimals?: boolean;
    mode?: Mode;
    thousandsSeparator?: string;
    unit?: BinaryUnit | DecimalUnit;
    unitSeparator?: string;
}

declare function format(value: number, options?: FormatOptions): string | null;

declare function withDefaultMode(mode: Mode): ByteConverter;

type ByteConverter = typeof format & {
    format: typeof format;
    parse: typeof parse;
    withDefaultMode: typeof withDefaultMode;
};

declare const instance: ByteConverter;

declare module "bytes-iec" {
    export = instance;
}
