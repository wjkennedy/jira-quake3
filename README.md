# Lotus 1-2-3 Forge App for Confluence

A Lotus 1-2-3 spreadsheet application packaged as a Forge app for Atlassian Confluence. This brings the classic spreadsheet experience to Confluence pages with save functionality.

## Features

- 📊 Classic Lotus 1-2-3 spreadsheet interface
- 💾 Save spreadsheets to Confluence storage
- 📝 Formula support with cell references
- 🎨 Multiple cell formats (Number, Currency, Percent, Date)
- ⌨️ Keyboard navigation and shortcuts
- 📋 Copy/paste functionality
- 🔢 100 rows x 26 columns (expandable)
- 🖱️ Click and double-click cell editing

## Quick Start

### Prerequisites

1. Install the Forge CLI:
```bash
npm install -g @forge/cli
```

2. Install dependencies:
```bash
npm install
```

### Local Development

**NEW!** Test your app locally without deploying:

```bash
npm run dev
```

Then open http://localhost:3000 in your browser to test:
- Lotus 1-2-3 at http://localhost:3000/lotus123
- Doom at http://localhost:3000/doom

The local dev server mocks Forge APIs including storage, so you can test save/load functionality instantly.

### Deploy to Atlassian

// ... existing code ...

## Development

### Local Testing

```bash
# Start local development server (no deployment needed!)
npm run dev

# Access apps at:
# - http://localhost:3000/lotus123
# - http://localhost:3000/doom
```

**Benefits:**
- Instant feedback - no deployment wait times
- Mock Forge storage in-memory
- Test multiple macro instances with different IDs
- Console logs visible in terminal
- Hot reload (restart server to pick up changes)

### Testing with Different Macro IDs

```bash
# Test isolated spreadsheets
http://localhost:3000/lotus123?macroId=test-1
http://localhost:3000/lotus123?macroId=test-2
```

### Forge Tunnel (Alternative)

For testing with real Atlassian authentication:

```bash
# Start local development tunnel
forge tunnel

# Access via the provided Atlassian URL
```

// ... existing code ...

## Troubleshooting

**Macro won't load:**
- Ensure app is deployed: `forge deploy`
- Check permissions in manifest.yml
- Verify installation: `forge install --upgrade`

**Local dev server issues:**
- Port 3000 in use? Set custom port: `PORT=3001 npm run dev`
- Storage not persisting? It's in-memory - restart clears data
- Can't find static files? Check `static/` directory exists

**Data not saving:**
- Check browser console for errors
- Verify Forge storage permissions
- Ensure unique macro ID is generated

**Formulas showing #ERROR:**
- Check formula syntax (must start with =)
- Verify cell references exist
- Complex formulas may need debugging

// ... existing code ...
```

```javascript file="" isHidden
