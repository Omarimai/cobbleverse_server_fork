# Cobbleverse Server In Docker Compose
## 

## What Exactly Is This?
### Cobbleverse
Cobbleverse is a modpack (collection of mods) for Java Minecraft that bring an experience much like the main series of Pokemon games to the world of Minecraft

### Docker
Docker is a way of containerizing applications and their dependencies, and does so in a way very akin to virtual machines

### This Particular Solution
This solution will help you set up your own Cobblemon server

## Instructions
### First Run
1) Ensure that you already have Docker/Docker Compose installed
2) Clone the repository
3) Navigate to the folder you cloned this repo to
4) Run the command: `docker-compose up -d` This will instantiate your server (will probably take a minute or two)

#### What will happen when I do this?
1) The system will check to see if the worldname you specified has already been used
2) Assuming it has not, then it will create a new folder for the world
3) If this is a new world, then the mods that make up this modpack will all be downloaded, and saved to the server in the proper spot
4) Next the Minecraft server is started up

### How to Play
The server is using a modpack known as [Cobbleverse](https://modrinth.com/modpack/cobbleverse).
This modpack includes Cobblemon as well as many sidemods to help recreate a Pokemon-like experience.
If your server is running mods, then your Minecraft client (the game itself) also needs to have the same mods.

My recommendation is that you use the [Modrinth App](https://modrinth.com/app).  Once it's installed, you can follow the Cobbleverse link above, and it will prompt you to install it into the Modrinth app.  Proceed to do that.  Once you've done that, then you'll actually be able to launch the proper version of Minecraft (equipped with mods) directly from Modrinth there.  That's the recommended approach.
Once in, simply put in the address of your server.  If you're on the same machine, you can use `localhost` or `127.0.0.1`.
Sometimes you need to specify the port number too.  This server will be utilizing port `25565`.
This means you could use `localhost:25565` or `127.0.0.1:localhost`

## Joining the Railway-Hosted Server

This repo is also deployed as a single Railway service (see [Deploying to Railway](#deploying-to-railway) below) running 24/7 in Railway's EU West (Amsterdam) region.

**1) Install the Cobbleverse modpack in the Modrinth App**
- Install the [Modrinth App](https://modrinth.com/app) if you haven't already.
- Open the [Cobbleverse modpack page](https://modrinth.com/modpack/cobbleverse) and click "Install", or search for "Cobbleverse" inside the app.
- Wait for it to finish downloading — this installs the matching Fabric + mods on your own machine so your client matches the server.

**2) Launch Cobbleverse from the Modrinth App**
- In the Modrinth App's Library, click the Cobbleverse instance, then **Play**. This launches Minecraft with the right Fabric loader and all client-side mods already in place.

**3) Add the server**
- In the Minecraft main menu, go to **Multiplayer → Add Server**.
- Server Address:
  ```
  altaria.proxy.rlwy.net:17688
  ```
- Save, then double-click the server entry to connect.

> **Note:** that address is Railway's public TCP proxy for this service. It's stable as long as the proxy isn't deleted/recreated — if it ever stops connecting, check **Railway dashboard → this service → Settings → Networking → TCP Proxy** for the current `domain:port`, since Railway assigns a new random port whenever a proxy is recreated.

If the modpack version installed by the Modrinth App ever drifts from what the server is running, check the `MODRINTH_URL` variable on the Railway service — it pins the exact `.mrpack` build the server installs.

## Deploying to Railway

Railway volumes only attach to one service, so the two-container `docker-compose` split used for local dev (an installer container writing to a shared volume, then `mc` waiting on it) doesn't translate directly. The root [`Dockerfile`](Dockerfile) combines both steps into one container instead: it installs the modpack (`scripts/install-modpack.sh`) and then hands off to `itzg/minecraft-server`'s own startup script (`scripts/railway-entrypoint.sh`), all sharing one Railway volume mounted at `/data`.

Local `docker-compose up` is unaffected — it still uses `Dockerfile.modinstaller` and the two-container setup.

Current Railway setup (project **proud-nurturing**, service **cobbleverse_server_fork**):
- **Build**: root `Dockerfile`, builder pinned to `DOCKERFILE` (see [`railway.json`](railway.json)).
- **Volume**: mounted at `/data` (holds the world, mods, and the downloaded modpack under `/data/modpack`).
- **Region**: `europe-west4` (Amsterdam / EU West).
- **Networking**: a TCP proxy exposes container port `25565` publicly — see the address in the Joining section above, or in the Railway dashboard under this service's Networking settings.
- **Variables**: `EULA`, `TYPE`, `VERSION`, `FABRIC_LOADER_VERSION`, `FABRIC_LAUNCHER_VERSION`, `MEMORY`, `SERVER_WORLDNAME`, `LEVEL`, `ENABLE_WHITELIST`, `DEBUG`, `SERVER_NAME`, `ALLOW_FLIGHT`, `SPAWN_MONSTERS`, `MODRINTH_URL` — same names as `.env.example`, set directly on the Railway service instead of a local `.env` file.

A few things worth knowing if you touch this again:
- **Java version matters.** `itzg/minecraft-server:latest` currently ships Java 25, which breaks Mixin/ASM in Fabric Loader 0.16.10 and several mods in this pack (crash-loops with "Unsupported class file major version 69"). Both the Dockerfile and `docker-compose.yml` pin `java21` explicitly — don't drop that pin without checking the modpack's Fabric/mixin versions still support whatever Java version you switch to.
- **Changing `SERVER_WORLDNAME` starts a brand-new world** (it becomes a new subfolder under `/data`) — don't change it on a running server unless you mean to reset progress.
- A push to `master` auto-deploys (Railway's GitHub integration rebuilds and restarts the service), which also means **any** push — including a docs-only change like this one — restarts the running Minecraft server for a minute or two. If that becomes annoying, set `build.watchPatterns` on the service to skip rebuilds for paths like `*.md`. If a push ever doesn't trigger a build, redeploy manually with `railway redeploy --service <id> --from-source --yes` (or from the dashboard).
