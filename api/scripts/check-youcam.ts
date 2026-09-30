// Zero-unit check of the YouCam setup: key, balance, prices, and the file
// upload path (register + PUT). It never creates a task, so it spends nothing.
// Run: npm run check:youcam

import sharp from 'sharp';
import { loadEnv } from '../config/env.js';
import { createYouCamClient } from '../youcam/live.js';

try {
  process.loadEnvFile(new URL('../../.env', import.meta.url));
} catch {
  // Use the process environment.
}

const env = loadEnv({ ...process.env, YOUCAM_MODE: 'live' });
const youcam = createYouCamClient({ apiKey: env.YOUCAM_API_KEY!, baseUrl: env.YOUCAM_API_BASE! });

const before = await youcam.getCredit();
console.log(`Balance: ${before.total} units`);

const costs = await youcam.getFeatureCosts();
for (const path of ['/s2s/v2.0/task/cloth-v4', '/s2s/v2.0/task/makeup-vto', '/s2s/v2.0/task/hair-color']) {
  const prices = costs.filter((c) => c.path === path).map((c) => c.amount);
  console.log(`Price ${path}: ${prices.join(' / ')} units`);
}

// A plain synthetic image (no person) exercises registration and upload.
const image = await sharp({ create: { width: 640, height: 800, channels: 3, background: '#B0304A' } })
  .jpeg({ quality: 80 })
  .toBuffer();
const file = await youcam.registerFile({ contentType: 'image/jpg', fileName: 'wearmony-check.jpg', size: image.length });
await youcam.uploadFile(file.upload, new Uint8Array(image));
console.log(`File upload: ok (file id ${file.fileId.slice(0, 8)}…)`);

const after = await youcam.getCredit();
console.log(`Balance after: ${after.total} units${after.total === before.total ? ' (unchanged)' : ''}`);
