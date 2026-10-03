import { describe, expect, it } from 'vitest';
import { nextPromDay } from './seed.js';

describe('nextPromDay', () => {
  it('is this year before late May and next year after it', () => {
    expect(nextPromDay(Date.UTC(2026, 9, 3))).toBe('2027-05-23');
    expect(nextPromDay(Date.UTC(2027, 0, 10))).toBe('2027-05-23');
    expect(nextPromDay(Date.UTC(2027, 4, 23))).toBe('2027-05-23');
    expect(nextPromDay(Date.UTC(2027, 4, 24))).toBe('2028-05-23');
  });
});
