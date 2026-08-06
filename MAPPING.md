# Alpha Server a0.2.1 — class mapping

Server jar: `server/jars/a0.2.1.jar` (sha1 `c6217416ce92eb91d1511392f21f830746937418`)
Decompiled to `server/src-obf/` with Vineflower 1.10.1.

Pairs with client **a1.1.2_01** — both speak **protocol 2** in vanilla.
(`a0.2.2`–`a0.2.3` = protocol 3, `a0.2.4` = 4, `a0.2.5*` = 5. Those reject this client.)
This patch set bumps the wire protocol to **100** on both sides — see the README.

Our own additions to `server/src/` use readable names (`DataWatcher.java`,
`PacketSoundEffect.java`, …); everything vanilla stays obfuscated and is what this
table is for.

## Confirmed mappings

Identified by structural/string fingerprint against the deobfuscated client source
in `ooneys-Alpha-Patches-master/source/` (and, where noted, by the b1.7.3 analogue).

### Core / world

| Server class | Client equivalent | Evidence |
|---|---|---|
| `net/minecraft/server/MinecraftServer.java` | — | shipped unobfuscated; contains `main`; command loop |
| `dy.java` | `World` (base) | listener walk, sound raise, AABB entity queries |
| `ee.java` | `World` (server subclass) | instantiates both mob spawners, overrides tick `e()` |
| `eb.java` | — (`IWorldAccess` impl) | the server's only world listener; empty sound/particle stubs we filled |
| `be.java` | `IWorldAccess` | the listener interface `eb` implements |
| `bl.java` | `SpawnerAnimals` | `HashSet` of eligible chunks + constant `576` |
| `hu.java` | monster-spawner subclass | `class hu extends bl` |
| `ft.java` | — (player list mgr) | holds the `ea` list; our `sendToAllNear*` live here |
| `fw.java` | `EntityTracker` | per-type range/frequency dispatch |
| `fy.java` | `EntityTrackerEntry` | spawn-packet factory `b()` throws "Don't know how to add" |
| `gr.java` | `EntityList` | name/id registration ("Creeper", 50, …) |
| `ew.java` | login/net handler | holds the `"Outdated client!"` protocol check |
| `id.java` | `NetServerHandler` | movement/dig/place/chat packet handlers; calls `ea.i()` |
| `gj.java` | `MathHelper` | `b()` floor, `d()` round-to-256ths |
| `dg.java` | `AxisAlignedBB` | static factory `b(x1,y1,z1,x2,y2,z2)` + pool `a()` |
| `s.java` | `NBTTagCompound` | `a(String, byte)` write, `l()` getBoolean, `d()` getInteger |
| `in.java` | `ItemInWorldManager` | per-player dig state; `c()` = harvestBlock, our packet-62 hook |
| `im.java` | `Chunk` | `a(long)` seeded random used by slime spawn check |
| `ff.java` | `Block` | static block registry `ff.n[]`, ids `bc` |
| `ez.java` | `Item` | static item registry, `aS` shifted index |
| `gp.java` | `ItemStack` | `a` stackSize, `c` itemID, `d` damage |
| `ix.java` | `ItemFood` | 2-int ctor (id, heal); our eat action lives here |
| `bd.java` | `ItemSoup` | `extends ix` |
| `iq.java` | `Material` | solidity checks in placement |

### Entities

| Server class | Client equivalent | Evidence |
|---|---|---|
| `dj.java` | `Entity` | base; our `dataWatcher`/`entityInit()` were added here |
| `is.java` | `EntityLiving` | health field, clamp `> 20` pattern |
| `gh.java` | `EntityCreature` | `extends is`; `at`/`fg` extend it |
| `at.java` | `EntityAnimal` | abstract, `extends gh implements ab` |
| `fg.java` | `EntityMob` | `extends gh implements dz` |
| `ab.java` | `IAnimals` (marker) | empty interface; the tracker's mob branch checks it |
| `dz.java` | `IMobs` | `extends ab`; monster-spawner filter class |
| `fc.java` | `EntityPlayer` (server) | `extends is`, health `= 20` |
| `ea.java` | `EntityPlayerMP` | per-player net handler field `a`; `yOffset = 0` |
| `eu.java` | `EntityCreeper` | `/mob/creeper.png`; swell state we mirror |
| `cj.java` | `EntitySheep` | `/mob/sheep.png`, `"Sheared"` NBT |
| `gu.java` | `EntityPig` | `"Saddle"` NBT |
| `fh.java` | `EntitySlime` | `"Size"` NBT, splits on death, `extends is implements dz` |
| `ek.java` | `EntitySkeleton` | creeper's record-drop check references it |
| `fm.java` | `EntityZombie` | `gr` registers "Zombie" |
| `bk.java` | `EntitySpider` | `gr` "Spider" |
| `q.java` | `EntityGiant` | `gr` "Giant" |
| `ay.java` | `EntityCow` | `gr` "Cow" |
| `hi.java` | `EntityChicken` | `gr` "Chicken" |
| `bx.java` | `EntityTNTPrimed` | `"Fuse"` NBT, 80-tick fuse, explodes via `dy.a(null,…)` |
| `hc.java` | `EntityFallingSand` | `gr` "FallingSand" |
| `fn.java` | `EntityItem` | `gr` "Item"; tracked at (64, 20) |
| `ih.java` | `EntityMinecart` | type field `ae` → AddObject 10/11/12 |
| `es.java` | `EntityBoat` | `gr` "Boat"; vanilla never tracked it — tracked + placeable since C8 (2026-08-05) |
| `di.java` | `EntityArrow` | `gr` "Arrow" |
| `az.java` | `EntitySnowball` | `gr` "Snowball" |
| `bu.java` | `EntityPainting` | `gr` "Painting" |

