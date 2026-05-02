# Wild Thyme Herd Dynamics


**1. Herd Center Pull**

Every time a cow picks a walk direction, it checks how far it is from the average position of all non-wanderer cows. If it's drifted more than 80 pixels away, a pull toward the center is added to its direction.

Variables that affect it:
- `herd_cohesion` — base strength of the pull
- `happiness` — via `get_effective_cohesion()`, happier cows pull stronger
- `days_in_herd` — via `get_effective_cohesion()`, experienced cows pull stronger
- Distance from herd center — further away = stronger pull, close = barely felt

---

**2. Lead Cow Following**

On top of the herd center pull, every non-wanderer cow feels a gentle pull toward wherever the current lead cow is standing. If the lead wanders to a new area, the whole herd gradually drifts that way.

The lead cow is determined by HerdManager every 10 seconds using this score:
```
score = happiness + (days_in_herd * 0.1) + (confidence * 0.2)
```

Variables that affect it:
- `happiness` — higher happiness = more likely to be lead
- `days_in_herd` — more experience = more likely to be lead
- `confidence` — permanent personality trait, tiebreaker
- `herd_cohesion` — affects how strongly others follow the lead
- `is_wanderer` — wanderers are excluded from lead calculation entirely

---

**3. Favourite Spot Pull**

A very gentle long term drift toward each cow's personal favourite spot on the map. Much weaker than herd cohesion — just a subtle tendency to hang around a particular area over many walk cycles.

Variables that affect it:
- `favourite_spot` — the Vector2 position assigned at birth or startup
- Distance from spot — stronger when far away, fades as they approach
- Bias is fixed at 0.05-0.2 — intentionally weak so herd cohesion dominates

---

**4. Short Range Separation**

When cows get within 25 pixels of each other, they gently push apart. This stops them stacking directly on top of each other while still allowing them to clump at medium range.

Variables that affect it:
- Nothing tunable currently — fixed 25 pixel radius and 0.5 strength
- Only applies to non-wanderer cows via `get_nearby_cows()`

---

**5. Panic Spreading**

When a cow enters FLEE state from the mouse, it registers itself as panicking in HerdManager. Nearby cows check this each tick via `bt_check_herd_panic` — if panic is detected nearby, they roll against their skittishness to decide whether to also flee.

Variables that affect it:
- `skittishness` — 0=ignores panic, 1=always catches panic
- `panic_radius` in HerdManager — how far panic spreads (default 150px)
- `panic_duration` in HerdManager — how long a panic event lasts (default 3s)
- `is_wanderer` — wanderers don't participate in panic spreading

---

**6. `get_effective_cohesion()` — the glue**

This function is called wherever herd cohesion strength is needed. It combines three things into one value:

```
effective_cohesion = herd_cohesion + (happiness * 0.3) + (clamp(days_in_herd * 0.02, 0, 0.3))
```

So a cow with:
- `herd_cohesion = 0.4`
- `happiness = 0.8`
- `days_in_herd = 10`

Gets effective cohesion of `0.4 + 0.24 + 0.2 = 0.84` — strongly bonded to the herd.

A new calf with:
- `herd_cohesion = 0.2`
- `happiness = 0.5`
- `days_in_herd = 0`

Gets `0.2 + 0.15 + 0.0 = 0.35` — loosely bonded, still finding their place.

---

**7. Wanderer Isolation**

Cows with `is_wanderer = true` are excluded from all herd calculations:
- Not included in herd center calculation
- Not included in `get_nearby_cows()` results
- Not eligible to be lead cow
- Don't feel herd center or lead cow pull
- Have `herd_cohesion = 0.0` so `get_effective_cohesion()` returns near zero

The `familiarity` variable exists on wanderers but isn't wired up yet — that's the future mechanic for gradually joining the herd.

---

**Summary of all variables and where they live:**

On the **cow script:**
- `herd_cohesion: float` — base bond strength, set in Inspector
- `skittishness: float` — panic sensitivity, set in Inspector
- `confidence: float` — permanent personality, assigned at birth
- `days_in_herd: int` — increments each safe night
- `happiness: float` — overall wellbeing, affected by night outcomes
- `favourite_spot: Vector2` — assigned at birth from GameManager
- `is_wanderer: bool` — excludes from all herd dynamics
- `familiarity: float` — wanderer only, not yet wired up

In **HerdManager:**
- `panic_radius: float` — how far panic spreads
- `panic_duration: float` — how long panic lasts
- `lead_update_interval: float` — how often lead cow recalculates
- `current_lead: Node` — the current lead cow reference