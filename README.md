# Termux Web Assistant

A modern web-based dashboard for managing Termux on Android devices remotely.

## Features

- **Package Management** - Search, install, update, and remove Termux packages
- **File Manager** - Navigate and manage files with tree view, breadcrumbs, and CRUD operations
- **Script Editor** - Create, edit, and schedule scripts (Bash/Python/Node.js)
- **System Dashboard** - Monitor your device with real-time metrics
- **AI Integration** - Built-in AI assistant for command help and automation

## Tech Stack

- **Frontend**: React 19, TypeScript, Tailwind CSS, Radix UI
- **Backend**: Express, tRPC, Drizzle ORM
- **Database**: MySQL
- **AI**: AI SDK with OpenAI integration

## Getting Started

### Prerequisites

- Node.js 22+
- pnpm 10+
- MySQL database

### Installation

```bash
# Install dependencies
pnpm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database and API credentials

# Push database schema
pnpm db:push

# Start development server
pnpm dev
```

### Build & Run Production

```bash
# Build the application
pnpm build

# Start production server
pnpm start
```

## Project Structure

```
├── client/           # React frontend
│   ├── src/
│   │   ├── components/   # UI components
│   │   ├── pages/        # Page components
│   │   ├── hooks/        # Custom React hooks
│   │   └── lib/          # Utilities
├── server/           # Express backend
│   └── _core/       # Core server logic, tRPC routers
├── drizzle/         # Database schema and migrations
├── shared/          # Shared types and utilities
└── patches/         # Dependency patches
```

## API Reference

The backend uses tRPC for type-safe API endpoints. Key routers:

- `package` - Package management operations
- `file` - File system operations
- `script` - Script CRUD and execution
- `system` - System information

## License

MIT