### Blocks and items we have touched

| Server class | Client equivalent | Evidence |
|---|---|---|
| `bi.java`, `iv.java` | `ItemBlock` (variants) | place + step sound, `--stack` |
| `ia.java` | `ItemHoe` | tills grass/dirt → farmland, 1-in-8 seed drop |
| `bh.java` | `ItemSword` | weaponDamage `4 + tier*2`; our `hitEntity` wears 1/hit (durability audit) |
| `cp.java` | `ItemTool` | tier fields, effective-blocks array; our `hitEntity` wears 2/hit |
| `ap.java` | `ItemBucket` | isFull field; our `a()` is the ported raytrace use action (E) |
| `bz.java` | `ItemBow` | our `a()` is the ported instant-fire (E) |
| `ch.java` | `ItemSnowball` | our `a()` spawns the tracked throw (E) |
| `fs.java` | `ItemBoat` | our `a()` is the ported placement raytrace (C8) |
| `hz.java` | `ItemFlintAndSteel` | ignite; except-player sound broadcast (actor echo) |
| `ie.java` | `BlockDoor` | `random.door_open`/`_close`, upper/lower half metadata |
| `hs.java` | `BlockLever` | `random.click` in `blockActivated` |
| `ak.java` | `BlockButton` | click on press + scheduled pop-out |
| `ax.java` | `BlockPressurePlate` | entity-list trigger, click at y+0.1 |
| `bs.java` | `TileEntityMobSpawner` | default `"Pig"` (see PARITY E) |

### Packets (vanilla ids — ours are listed in [PACKETS.md](../reference/b1.7.3/PACKETS.md))

| Server class | Packet | Evidence |
|---|---|---|
| `hp.java` | `Packet` (base) | static id table |
| `hd.java` | 14 PlayerDigging | statuses 0 start / 1 dig / 2 stop |
| `fe.java` | 15 PlayerBlockPlacement | y and direction are unsigned bytes; -1/255/-1 = our no-target form |
| `dl.java` | 23 AddObject | int,byte,int,int,int layout; types 1/10/11/12 (+50 ours) |
| `gv.java` | 24 MobSpawn | carries `gr` numeric id (the id-91 bug) |
| `c.java` | 20 NamedEntitySpawn | built from `fc` in `fy.b()` |
| `k.java` | 21 PickupSpawn | built from `fn` in `fy.b()` |
| `ct.java` | 29 DestroyEntity | sent by `fy.a()` on untrack |
| `ex.java` | 30 Entity | no-move keepalive in `fy`'s ladder |
| `dr.java` | 31 RelEntityMove | byte deltas |
| `cx.java` | 32 EntityLook | yaw/pitch only |
| `bg.java` | 33 RelEntityMoveLook | deltas + look |
| `cf.java` | 34 EntityTeleport | absolute, when delta overflows a byte |

## Mob spawner registration (`ee.java`) — resolved

```java
private bl C = new hu(this, 200, dz.class, new Class[]{fm, ek, eu, bk, fh});  // monsters, cap 200
private bl D = new bl(15, at.class, new Class[]{cj, gu, ay, hi});             // animals, cap 15
```

`dz` is the `IMobs` **interface** and `at` the `EntityAnimal` base class (not two base
classes as an earlier pass guessed). Monsters: Zombie, Skeleton, Creeper, Spider,
Slime. Animals: Sheep, Pig, Cow, Chicken.

## Status: source tree builds and runs

See [BUILD.md](BUILD.md). `src/` compiles clean and the rebuilt jar reaches `Done!`.

Only `do` and `if` were actual Java keywords; they are now `BlockStairs` and `Path`.
`in` and `is` are legal identifiers and were left as-is — so `is.java`
(`EntityLiving`) needed no rename.

The stray zero-byte `null` file is genuine — it exists in Mojang's original jar too.

## Historical findings (both since resolved — kept because they explain the design)

- **Monsters are gated, not absent**: `monsters=true` in `server.properties` enables
  monster spawning with no code changes (`ee.e()` gates `C.a(this)` on it). Animals
  always spawn.
- **Health existed server-side but had no wire format**: `is` tracked health, `fc` set
  20, and the protocol had no id 8 — the machinery existed on both ends with no link.
  That gap is exactly what packets 7/8/9 (and later 28/38/40/60/61) filled; the full
  current table is [PACKETS.md](../reference/b1.7.3/PACKETS.md).
