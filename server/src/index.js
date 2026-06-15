import bcrypt from 'bcryptjs';
import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';
import morgan from 'morgan';
import { v4 as uuid } from 'uuid';

import { requireAdmin, requireAuth } from './auth.js';
import { db } from './db.js';

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

const now = () => new Date().toISOString();
const audit = (userId, action, entity, entityId, metadata = {}) => {
  db.prepare(`
    INSERT INTO audit_logs (id, user_id, action, entity, entity_id, metadata, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(uuid(), userId, action, entity, entityId, JSON.stringify(metadata), now());
};

function publicUser(user) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    age: user.age,
    mobile: user.mobile || '',
    role: user.role,
    status: user.status,
    deviceId: user.device_id || '',
    createdAt: user.created_at,
    updatedAt: user.updated_at
  };
}

app.get('/health', (_, res) => res.json({ ok: true, service: 'Deepu Manager' }));

app.get('/app/latest', (_, res) => {
  res.json({
    version: process.env.APP_VERSION || '1.0.7',
    apkUrl: process.env.APP_APK_URL || 'https://github.com/AustinKarasu/DeepuManager/releases/download/v1.0.7/Deepu-Manager-v1.0.7.apk',
    notes: process.env.APP_NOTES || 'Latest Deepu Manager release with faster startup, working biometrics, and a mobile-optimized stock sheet.'
  });
});

app.post('/auth/login', (req, res) => {
  const { email, password } = req.body;
  const user = db.prepare('SELECT * FROM users WHERE email = ? AND status = ?').get(email, 'active');
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Invalid login' });
  }
  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '12h' }
  );
  audit(user.id, 'login', 'users', user.id);
  return res.json({
    token,
    user: publicUser(user)
  });
});

app.get('/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.sub);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(publicUser(user));
});

app.put('/me', requireAuth, (req, res) => {
  const updated = now();
  db.prepare('UPDATE users SET name = ?, age = ?, mobile = ?, updated_at = ? WHERE id = ?')
    .run(req.body.name || '', req.body.age || null, req.body.mobile || '', updated, req.user.sub);
  audit(req.user.sub, 'update_profile', 'users', req.user.sub);
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.sub);
  res.json(publicUser(user));
});

app.post('/access-requests', (req, res) => {
  const id = uuid();
  db.prepare(`
    INSERT INTO access_requests (id, email, name, reason, status, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(id, req.body.email, req.body.name, req.body.reason || '', 'pending', now());
  return res.status(201).json({ id });
});

app.get('/admin/users', requireAuth, requireAdmin, (_, res) => {
  res.json(db.prepare('SELECT id, email, name, age, mobile, role, status, device_id, created_at, updated_at FROM users ORDER BY created_at DESC').all());
});

app.post('/admin/users', requireAuth, requireAdmin, (req, res) => {
  const id = uuid();
  const created = now();
  db.prepare(`
    INSERT INTO users (id, email, name, age, mobile, password_hash, role, status, device_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    req.body.email,
    req.body.name,
    req.body.age || null,
    req.body.mobile || '',
    bcrypt.hashSync(req.body.password || 'ChangeMe@123', 12),
    req.body.role || 'staff',
    req.body.status || 'active',
    req.body.deviceId || '',
    created,
    created
  );
  audit(req.user.sub, 'create_user', 'users', id, { role: req.body.role || 'staff' });
  res.status(201).json({ id });
});

app.get('/admin/access-requests', requireAuth, requireAdmin, (_, res) => {
  res.json(db.prepare('SELECT * FROM access_requests WHERE status = ? ORDER BY created_at DESC').all('pending'));
});

app.post('/admin/access-requests/:id/approve', requireAuth, requireAdmin, (req, res) => {
  const request = db.prepare('SELECT * FROM access_requests WHERE id = ?').get(req.params.id);
  if (!request) return res.status(404).json({ error: 'Request not found' });
  const userId = uuid();
  const created = now();
  db.prepare(`
    INSERT INTO users (id, email, name, age, mobile, password_hash, role, status, device_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(userId, request.email, request.name, null, '', bcrypt.hashSync('ChangeMe@123', 12), 'staff', 'active', req.body.deviceId || '', created, created);
  db.prepare('UPDATE access_requests SET status = ?, reviewed_at = ?, reviewed_by = ? WHERE id = ?')
    .run('approved', created, req.user.sub, req.params.id);
  audit(req.user.sub, 'approve_access', 'access_requests', req.params.id);
  res.json({ id: userId });
});

app.post('/admin/access-requests/:id/deny', requireAuth, requireAdmin, (req, res) => {
  db.prepare('UPDATE access_requests SET status = ?, reviewed_at = ?, reviewed_by = ? WHERE id = ?')
    .run('denied', now(), req.user.sub, req.params.id);
  audit(req.user.sub, 'deny_access', 'access_requests', req.params.id);
  res.json({ ok: true });
});

app.delete('/admin/users/:id', requireAuth, requireAdmin, (req, res) => {
  db.prepare('DELETE FROM users WHERE id = ? AND role != ?').run(req.params.id, 'admin');
  audit(req.user.sub, 'delete_user', 'users', req.params.id);
  res.json({ ok: true });
});

function stockPayload(row) {
  return {
    ...JSON.parse(row.payload),
    id: row.id,
    userId: row.user_id,
    updatedAt: row.updated_at
  };
}

app.get('/stock-registers', requireAuth, (req, res) => {
  const limit = Math.min(Number(req.query.limit || 50), 500);
  const offset = Number(req.query.offset || 0);
  const search = String(req.query.search || '').trim().toLowerCase();
  const from = req.query.from ? new Date(String(req.query.from)) : null;
  const to = req.query.to ? new Date(String(req.query.to)) : null;
  const lowOnly = req.query.lowStockOnly === 'true';
  let rows = db.prepare('SELECT * FROM stock_registers WHERE user_id = ? ORDER BY updated_at DESC').all(req.user.sub);
  let payloads = rows.map(stockPayload);
  if (search) {
    payloads = payloads.filter((item) =>
      [item.itemName, item.particulars, item.remarks].some((value) =>
        String(value || '').toLowerCase().includes(search)
      )
    );
  }
  if (from) payloads = payloads.filter((item) => new Date(item.entryDate) >= from);
  if (to) payloads = payloads.filter((item) => new Date(item.entryDate) <= to);
  if (lowOnly) payloads = payloads.filter((item) => Number(item.closingQty) <= Number(item.lowStockThreshold));
  res.json(payloads.slice(offset, offset + limit));
});

app.get('/stock-registers/:id', requireAuth, (req, res) => {
  const row = db.prepare('SELECT * FROM stock_registers WHERE id = ? AND user_id = ?').get(req.params.id, req.user.sub);
  if (!row) return res.status(404).json({ error: 'Stock register not found' });
  res.json(stockPayload(row));
});

app.post('/stock-registers', requireAuth, (req, res) => {
  const id = req.body.id || uuid();
  db.prepare(`
    INSERT INTO stock_registers (id, user_id, payload, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at
  `).run(id, req.user.sub, JSON.stringify(req.body), now());
  audit(req.user.sub, 'create_stock_register', 'stock_registers', id);
  res.status(201).json({ id });
});

app.put('/stock-registers/:id', requireAuth, (req, res) => {
  const existing = db.prepare('SELECT id FROM stock_registers WHERE id = ? AND user_id = ?').get(req.params.id, req.user.sub);
  if (!existing) return res.status(404).json({ error: 'Stock register not found' });
  db.prepare('UPDATE stock_registers SET payload = ?, updated_at = ? WHERE id = ? AND user_id = ?')
    .run(JSON.stringify({ ...req.body, id: req.params.id }), now(), req.params.id, req.user.sub);
  audit(req.user.sub, 'update_stock_register', 'stock_registers', req.params.id);
  res.json({ id: req.params.id });
});

app.post('/stock-registers/:id/duplicate', requireAuth, (req, res) => {
  const row = db.prepare('SELECT * FROM stock_registers WHERE id = ? AND user_id = ?').get(req.params.id, req.user.sub);
  if (!row) return res.status(404).json({ error: 'Stock register not found' });
  const source = stockPayload(row);
  const id = uuid();
  const copy = {
    ...source,
    id,
    itemName: `${source.itemName} Copy`,
    entryDate: now(),
    monthLabel: new Intl.DateTimeFormat('en', { month: 'short', year: 'numeric' }).format(new Date())
  };
  db.prepare('INSERT INTO stock_registers (id, user_id, payload, updated_at) VALUES (?, ?, ?, ?)')
    .run(id, req.user.sub, JSON.stringify(copy), now());
  audit(req.user.sub, 'duplicate_stock_register', 'stock_registers', id, { sourceId: req.params.id });
  res.status(201).json({ id });
});

app.delete('/stock-registers/:id', requireAuth, (req, res) => {
  db.prepare('DELETE FROM stock_registers WHERE id = ? AND user_id = ?').run(req.params.id, req.user.sub);
  audit(req.user.sub, 'delete_stock_register', 'stock_registers', req.params.id);
  res.json({ ok: true });
});

app.get('/backup', requireAuth, (req, res) => {
  res.json({
    generatedAt: now(),
    stockRegisters: db.prepare('SELECT * FROM stock_registers WHERE user_id = ?').all(req.user.sub).map(stockPayload)
  });
});

app.post('/restore', requireAuth, (req, res) => {
  if (!Array.isArray(req.body.stockRegisters)) {
    return res.status(400).json({ error: 'Invalid backup file' });
  }
  const tx = db.transaction(() => {
    for (const item of req.body.stockRegisters) {
      if (!item.id) continue;
      db.prepare(`
        INSERT INTO stock_registers (id, user_id, payload, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at
      `).run(item.id, req.user.sub, JSON.stringify({ ...item, userId: req.user.sub }), item.updatedAt || now());
    }
  });
  tx();
  audit(req.user.sub, 'restore_backup', 'stock_registers', null, { count: req.body.stockRegisters.length });
  res.json({ ok: true, restored: req.body.stockRegisters.length });
});

app.get('/admin/audit-logs', requireAuth, requireAdmin, (_, res) => {
  res.json(db.prepare(`
    SELECT audit_logs.*, users.email AS user_email
    FROM audit_logs
    LEFT JOIN users ON users.id = audit_logs.user_id
    ORDER BY audit_logs.created_at DESC
    LIMIT 500
  `).all());
});

app.get('/admin/backup', requireAuth, requireAdmin, (_, res) => {
  res.json({
    generatedAt: now(),
    users: db.prepare('SELECT id, email, name, age, mobile, role, status, device_id, created_at, updated_at FROM users').all(),
    accessRequests: db.prepare('SELECT * FROM access_requests').all(),
    stockRegisters: db.prepare('SELECT * FROM stock_registers').all().map(stockPayload),
    auditLogs: db.prepare('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 1000').all()
  });
});

app.post('/admin/restore', requireAuth, requireAdmin, (req, res) => {
  if (!Array.isArray(req.body.stockRegisters)) {
    return res.status(400).json({ error: 'Invalid backup file' });
  }
  const tx = db.transaction(() => {
    for (const item of req.body.stockRegisters) {
      if (!item.id || !item.userId) continue;
      db.prepare(`
        INSERT INTO stock_registers (id, user_id, payload, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at
      `).run(item.id, item.userId, JSON.stringify(item), item.updatedAt || now());
    }
  });
  tx();
  audit(req.user.sub, 'restore_backup', 'stock_registers', null, { count: req.body.stockRegisters.length });
  res.json({ ok: true, restored: req.body.stockRegisters.length });
});

const port = Number(process.env.PORT || 8443);
app.listen(port, '0.0.0.0', () => console.log(`Deepu Manager API listening on ${port}`));
