import sharp from 'sharp';
import { loadEnv } from '../config/env.js';
import { createServices, type ServiceOverrides } from '../services.js';
import { createApp } from './app.js';

export const ORGANIZER = '11111111-1111-4111-8111-111111111111';
export const ANA = '22222222-2222-4222-8222-222222222222';
export const BORIS = '33333333-3333-4333-8333-333333333333';
export const OUTSIDER = '44444444-4444-4444-8444-444444444444';

export function setup(env: Record<string, string> = {}, overrides: ServiceOverrides = {}) {
  let time = Date.parse('2026-10-01T10:00:00Z');
  const services = createServices(loadEnv({ MOCK_TRYON_SECONDS: '4', ...env }), { now: () => time, ...overrides });
  const app = createApp(services);

  async function call(method: string, path: string, user?: string | null, body?: unknown, headers: Record<string, string> = {}) {
    const init: RequestInit = { method, headers: { ...headers } };
    if (user) (init.headers as Record<string, string>).Authorization = `Bearer dev.${user}`;
    if (body instanceof Uint8Array) {
      init.body = new Uint8Array(body);
    } else if (body !== undefined) {
      (init.headers as Record<string, string>)['Content-Type'] = 'application/json';
      init.body = JSON.stringify(body);
    }
    const response = await app.request(`/api${path}`, init);
    const text = await response.text();
    let json: any = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = text;
    }
    return { status: response.status, json, headers: response.headers };
  }

  return { app, services, call, advance: (ms: number) => (time += ms) };
}

/** A simple portrait: plain background, a head, and a torso in the given clothing color. */
export async function portrait(clothing = '#6C8EBF', width = 768, height = 1024): Promise<Buffer> {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="100%" height="100%" fill="#DADDE2"/>
    <circle cx="${width / 2}" cy="${height * 0.2}" r="${width * 0.12}" fill="#D7A98C"/>
    <rect x="${width * 0.25}" y="${height * 0.32}" width="${width * 0.5}" height="${height * 0.6}" fill="${clothing}"/>
  </svg>`;
  return sharp(Buffer.from(svg)).jpeg({ quality: 92 }).toBuffer();
}

/** A product shot: one garment shape on white. */
export async function garmentImage(color: string): Promise<Buffer> {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="500">
    <rect width="400" height="500" fill="#FFFFFF"/>
    <path d="M150 70 L250 70 L262 160 L330 470 L70 470 L138 160 Z" fill="${color}"/>
  </svg>`;
  return sharp(Buffer.from(svg)).jpeg({ quality: 95 }).toBuffer();
}
