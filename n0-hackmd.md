-- summary of ipfs-embed api for n0 / iroh team

# Ipfs-Embed and SQLite block store

Design decisions and rationale

## Local block api

insert (sync)
get (sync)

```rust
// Returns a block from the block store.
pub fn get(&self, cid: &Cid) -> Result<Block<P>>

// Inserts a block in to the block store.
pub fn insert(&self, block: Block<P>) -> Result<()>

// Checks if the block is in the block store.
pub fn contains(&self, cid: &Cid) -> Result<bool>
```

### Why?

accessing local data is extremely fast. Microseconds for small blocks. Too much overhead and inconvenience to make it async. 

More convenient to write complex data structures when getting blocks is sync. See e.g. https://github.com/actyx/banyan

Even disregarding the sync/async decision, I am very convinced that it is good to have a separate API for accessing data that is known to be local.

Note: actyx apps are supposed to work even when a device is completely offline. Local first.

## Temp pins

create_temp_pin (sync)
temp_pin (sync)

- no problem to have millions of temp pins
- persist only until restart
- RAII pattern
- currently recursive, but typically not needed

```rust
// Creates a temporary pin in the block store. A temporary pin is not persisted to disk and is released once it is dropped.
pub fn create_temp_pin(&self) -> Result<TempPin>

// Adds a new root to a temporary pin.
pub fn temp_pin(&self, tmp: &mut TempPin, cid: &Cid) -> Result<()>
```

### Why

while building a DAG you want a way to protect your half-finished DAG or DAG update from GC that could run at any time.

In go-ipfs / kubo, GC runs very rarely. Once per day. In actxy it runs once per minute or more often.

Building a DAG is always done from the bottom up, so recursively pinning just the current root(s) is inconvenient.

## Named pins (aka aliases)

alias (sync)

- recursive
- typlically few aliases
- an alias is a blob
- persistent

```rust
pub fn alias<T: AsRef<[u8]> + Send + Sync>(
    &self,
    alias: T,
    cid: Option<&Cid>
) -> Result<()>
```

### Why

an alias is for a DAG you want to keep permanently. Aliases are persistent. They are always recursive.

E.g. if you sync a dynamic DAG from somewhere else, you have an alias pointing to the most recent complete sync, and update it once you have synced more.

Notable difference from IPFS: an alias will protect a DAG from GC even while it is being synced.

Syncing is always top down from the root.

## Network api

fetch (async, like get for go-ipfs / kubo)
sync (progress stream, sync entire DAG)

How to prevent data during a long sync from being GCed: alias or temp pin the root, then everything "hanging" from the root will be protected even as the dag is being synced.

```rust
pub async fn fetch(&self, cid: &Cid, providers: Vec<PeerId>) -> Result<Block<P>>
// Either returns a block if it’s in the block store or tries to retrieve it from a peer.

pub fn sync(&self, cid: &Cid, providers: Vec<PeerId>) -> SyncQuery<P>
// sync an entire DAG
```

### Why?

We found it very rarely useful to traverse a DAG via the network. Lots of roundtrips, nasty code etc. What you usually want is to first sync a DAG and then traverse it from local data once it is fully synced.

## GC

Gc is somewhat incremental
Minimum number of blocks per GC call
Target time for GC call

```rust
pub struct StorageConfig {
    ...
    pub gc_interval: Duration,
    pub gc_min_blocks: usize,
    pub gc_target_duration: Duration,
    ...
}
```

### Why

you want to run GC frequently, but you don't want long breaks. So `gc_target_duration` is a rough estimate how long of a GC pause is acceptable. But - you also want a guarantee that GC will make progress. That is what `gc_min_blocks` is for. GC will ignore time constraints until at least gc_min_blocks are collected or until there is no more garbage.

## Caching

- target size (in kb and number of blocks)
- store keeps track of accesses for caching purposes
- Tracking can be either persistent or ephemeral
- Default strategy is LRU
- you could do something more sophisticated like prefer to keep things that are higher up a DAG

```rust
pub struct StorageConfig {
    ...
    pub access_db_path: Option<PathBuf>,
    pub cache_size_blocks: u64,
    pub cache_size_bytes: u64,
    ...
}
```

### Why?

In addition to app related DAG data that needs to be complete, actyx deals with assets such as videos, images etc. in unixfs format. For these you typically want LRU. You can track access in a separate SQLite database with less strict transactionality, or in memory, or not at all.

Why separate size and count: otherwise a large number of tiny nodes could overwhelm the system. E.g. a video with 1GB and 1000 blocks is not as bad as a IPLD DAG with 1GB and 10000000 nodes for GC.

---

# Some relevant parts of the ipfs-embed API:

```rust
pub fn create_temp_pin(&self) -> Result<TempPin>
// Creates a temporary pin in the block store. A temporary pin is not persisted to disk and is released once it is dropped.

pub fn temp_pin(&self, tmp: &mut TempPin, cid: &Cid) -> Result<()>
// Adds a new root to a temporary pin.

pub fn contains(&self, cid: &Cid) -> Result<bool>
// Checks if the block is in the block store.

pub fn get(&self, cid: &Cid) -> Result<Block<P>>
// Returns a block from the block store.

pub fn insert(&self, block: Block<P>) -> Result<()>
// Inserts a block in to the block store.

pub fn alias<T: AsRef<[u8]> + Send + Sync>(
    &self,
    alias: T,
    cid: Option<&Cid>
) -> Result<()>

pub async fn fetch(&self, cid: &Cid, providers: Vec<PeerId>) -> Result<Block<P>>
// Either returns a block if it’s in the block store or tries to retrieve it from a peer.

pub fn sync(&self, cid: &Cid, providers: Vec<PeerId>) -> SyncQuery<P>
```

```rust
pub struct StorageConfig {
    pub path: Option<PathBuf>,
    pub access_db_path: Option<PathBuf>,
    pub cache_size_blocks: u64,
    pub cache_size_bytes: u64,
    pub gc_interval: Duration,
    pub gc_min_blocks: usize,
    pub gc_target_duration: Duration,
}
```

```rust
pub trait CacheTracker: Debug + Send + Sync {
    fn has_persistent_state(&self) -> bool;

    fn blocks_accessed(&self, blocks: Vec<BlockInfo>) { ... }
    fn blocks_written(&self, blocks: Vec<WriteInfo>) { ... }
    fn blocks_deleted(&self, blocks: Vec<BlockInfo>) { ... }
    fn sort_ids(&self, ids: &mut [i64]) { ... }
    fn retain_ids(&self, ids: &[i64]) { ... }
}
```

# How sync works internally

- loop until no more open ends:
    - find open ends of a DAG
    - ask for them in bulk

Very fast and low roundtrip sync of wide trees, which is what we had at actyx and what is typical for e.g. unixfs.

Does not help much for a linked list/"blockchain" obviously... There you really want something like graphsync