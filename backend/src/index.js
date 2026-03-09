require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const { Pool } = require('pg');
const redis = require('redis');

// Initialize Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connections
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://localhost:5432/whitealert'
});

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.connect().catch(console.error);

// Basic routes
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Companies routes
app.post('/api/companies', async (req, res) => {
  try {
    const { name } = req.body;
    const result = await pool.query(
      'INSERT INTO companies (name, created_at) VALUES ($1, $2) RETURNING id',
      [name, new Date()]
    );
    res.json({ id: result.rows[0].id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// User management routes (basic)
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, companyId } = req.body;
    // Basic user creation - in real app, hash password, validate, etc.
    const result = await pool.query(
      'INSERT INTO users (email, password, company_id, created_at) VALUES ($1, $2, $3, $4) RETURNING id',
      [email, password, companyId, new Date()]
    );
    res.json({ userId: result.rows[0].id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    // Basic auth - in real app, verify password hash
    const user = result.rows[0];
    const token = 'mock-jwt-token-' + user.id; // Replace with real JWT
    res.json({ token, user: { id: user.id, email: user.email, companyId: user.company_id } });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Socket.io for chat
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join-room', (roomId) => {
    socket.join(roomId);
    console.log(`User ${socket.id} joined room ${roomId}`);
  });

  socket.on('send-message', async (data) => {
    const { roomId, message, userId, companyId } = data;
    // Store message in database
    try {
      await pool.query(
        'INSERT INTO messages (room_id, user_id, company_id, content, created_at) VALUES ($1, $2, $3, $4, $5)',
        [roomId, userId, companyId, message, new Date()]
      );
      io.to(roomId).emit('receive-message', { ...data, timestamp: new Date() });
    } catch (error) {
      console.error('Error saving message:', error);
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});