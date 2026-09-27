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

### Playing with a Non-Premium Account (TLauncher)

The server has `ONLINE_MODE` set to `false`, so it doesn't check accounts against Mojang and accepts non-premium clients like [TLauncher](https://tlauncher.org/). Keep in mind this also means the server no longer verifies who's logging in — anyone who knows the address can join as any username, so it's meant for a trusted group of players, not a public server.

TLauncher doesn't import `.mrpack` files directly, so the mods have to be placed by hand:

1. In TLauncher, create/select a profile for **Minecraft 1.21.1** with **Fabric Loader 0.16.10** (TLauncher's version list lets you install a Fabric version the same way the vanilla launcher does). Launch it once so it creates the profile's folder structure, then close the game.
2. Get the same mod files the server is running: download the modpack from the `MODRINTH_URL` set on the Railway service (currently the Cobbleverse `.mrpack` — you can also just install Cobbleverse via the [Modrinth App](https://modrinth.com/app) as in the steps above purely to fetch the files) and unzip it.
3. Copy the contents of its `mods/` (and `resourcepacks/`, `shaderpacks/` if you want them) into that TLauncher profile's `.minecraft/mods` folder. Server-only mods don't hurt anything if included, but if you want a lighter client you only strictly need the mods that aren't purely server-side.
4. Launch that profile from TLauncher and add the server the same way as step 3 above (**Multiplayer → Add Server** → `altaria.proxy.rlwy.net:17688`).

Mod versions on the client need to match what the server has installed — if TLauncher shows a "mismatched mods" or version error on connect, double check the Fabric Loader version and that the `mods/` folder matches the pack currently at `MODRINTH_URL`.

## Deploying to Railway

Railway volumes only attach to one service, so the two-container `docker-compose` split used for local dev (an installer container writing to a shared volume, then `mc` waiting on it) doesn't translate directly. The root [`Dockerfile`](Dockerfile) combines both steps into one container instead: it installs the modpack (`scripts/install-modpack.sh`) and then hands off to `itzg/minecraft-server`'s own startup script (`scripts/railway-entrypoint.sh`), all sharing one Railway volume mounted at `/data`.

Local `docker-compose up` is unaffected — it still uses `Dockerfile.modinstaller` and the two-container setup.

Current Railway setup (project **proud-nurturing**, service **cobbleverse_server_fork**):
- **Build**: root `Dockerfile`, builder pinned to `DOCKERFILE` (see [`railway.json`](railway.json)).
- **Volume**: mounted at `/data` (holds the world, mods, and the downloaded modpack under `/data/modpack`).
- **Region**: `europe-west4` (Amsterdam / EU West).
- **Networking**: a TCP proxy exposes container port `25565` publicly — see the address in the Joining section above, or in the Railway dashboard under this service's Networking settings.
- **Variables**: `EULA`, `TYPE`, `VERSION`, `FABRIC_LOADER_VERSION`, `FABRIC_LAUNCHER_VERSION`, `MEMORY`, `SERVER_WORLDNAME`, `LEVEL`, `ENABLE_WHITELIST`, `DEBUG`, `SERVER_NAME`, `ALLOW_FLIGHT`, `SPAWN_MONSTERS`, `MODRINTH_URL` — same names as `.env.example`, set directly on the Railway service instead of a local `.env` file. Also `ONLINE_MODE=false` (not in `.env.example`, itzg-specific) so non-premium clients like TLauncher can connect — see the Joining section above.

A few things worth knowing if you touch this again:
- **Java version matters.** `itzg/minecraft-server:latest` currently ships Java 25, which breaks Mixin/ASM in Fabric Loader 0.16.10 and several mods in this pack (crash-loops with "Unsupported class file major version 69"). Both the Dockerfile and `docker-compose.yml` pin `java21` explicitly — don't drop that pin without checking the modpack's Fabric/mixin versions still support whatever Java version you switch to.
- **Changing `SERVER_WORLDNAME` starts a brand-new world** (it becomes a new subfolder under `/data`) — don't change it on a running server unless you mean to reset progress.
- A push to `master` auto-deploys (Railway's GitHub integration rebuilds and restarts the service), which also means **any** push — including a docs-only change like this one — restarts the running Minecraft server for a minute or two. If that becomes annoying, set `build.watchPatterns` on the service to skip rebuilds for paths like `*.md`. If a push ever doesn't trigger a build, redeploy manually with `railway redeploy --service <id> --from-source --yes` (or from the dashboard).
