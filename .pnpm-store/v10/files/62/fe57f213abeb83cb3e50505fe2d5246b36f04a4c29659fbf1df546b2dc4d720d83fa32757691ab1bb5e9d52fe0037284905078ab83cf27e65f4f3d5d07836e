declare module '@breezystack/lamejs' {
  export class Mp3Encoder {
    constructor(channels: number, sampleRate: number, kbps: number);
    encodeBuffer(left: Int16Array, right?: Int16Array): Uint8Array;
    flush(): Uint8Array;
  }

  export class WavHeader {
    constructor();
    RIFF: number;
    WAVE: number;
    fmt_: number;
    data: number;
    readHeader: (buffer: ArrayBuffer | any) => void;
    toBuffer(): ArrayBuffer;
  }
}
