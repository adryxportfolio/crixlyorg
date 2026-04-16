# Plugin Authoring Smoke Example

A Crixly plugin

## Development

```bash
pnpm install
pnpm dev            # watch builds
pnpm dev:ui         # local dev server with hot-reload events
pnpm test
```

## Install Into Crixly

```bash
pnpm crixlyai plugin install ./
```

## Build Options

- `pnpm build` uses esbuild presets from `@crixlyai/plugin-sdk/bundlers`.
- `pnpm build:rollup` uses rollup presets from the same SDK.
