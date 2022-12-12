import Vue = require("vue");

type Dictionary<T> = { [key: string]: T };

export function mapState (map: string[]): Dictionary<() => any>;
export function mapState (namespace: string, map: string[]): Dictionary<() => any>;
export function mapState (map: Dictionary<string>): Dictionary<() => any>;
export function mapState (namespace: string, map: Dictionary<string>): Dictionary<() => any>;
export function mapState <S>(
  map: Dictionary<(this: typeof Vue, state: S, getters: any) => any>
): Dictionary<() => any>;
export function mapState <S>(
  namespace: string,
  map: Dictionary<(this: typeof Vue, state: S, getters: any) => any>
): Dictionary<() => any>;

type MutationMethod = (...args: any[]) => void;
export function mapMutations (map: string[]): Dictionary<MutationMethod>;
export function mapMutations (namespace: string, map: string[]): Dictionary<MutationMethod>;
export function mapMutations (map: Dictionary<string>): Dictionary<MutationMethod>;
export function mapMutations (namespace: string, map: Dictionary<string>): Dictionary<MutationMethod>;

export function mapGetters (map: string[]): Dictionary<() => any>;
export function mapGetters (namespace: string, map: string[]): Dictionary<() => any>;
export function mapGetters (map: Dictionary<string>): Dictionary<() => any>;
export function mapGetters (namespace: string, map: Dictionary<string>): Dictionary<() => any>;

type ActionMethod = (...args: any[]) => Promise<any[]>;
export function mapActions (map: string[]): Dictionary<ActionMethod>;
export function mapActions (namespace: string, map: string[]): Dictionary<ActionMethod>;
export function mapActions (map: Dictionary<string>): Dictionary<ActionMethod>;
export function mapActions (namespace: string, map: Dictionary<string>): Dictionary<ActionMethod>;
