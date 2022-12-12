declare type Deps = Record<string, string>;
interface PackageJson {
    dependencies?: Deps;
    devDependencies?: Deps;
}
export declare const getFrameworks: ({ dependencies, devDependencies }: PackageJson) => string[];
export {};
