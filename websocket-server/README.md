# Amerike MBA 2026 - WebSocket Server

WebSocket server for the Amerike MBA 2026 investment simulation application. This server handles real-time communication, authentication, investment transactions, and session management.

## Features

- Real-time WebSocket communication
- User authentication
- Investment transactions with atomic database operations
- Session management with countdown timer
- Broadcasting to all connected clients
- Heartbeat mechanism for connection health
- Automatic reconnection handling
- SQLite database integration

## Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn
- SQLite database (shared with Flutter app)

## Installation

1. Navigate to the websocket-server directory:
```bash
cd /Users/raxgomez/Documents/MBA/Tania/websocket-server
```

2. Install dependencies:
```bash
npm install
```

3. Copy the example environment file and configure it:
```bash
cp .env.example .env
```

4. Ensure the database exists at the specified path (default: `../data/amerike_investment.db`)

## Configuration

Edit the `.env` file to configure the server:

```env
WS_PORT=8080                    # WebSocket server port
WS_HOST=0.0.0.0                 # WebSocket server host
DB_PATH=../data/amerike_investment.db  # Database path
HEARTBEAT_INTERVAL=30000        # Heartbeat interval in milliseconds
HEARTBEAT_TIMEOUT=10000         # Heartbeat timeout in milliseconds
INITIAL_BALANCE=1000000         # Initial user balance
ROUND_DURATION=1800             # Round duration in seconds (30 minutes)
MIN_INVESTMENT=10000            # Minimum investment amount
MAX_INVESTMENT=500000           # Maximum investment amount
LOG_LEVEL=info                  # Logging level
```

## Running the Server

### Development Mode (with TypeScript compilation on-the-fly):
```bash
npm run dev
```

### Production Mode:
```bash
npm run build
npm start
```

### Watch Mode (for development with auto-recompile):
```bash
npm run watch
```

In a separate terminal, you can then run:
```bash
npm start
```

## API Protocol

The server communicates using JSON messages with the following structure:

### Message Types

#### 1. Authentication (`auth`)
**Client → Server:**
```json
{
  "type": "auth",
  "username": "student1",
  "password": "123456"
}
```

**Server → Client:**
```json
{
  "type": "auth",
  "status": "success",
  "user": { ... },
  "sessionId": "session-id"
}
```

#### 2. Investment (`invest`)
**Client → Server:**
```json
{
  "type": "invest",
  "projectId": "project-id",
  "amount": 50000,
  "observations": "Optional notes"
}
```

**Server → Client (Broadcast to all):**
```json
{
  "type": "invest",
  "status": "success",
  "investment": { ... },
  "user": { ... },
  "project": { ... }
}
```

#### 3. Session Update (`session_update`)
**Client → Server (Admin only):**
```json
{
  "type": "session_update",
  "action": "start|pause|resume|end|update_time",
  "tiempoRestante": 1800,
  "estado": "active|paused|ended"
}
```

**Server → Client (Broadcast to all):**
```json
{
  "type": "session_update",
  "session": { ... }
}
```

#### 4. Sync Request (`sync_request`)
**Client → Server:**
```json
{
  "type": "sync_request",
  "userId": "user-id"
}
```

**Server → Client:**
```json
{
  "type": "sync_request",
  "status": "success",
  "data": {
    "users": [ ... ],
    "projects": [ ... ],
    "investments": [ ... ],
    "session": { ... },
    "themes": [ ... ],
    "ranking": [ ... ]
  }
}
```

#### 5. Heartbeat (`heartbeat`)
**Client → Server:**
```json
{
  "type": "heartbeat",
  "timestamp": "2026-05-26T12:00:00.000Z"
}
```

**Server → Client:**
```json
{
  "type": "pong",
  "timestamp": "2026-05-26T12:00:00.500Z"
}
```

#### 6. Error Response
**Server → Client:**
```json
{
  "type": "error",
  "code": "ERROR_CODE",
  "message": "Error description",
  "timestamp": "2026-05-26T12:00:00.000Z"
}
```

## Error Codes

- `INVALID_CREDENTIALS` - Invalid username or password
- `USER_EXISTS` - User already exists
- `INSUFFICIENT_FUNDS` - Insufficient balance for investment
- `INVALID_AMOUNT` - Investment amount out of valid range
- `PROJECT_NOT_FOUND` - Project does not exist
- `USER_NOT_FOUND` - User does not exist
- `SERVER_ERROR` - Internal server error
- `UNAUTHORIZED` - Unauthorized access
- `CONNECTION_LOST` - WebSocket connection lost

## Architecture

```
websocket-server/
├── src/
│   ├── config/          # Configuration files
│   ├── database/        # Database connection and repositories
│   ├── models/          # Data models
│   ├── services/        # Business logic services
│   ├── handlers/        # WebSocket message handlers
│   ├── websocket/       # WebSocket server implementation
│   ├── utils/           # Utility functions
│   └── index.ts         # Entry point
├── data/                # Database directory (linked to Flutter)
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

## Development

### Build TypeScript:
```bash
npm run build
```

### Run Linter:
```bash
npm run lint
```

### Run Tests:
```bash
npm test
```

## Database Schema

The server connects to the SQLite database used by the Flutter app with the following tables:
- `users` - User accounts
- `projects` - Investment projects
- `investments` - Investment transactions
- `sessions` - Session management
- `themes` - Investment themes

## Security Notes

- Passwords should be hashed in production
- Implement rate limiting for investment operations
- Use TLS/WSS for production deployments
- Validate all incoming messages
- Implement proper error handling to prevent information leakage

## Troubleshooting

### Database Connection Issues
- Ensure the database file exists at the specified path
- Check file permissions on the database file
- Verify the database is not locked by another process

### WebSocket Connection Issues
- Check that the port is not in use: `lsof -i :8080`
- Verify firewall settings allow WebSocket connections
- Check the Flutter app is using the correct WebSocket URL

### Performance Issues
- Monitor the number of connected clients
- Check database query performance
- Implement connection pooling if needed

## License

MIT