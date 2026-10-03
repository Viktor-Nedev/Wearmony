import { describe, expect, it } from 'vitest';
import { nextDay } from './seed.js';

describe('nextDay', () => {
  it('is this year until the day and next year after it', () => {
    expect(nextDay(Date.UTC(2026, 9, 3), 5, 23)).toBe('2027-05-23');
    expect(nextDay(Date.UTC(2027, 0, 10), 5, 23)).toBe('2027-05-23');
    expect(nextDay(Date.UTC(2027, 4, 23), 5, 23)).toBe('2027-05-23');
    expect(nextDay(Date.UTC(2027, 4, 24), 5, 23)).toBe('2028-05-23');
    expect(nextDay(Date.UTC(2026, 9, 3), 3, 27)).toBe('2027-03-27');
  });
});
