const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const app = express();
const port = 3000;

// Database connection
const pool = new Pool({
  user: 'gameuser',
  host: 'postgres-service',
  database: 'asteroids',
  password: 'gamepass123',
  port: 5432,
});

// Middleware
app.use(express.json());
app.use(express.static('.'));

// Initialize database
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS high_scores (
        id SERIAL PRIMARY KEY,
        initials VARCHAR(3) NOT NULL,
        score INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Create index for faster queries
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_high_scores_score 
      ON high_scores (score DESC)
    `);
    
    console.log('Database initialized successfully');
  } catch (err) {
    console.error('Database initialization error:', err);
  }
}

// API Routes
app.get('/api/highscores', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT initials, score FROM high_scores ORDER BY score DESC LIMIT 20'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching high scores:', err);
    res.status(500).json({ error: 'Failed to fetch high scores' });
  }
});

app.post('/api/highscores', async (req, res) => {
  const { initials, score } = req.body;
  
  // Validate input
  if (!initials || typeof initials !== 'string' || initials.length !== 3) {
    return res.status(400).json({ error: 'Initials must be exactly 3 characters' });
  }
  
  if (!score || typeof score !== 'number' || score < 0) {
    return res.status(400).json({ error: 'Score must be a positive number' });
  }
  
  // Convert to uppercase
  const upperInitials = initials.toUpperCase();
  
  try {
    // Insert new score
    await pool.query(
      'INSERT INTO high_scores (initials, score) VALUES ($1, $2)',
      [upperInitials, score]
    );
    
    // Keep only top 20 scores
    await pool.query(`
      DELETE FROM high_scores 
      WHERE id NOT IN (
        SELECT id FROM high_scores 
        ORDER BY score DESC 
        LIMIT 20
      )
    `);
    
    res.json({ success: true });
  } catch (err) {
    console.error('Error saving high score:', err);
    res.status(500).json({ error: 'Failed to save high score' });
  }
});

// Serve the game
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'asteroids.html'));
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Start server
app.listen(port, async () => {
  console.log(`API server running on port ${port}`);
  await initDB();
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    process.exit(0);
  });
});
