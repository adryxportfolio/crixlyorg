export const type = "openclaw_gateway";
export const label = "OpenClaw Gateway";

export const models: { id: string; label: string }[] = [];

export const agentConfigurationDoc = `# openclaw_gateway agent configuration

Adapter: openclaw_gateway

Use when:
- You want Crixly to invoke OpenClaw over the Gateway WebSocket protocol.
- You want native gateway auth/connect semantics instead of HTTP /v1/responses or /hooks/*.

Don't use when:
- You only expose OpenClaw HTTP endpoints.
- Your deployment does not permit outbound WebSocket access from the Crixly server.

Core fields:
- url (string, required): OpenClaw gateway WebSocket URL (ws:// or wss://)
- headers (object, optional): handshake headers; supports x-openclaw-token / x-openclaw-auth
- authToken (string, optional): shared gateway token override
- password (string, optional): gateway shared password, if configured

Gateway connect identity fields:
- clientId (string, optional): gateway client id (default gateway-client)
- clientMode (string, optional): gateway client mode (default backend)
- clientVersion (string, optional): client version string
- role (string, optional): gateway role (default operator)
- scopes (string[] | comma string, optional): gateway scopes (default ["operator.admin"])
- disableDeviceAuth (boolean, optional): disable signed device payload in connect params (default false)

Request behavior fields:
- payloadTemplate (object, optional): additional fields merged into gateway agent params
- workspaceRuntime (object, optional): desired runtime service intents; Crixly forwards these in a standardized crixly.workspaceRuntime block for remote execution environments
- timeoutSec (number, optional): adapter timeout in seconds (default 120)
- waitTimeoutMs (number, optional): agent.wait timeout override (default timeoutSec * 1000)
- autoPairOnFirstConnect (boolean, optional): on first "pairing required", attempt device.pair.list/device.pair.approve via shared auth, then retry once (default true)
- crixlyApiUrl (string, optional): absolute Crixly base URL advertised in wake text

Session routing fields:
- sessionKeyStrategy (string, optional): issue (default), fixed, or run
- sessionKey (string, optional): fixed session key when strategy=fixed (default crixly)

Standard outbound payload additions:
- crixly (object): standardized Crixly context added to every gateway agent request
- crixly.workspace (object, optional): resolved execution workspace for this run
- crixly.workspaces (array, optional): additional workspace hints Crixly exposed to the run
- crixly.workspaceRuntime (object, optional): normalized runtime service intent config for the workspace

Standard result metadata supported:
- meta.runtimeServices (array, optional): normalized adapter-managed runtime service reports
- meta.previewUrl (string, optional): shorthand single preview URL
- meta.previewUrls (string[], optional): shorthand multiple preview URLs
`;
