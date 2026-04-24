# 🌐 Abyss & Acres — Online Multiplayer Plan

This document plans the transition from the current single-player + bots build
to a real-time multiplayer Snake.io clone running from a hosted server.

## Current Status — Slice 1 shipped ✅

The lobby plumbing is live in the APK:

- `NetManager` autoload owns the `MultiplayerPeer` (ENet, port 8910), the
  nickname registry, and host/join/leave RPCs.
- `LanDiscovery` broadcasts a JSON beacon every 1 s on UDP port 8911 when
  hosting, and listens for beacons when browsing. Hosts expire from the list
  after 4 s of silence.
- `Lobby.tscn` exposes nickname entry (persisted to `SaveManager.data.nickname`),
  a "Host game" button, an auto-refreshing list of discovered LAN games, a
  manual IP input as fallback, and a back button.
- Android export now requests INTERNET, ACCESS_NETWORK_STATE,
  ACCESS_WIFI_STATE and CHANGE_WIFI_MULTICAST_STATE.

**Slice 1 limitation by design**: clicking Host or Join still drops both peers
into the existing single-player `Game.tscn`. The connection is open but the
gameplay is not yet networked. **Slice 2** below replaces this with the real
authoritative loop.

## 1. Goals & Constraints

- Up to **20 players per arena** + AI fillers when below threshold.
- **Mobile-first** (Android, low bandwidth, intermittent latency 80–250 ms).
- Server-authoritative to prevent cheating (speed hacks, teleport, ghost bodies).
- Reuse the existing **single-player loop** (snake controller, body manager,
  world wrap, power-ups, modes) with minimal rewrites.
- Same APK acts as **client only**; server runs headless on a VPS.

## 2. Architecture Choice

### Recommended: Godot Headless + ENet (UDP)
| Aspect | Why |
|---|---|
| Same engine | Reuse `SnakeController`, `BodyManager`, `WorldWrap` verbatim. |
| ENetMultiplayerPeer | Built into Godot 4. UDP, ordered + reliable channels. |
| Headless export | Run `Godot --headless --server`, no GPU needed. |
| Cost | One small VPS ($5/mo) handles 50–100 concurrent users. |

### Alternatives considered
- **WebSocketMultiplayerPeer** — easier through firewalls but TCP head-of-line
  blocking hurts at >100 ms RTT. Use only if browser export is also planned.
- **Custom Node.js + protobuf** — more flexible but doubles the codebase.
- **Nakama / Colyseus** — overkill for v1, useful later for matchmaking & accounts.

## 3. Repo Restructure

```
Abyss-Acres/
├── Scripts/
│   ├── Net/
│   │   ├── net_manager.gd        # autoload — connect / host / disconnect
│   │   ├── server_world.gd       # authoritative simulation
│   │   ├── client_world.gd       # interpolated rendering of server state
│   │   ├── snapshot.gd           # serialize/deserialize world state
│   │   └── input_packet.gd       # client → server input frames
│   └── ...
├── Server/
│   └── server_main.tscn          # headless entry point
└── project.godot                 # add `--server` feature flag
```

Existing scripts stay; `game.gd` becomes a thin wrapper that switches between
`offline_world.gd` (current logic) and `client_world.gd`.

## 4. Networking Model

### Authority
- **Server** simulates physics, collisions, food spawn, power-ups, scores.
- **Client** sends only its desired heading + boost flag (~30 Hz).
- **Server** broadcasts compressed world snapshots (~15 Hz) plus events
  (kills, power-up pickups) reliably.

### Snapshot format (per tick, ~15 Hz)
```
- tick: u32
- snakes[]:
    - id: u8
    - head_pos: i16 x i16   (1 px precision in 4000² world)
    - heading: u8           (256 directions ≈ 1.4° each)
    - segment_count: u16
    - flags: u8             (boost, shield, magnet, x2)
- food_changes[]:
    - id: u16, pos: i16x2, kind: u8, removed: bool
- powerups[]:
    - id: u8, pos: i16x2, kind: u8
```
Estimated payload: ~1.5 KB per snapshot, ~22 KB/s downlink per client.

### Body sync
Don't transmit every segment. Server sends head position + segment count;
client reconstructs the trail locally using the same `BodyManager` ring buffer
fed by interpolated head positions. Visual drift is acceptable; collisions are
server-authoritative anyway.

### Lag compensation
- **Client-side prediction** for own snake: apply input immediately, reconcile
  on snapshot if server head differs by > 8 px.
- **Entity interpolation** for other snakes: render 100 ms behind latest
  snapshot to hide jitter.

## 5. Lobby / Matchmaking (v1 minimal)

- Single global server with one always-running arena.
- Player connects → server assigns slot → spawns snake at safe location.
- When player count > 20, spin up a second arena (or just kick).
- v2: add quick-match, regions, friends list (Nakama).

## 6. Anti-cheat Baseline

- Server rejects input frames > 60 Hz (rate-limit).
- Server clamps heading deltas to `turn_rate * dt`.
- Server validates power-up pickup distance.
- Disconnect on >3 protocol violations / minute.

## 7. Phased Roadmap

### Phase 1 — Foundation ✅ (shipped)
- ✅ `Scripts/Net/` skeleton (`net_manager.gd`, `lan_discovery.gd`, `lobby.gd`).
- ✅ `NetManager` autoload (host / join / disconnect, nickname registry).
- ✅ Two clients can find each other on LAN and open an ENet session.

### Phase 2 — Authoritative loop ⏳ (next)
- Move spawn / collision / food logic into `server_world.gd`.
- Snapshot send + apply on client. No prediction yet — just see other snakes.

### Phase 3 — Smoothness ⏳
- Client-side prediction + reconciliation for own snake.
- Entity interpolation for remote snakes.
- Tune snapshot rate to balance bandwidth vs feel.

### Phase 4 — Features parity (1 week)
- Power-ups, score, kill credit, respawn flow.
- Game modes: Classic + Timed + Last Standing (Shrinking arena last).
- Bots filling empty slots run on the **server**, not the client.

### Phase 5 — Production (1 week)
- Headless build pipeline (`Godot --headless --export-debug LinuxServer`).
- Deploy to a $5 VPS (Hetzner / DigitalOcean), `systemd` service, log rotation.
- Add a tiny stats endpoint (HTTP /status JSON: tick, players, uptime).

### Phase 6 — Nice to have
- Nakama integration for accounts, friends, leaderboards.
- Multiple regional servers with latency-based picker.
- Replays (record snapshot stream → play back).

## 8. Things to Decide Before Starting

1. **Hosting region** (US / EU / Asia first?).
2. **Account system?** v1 = anonymous + nickname; v2 = Google Play Games.
3. **Server cost cap** before adding monetization (ads/cosmetics).
4. **Lock-step vs snapshot** — recommend snapshot; lock-step needs deterministic
   floats which Godot does not guarantee across mobile chips.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Mobile network drops | Reconnect with same player ID (5 s grace). |
| 250 ms+ RTT players | Generous prediction window, tolerant collision radius. |
| Cheaters reverse-engineering ENet packets | Server validates everything; client is dumb renderer. |
| Server crash drops 20 players | systemd auto-restart; periodic snapshot dump for warm restart. |
| Body sync looks wrong after disconnect | On reconnect, server re-sends full segment history. |

## 10. Out of Scope (v1)

- Voice chat, text chat, friend invites.
- Cross-region matchmaking.
- Persistent player progression (unlocks stay client-local for now).
- Spectator mode.
