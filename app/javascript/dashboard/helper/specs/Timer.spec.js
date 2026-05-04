import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import Timer from '../Timer';

describe('Timer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  describe('constructor', () => {
    it('initializes with elapsed 0 and no interval', () => {
      const timer = new Timer();
      expect(timer.elapsed).toBe(0);
      expect(timer.intervalId).toBeNull();
    });

    it('accepts an onTick callback', () => {
      const onTick = vi.fn();
      const timer = new Timer(onTick);
      expect(timer.onTick).toBe(onTick);
    });
  });

  describe('start', () => {
    it('starts the timer and increments elapsed every second', () => {
      const timer = new Timer();
      timer.start();

      expect(timer.elapsed).toBe(0);

      vi.advanceTimersByTime(1000);
      expect(timer.elapsed).toBe(1);

      vi.advanceTimersByTime(1000);
      expect(timer.elapsed).toBe(2);

      vi.advanceTimersByTime(3000);
      expect(timer.elapsed).toBe(5);
    });

    it('calls onTick callback with elapsed value', () => {
      const onTick = vi.fn();
      const timer = new Timer(onTick);
      timer.start();

      vi.advanceTimersByTime(1000);
      expect(onTick).toHaveBeenCalledWith(1);

      vi.advanceTimersByTime(1000);
      expect(onTick).toHaveBeenCalledWith(2);

      expect(onTick).toHaveBeenCalledTimes(2);
    });

    it('resets elapsed to 0 when restarted', () => {
      const timer = new Timer();
      timer.start();

      vi.advanceTimersByTime(5000);
      expect(timer.elapsed).toBe(5);

      timer.start();
      expect(timer.elapsed).toBe(0);

      vi.advanceTimersByTime(2000);
      expect(timer.elapsed).toBe(2);
    });

    it('clears previous interval when restarted', () => {
      const timer = new Timer();
      timer.start();
      const firstIntervalId = timer.intervalId;

      timer.start();
      expect(timer.intervalId).not.toBe(firstIntervalId);
    });
  });

  describe('stop', () => {
    it('stops the timer and resets elapsed to 0', () => {
      const timer = new Timer();
      timer.start();

      vi.advanceTimersByTime(3000);
      expect(timer.elapsed).toBe(3);

      timer.stop();
      expect(timer.elapsed).toBe(0);
      expect(timer.intervalId).toBeNull();
    });

    it('prevents further increments after stopping', () => {
      const timer = new Timer();
      timer.start();

      vi.advanceTimersByTime(2000);
      timer.stop();

      vi.advanceTimersByTime(5000);
      expect(timer.elapsed).toBe(0);
    });

    it('handles stop when timer is not running', () => {
      const timer = new Timer();
      expect(() => timer.stop()).not.toThrow();
      expect(timer.elapsed).toBe(0);
    });
  });
});
