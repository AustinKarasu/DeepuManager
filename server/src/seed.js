import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import { v4 as uuid } from 'uuid';

import { db } from './db.js';

dotenv.config();

const email = process.env.ADMIN_EMAIL;
const password = process.env.ADMIN_PASSWORD;

if (!email || !password) {
  throw new Error('ADMIN_EMAIL and ADMIN_PASSWORD are required to seed the admin account');
}
const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);

if (!existing) {
  const now = new Date().toISOString();
  db.prepare(`
    INSERT INTO users (id, email, name, password_hash, role, status, device_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    uuid(),
    email,
    'DeepuLogger Admin',
    bcrypt.hashSync(password, 12),
    'admin',
    'active',
    'vps-admin',
    now,
    now
  );
  console.log('Default admin seeded');
} else {
  console.log('Default admin already exists');
}
