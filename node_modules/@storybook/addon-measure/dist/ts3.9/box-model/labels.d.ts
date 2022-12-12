declare type LabelType = 'margin' | 'padding' | 'border' | 'content';
declare type LabelPosition = 'top' | 'right' | 'bottom' | 'left' | 'center';
export interface Label {
    type: LabelType;
    text: number | string;
    position: LabelPosition;
}
export declare type LabelStack = Label[];
export declare function drawFloatingLabel(context: CanvasRenderingContext2D, measurements: ElementMeasurements, { type, text }: Label): {
    x: number;
    y: number;
    w: number;
    h: number;
};
export declare function labelStacks(context: CanvasRenderingContext2D, measurements: ElementMeasurements, labels: LabelStack, externalLabels: boolean): void;
export {};
