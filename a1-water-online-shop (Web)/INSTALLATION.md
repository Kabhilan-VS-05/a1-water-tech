# Installation Guide

## Prerequisites
- Node.js 18+ (recommended: latest LTS)
- npm (comes with Node.js)

## Clone and Install
```bash
git clone <your-repo-url>
cd a1-water-online-shop
npm ci
```

Use `npm install` if you are not using the lockfile:
```bash
npm install
```

## Run in Development
```bash
npm run dev
```

## Build for Production
```bash
npm run build
```

## Preview Production Build
```bash
npm run preview
```

## Windows PowerShell Note
If PowerShell blocks `npm` scripts, use:
```bash
npm.cmd ci
npm.cmd run dev
```

## Important
- Do not commit `node_modules`.
- Commit `package.json` and `package-lock.json` so others can install exact dependencies.
