export declare const createBabelLoader: (options: any, framework: string) => {
    test: RegExp;
    use: {
        loader: string;
        options: any;
    }[];
    include: string[];
    exclude: RegExp;
};
