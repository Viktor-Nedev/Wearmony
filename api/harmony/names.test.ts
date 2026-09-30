import { describe, expect, it } from 'vitest';
import { hexToLab } from './color.js';
import { nameColor } from './names.js';

describe('nameColor', () => {
  it.each([
    ['#000000', 'black'],
    ['#FFFFFF', 'white'],
    ['#808080', 'gray'],
    ['#FF0000', 'red'],
    ['#800020', 'burgundy'],
    ['#FFC0CB', 'pink'],
    ['#FFA500', 'orange'],
    ['#FFD700', 'yellow'],
    ['#228B22', 'green'],
    ['#008080', 'teal'],
    ['#4169E1', 'blue'],
    ['#000080', 'navy'],
    ['#800080', 'purple'],
    ['#E6E6FA', 'lavender'],
    ['#8B4513', 'brown'],
    ['#F5F5DC', 'beige'],
  ])('%s is %s', (hex, base) => {
    expect(nameColor(hexToLab(hex)).base).toBe(base);
  });

  it('adds a modifier to the label', () => {
    expect(nameColor(hexToLab('#404040')).label).toBe('dark gray');
    expect(nameColor(hexToLab('#006400')).label).toBe('dark green');
  });
});
