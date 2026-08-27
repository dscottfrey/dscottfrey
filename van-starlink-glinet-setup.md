# Van Starlink Mini + GL.iNet (GL-MT3000) Reference

Hardware: Starlink **Mini** (router built into dish) + **GL-MT3000 (Beryl AX)**, firmware **4.8.1** (LuCI = OpenWrt 21.02).
Starlink is run in **Bypass Mode** so the GL-MT3000 is the only router.

---

## Current setup (as configured)

- **Physical:** Starlink Mini Ethernet port → GL-MT3000 **WAN** port.
- **Starlink:** **Bypass Mode ON** (Mini's own WiFi/router/DHCP disabled; it just passes the connection through).
- **GL-MT3000 WAN:** DHCP client (`eth0`). Pulls its address from the dish automatically.
- **Internet config:** Failover — **WiFi repeater (home network) first**, **Ethernet/Starlink second**. In the driveway it relays the home network; on the road it uses Starlink.
- **Static route to reach the dish** (LuCI → Network → Static Routes):
  - Interface: `wan`
  - Target: `192.168.100.0`
  - Netmask: `255.255.255.0`
  - Gateway: `192.168.100.1`
  - Metric: `0`

---

## Reaching the dish from the van

The dish always lives at the fixed IP **`192.168.100.1`** (ports: 22 ssh, 80 http, 9200 gRPC).

- **Primary method — Starlink app:** Connect a device to the **VanNet (GL-MT3000) WiFi**, open the Starlink app. It reaches the dish through the static route above. This is what you use for stow/unstow, aiming, obstruction checks, snow melt, speed test, stats. **Verified working on VanNet.**
- **Browser (optional):** `http://192.168.100.1/support/statistics` and `http://192.168.100.1/support/debug` may also work for raw stats. The app is the reliable channel; the browser page is firmware-dependent.

**Notes / gotchas learned during setup:**
- The static route only reaches the dish **once Bypass Mode is ON.** In default (router) mode it won't, because the dish sits behind the Starlink router on a different subnet.
- Running the **iPad Starlink app on a Mac** can show connect/drop/connect cycling. This is the **app losing and regaining its connection to the dish** — a software/environment artifact of the iPad app running on macOS. It is **not** the dish going offline and **not** an obstruction. The native phone/iPad app connects cleanly.
- A device on the wrong network (home WiFi, or a tailnet subnet-route path) can give misleading results. Test from a device actually on **VanNet**.

---

## Roam plan — turn ON / OFF (on the road)

Enabling/disabling Roam is an **account/billing action done over the internet** — it does **not** need the local dish page or Bypass.

1. Make sure the device has **internet** (through the GL-MT3000).
2. Go to **starlink.com → log in → account homepage → Manage** next to the device → change plan / Standby, **or** do it in the **Starlink app** (account/subscription section).
3. To "turn it off" when done, switch the line back to **Standby Mode** (note: as of Aug 2025 this is **$5/month**, not the old free pause).

---

## ⭐ FACTORY RESET — exit Bypass Mode (the escape hatch)

This is the guaranteed, offline way to undo Bypass and get the Mini back to normal (its own WiFi). **No internet, no app, no GL.iNet needed.** Repeatable any number of times — there is **no limit** on how often you can reset.

> The Mini uses a **physical reset button on the back of the dish.** (This is NOT the "6× power cycle" method — that's for the Gen 2 router, not the Mini.)

**Procedure:**

1. Make sure the **Mini is powered on.**
2. Locate the **recessed reset button on the back of the Mini dish** (needs a paperclip / SIM-eject tool).
3. **Press and hold ~3 seconds**, until the **LED flashes rapidly.**
4. Release. **Wait a few minutes** for it to reboot — LED settles to a **slow white blink.**
5. The default **`STARLINK` WiFi network reappears** = Bypass is cleared, Mini is back to normal router mode.
6. Reconnect to **`STARLINK`** WiFi, open the Starlink app, and re-do WiFi setup (name/password) if desired.

After a reset, to go back to the van setup: re-enable **Bypass Mode**, then confirm the GL-MT3000 has internet and the dish is reachable at `192.168.100.1` from VanNet.

---

## Quick recovery checklist (if dish unreachable on the road)

1. Is the **GL-MT3000 getting internet?** (Check admin → WAN/Internet status.) If yes, the link is fine; the issue is just dish-page access.
2. Is the test device actually on **VanNet** (not home WiFi / not a stale tailnet path)?
3. Try the **Starlink app** (more reliable than the browser).
4. Give it **2–3 minutes** after any bypass/Ethernet change — the WAN re-DHCPs and the path needs to settle before it works.
5. Still stuck and you need the Mini's own WiFi back → **factory reset** (procedure above).

---

## Reference values

| Item | Value |
|---|---|
| Dish IP (fixed) | `192.168.100.1` |
| Dish ports | 22 (ssh), 80 (http), 9200 (gRPC) |
| GL-MT3000 admin | `http://192.168.8.1` |
| GL-MT3000 LuCI | `http://192.168.8.1:8080` (or via admin → System → Advanced) |
| GL-MT3000 LAN | `192.168.8.1/24` |
| Static route | `192.168.100.0 / 255.255.255.0 / gw 192.168.100.1 / iface wan` |
| Mini reset | Rear button, hold ~3 sec, LED flashes fast |
