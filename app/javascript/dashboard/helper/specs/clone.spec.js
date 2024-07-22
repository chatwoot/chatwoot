import { describe, it, expect, vi } from 'vitest';
import { cloneObject } from '../clone'; // Update this path

describe('cloneObject', () => {
  it('should clone a simple object', () => {
    const original = { a: 1, b: 'string', c: true };
    const cloned = cloneObject(original);
    expect(cloned).toEqual(original);
    expect(cloned).not.toBe(original);
  });

  it('should clone a nested object', () => {
    const original = { a: 1, b: { c: 2, d: { e: 3 } } };
    const cloned = cloneObject(original);
    expect(cloned).toEqual(original);
    expect(cloned.b).not.toBe(original.b);
    expect(cloned.b.d).not.toBe(original.b.d);
  });

  it('should clone an array', () => {
    const original = [1, 2, [3, 4]];
    const cloned = cloneObject(original);
    expect(cloned).toEqual(original);
    expect(cloned).not.toBe(original);
    expect(cloned[2]).not.toBe(original[2]);
  });

  it('should clone a Date object', () => {
    const original = new Date();
    const cloned = cloneObject(original);
    expect(cloned).toEqual(original);
    expect(cloned).not.toBe(original);
  });

  it('should use structuredClone when available', () => {
    const structuredCloneSpy = vi.fn(x => x);
    global.structuredClone = structuredCloneSpy;
    const obj = { a: 1 };

    cloneObject(obj);

    expect(structuredCloneSpy).toHaveBeenCalledWith(obj);
    delete global.structuredClone;
  });

  it('should fall back to JSON methods when structuredClone is not available', () => {
    const jsonParseSpy = vi.spyOn(JSON, 'parse');
    const jsonStringifySpy = vi.spyOn(JSON, 'stringify');

    const original = { a: 1 };
    global.structuredClone = undefined;

    cloneObject(original);

    expect(jsonStringifySpy).toHaveBeenCalledWith(original);
    expect(jsonParseSpy).toHaveBeenCalled();

    jsonParseSpy.mockRestore();
    jsonStringifySpy.mockRestore();
  });
});
