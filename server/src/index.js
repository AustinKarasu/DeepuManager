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

app.get('/health', (_, res) => res.json({ ok: true, service: 'DeepuLogger' }));

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
  return res.json({ token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
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
  res.json(db.prepare('SELECT id, email, name, role, status, device_id, created_at FROM users ORDER BY created_at DESC').all());
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
    INSERT INTO users (id, email, name, password_hash, role, status, device_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(userId, request.email, request.name, bcrypt.hashSync('ChangeMe@123', 12), 'staff', 'active', req.body.deviceId || '', created, created);
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

app.post('/sync/stock-registers', requireAuth, (req, res) => {
  const id = req.body.id || uuid();
  db.prepare(`
    INSERT INTO stock_registers (id, user_id, payload, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at
  `).run(id, req.user.sub, JSON.stringify(req.body), now());
  audit(req.user.sub, 'sync_stock_register', 'stock_registers', id);
  res.status(201).json({ id });
});

app.get('/admin/audit-logs', requireAuth, requireAdmin, (_, res) => {
  res.json(db.prepare('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 500').all());
});

const port = Number(process.env.PORT || 8443);
app.listen(port, '0.0.0.0', () => console.log(`DeepuLogger API listening on ${port}`));
