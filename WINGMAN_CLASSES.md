# Wingman Classes Design Document

## Overview

This document outlines the design for all wingman classes in the game, including the existing 3 classes and 7 new classes planned for implementation.

**Total Classes**: 9
- **Existing**: Striker, Heavy, Spread
- **New**: Burst, Shield, Laser, Ricochet, Support, Charge

---

## Class Positioning Matrix

| Class | Fire Rate | Damage | Role | Special Mechanic |
|-------|-----------|--------|------|------------------|
| **Striker** | Very Fast (0.1s) | Low (8) | Sustained DPS | Attack Speed Synergy |
| **Heavy** | Slow (1.0s) | High (25) | Burst Damage | Large Bullet |
| **Spread** | Medium (0.5s) | Medium (12×3) | Area Coverage | Fan Pattern |
| **Burst** | Intermittent | Medium (10×3) | Burst Window | Burst+Cooldown |
| **Shield** | Slow (0.8s) | Low (6) | Defensive Support | Shield Generation |
| **Laser** | Continuous | Very Low (2/tick) | Lock-on DPS | Continuous Beam |
| **Ricochet** | Medium (0.4s) | Medium (10) | Chain Reaction | Bounce Mechanic |
| **Support** | N/A | 0 | Pure Support | Team Buffs |
| **Charge** | Special | Rhythm-based | Charge Burst | Charge Mechanic |

---

## Existing Classes (Implemented)

### 1. Striker 🔵
**Visual**: Circle (ring), Cyan color

**Stats**:
- Damage: 8
- Fire Interval: 0.1s
- Bullet: Single shot, standard size

**Synergy Effects**:
- ×2 Strikers: +50% attack speed (1.5x)
- ×4 Strikers: +100% attack speed (2.0x)

**Role**: High fire rate sustained DPS. Best for consistent damage output.

---

### 2. Heavy 🟡
**Visual**: Square, Yellow color

**Stats**:
- Damage: 25
- Fire Interval: 1.0s
- Bullet: Single shot, large (2x scale)

**Synergy Effects**:
- ×2 Heavy: +50% damage multiplier (1.5x)

**Role**: Slow but powerful shots. Excels at burst damage and high-value targets.

---

### 3. Spread 🟣
**Visual**: Triangle, Purple color

**Stats**:
- Damage: 12 per bullet
- Fire Interval: 0.5s
- Bullets: 3 shots in fan pattern (-15°, 0°, +15°)

**Synergy Effects**:
- ×2 Spread: +50% bullet size (1.5x)

**Role**: Area coverage. Effective against multiple enemies or dodging targets.

---

## New Classes (Planned)

### 4. Burst 💥
**Visual**: Triple-star shape, Orange color

**Stats**:
- Damage: 10 per bullet
- Fire Pattern: 3-round burst (0.05s between shots), then 0.8s cooldown
- Total Burst Damage: 30 (3×10)
- Effective Fire Rate: 0.28s per bullet average

**Synergy Effects**:
- ×2 Burst: Increases burst to 4 rounds (40 damage)
- ×3 Burst: Cooldown reduced by 30% (0.56s)
- ×4 Burst: Burst increased to 5 rounds + 20% damage per bullet (50 damage total)

**Role**: Burst window DPS. Creates damage spikes followed by reload periods. Good for timing-based play.

---

### 5. Shield 🛡️
**Visual**: Hexagon, Blue color

**Stats**:
- Damage: 6
- Fire Interval: 0.8s
- Special: Generates a small shield every 10 seconds (absorbs 20 damage)

**Synergy Effects**:
- ×2 Shield: Shield absorption +50% (30 damage)
- ×3 Shield: Shield generation interval -30% (7 seconds)
- ×4 Shield: Can maintain 2 shields simultaneously

**Role**: Defensive support. Sacrifices damage output for survivability. Shield orbits player or protects specific allies.

---

### 6. Laser ⚡
**Visual**: Crossed dual lines, Red color

**Stats**:
- Damage: 2 per tick (0.05s tick rate)
- Fire Interval: 0.6s (between laser activations)
- Duration: 0.3s lock-on per activation
- Total Damage per Activation: 12 (6 ticks)
- Special: Locks onto nearest enemy with continuous beam

**Synergy Effects**:
- ×2 Laser: Duration +0.2s (0.5s total, 20 damage)
- ×3 Laser: Can lock 2 targets simultaneously
- ×4 Laser: Damage per tick +50% (3 damage/tick)

**Role**: Sustained lock-on damage. Excellent against high-HP targets. Doesn't require aiming.

---

### 7. Ricochet 🎱
**Visual**: Diamond shape, Silver color

**Stats**:
- Damage: 10 (initial hit)
- Fire Interval: 0.4s
- Special: Bounces to nearby enemy after hit (max 2 bounces)
- Bounce Range: 50 units
- Damage Decay: -30% per bounce (10 → 7 → 4.9)

**Synergy Effects**:
- ×2 Ricochet: Bounce count +1 (total 3 bounces)
- ×3 Ricochet: No damage decay on bounces
- ×4 Ricochet: Bounce range +50% (75 units)

**Role**: Chain reaction damage. Explosive DPS in crowded situations. Weak against single targets.

---

### 8. Support ✨
**Visual**: Star or cross shape, Gold color

**Stats**:
- Damage: 0 (does not fire)
- Buff Interval: Every 3 seconds
- Special: Buffs nearby allies (+15% attack speed for 2 seconds)
- Buff Targets: 2 closest wingmen

**Synergy Effects**:
- ×2 Support: Buff power increased to +25% attack speed
- ×3 Support: Buff range expanded to 3 wingmen + player main weapon
- ×4 Support: Adds +15% damage buff on top of attack speed

**Role**: Pure support. Amplifies team damage output. Requires other damage dealers to be effective.

---

### 9. Charge ⚡⚡
**Visual**: Circle with lightning center, Cyan-white color

**Stats**:
- Damage: 5 (normal shots), 50 (charged shot)
- Fire Pattern: Cycles - 3 normal shots (0.3s interval) → 1 charged shot
- Normal Shot: 5 damage, standard size
- Charged Shot: 50 damage, 1.5x size
- Total Cycle Time: ~1.2s (0.9s for 3 shots + 0.3s for charged)
- Average DPS: ~16.7

**Synergy Effects**:
- ×2 Charge: Charge requirement reduced to 2 normal shots
- ×3 Charge: Charged shot damage ×1.5 (75 damage)
- ×4 Charge: Normal shot damage increased to 8

**Role**: Rhythm-based damage. Rewards timing and positioning. Mix of sustained and burst damage.

---

## Team Composition Strategies

### 1. Burst Flow Build
**Composition**: Burst ×3 + Charge ×2  
**Strategy**: High burst damage windows. Time abilities for maximum spike damage.  
**Best Against**: Boss phases, high-priority targets

### 2. Survival Build
**Composition**: Shield ×3 + Support ×2  
**Strategy**: Maximum tankiness with sustained buffs. Slower but safer progression.  
**Best Against**: Bullet hell patterns, sustained fights

### 3. Laser Lock Build
**Composition**: Laser ×3 + Striker ×2  
**Strategy**: Lock-on continuous damage. Focus on dodging while lasers track targets.  
**Best Against**: High HP enemies, mobile targets

### 4. Chain Reaction Build
**Composition**: Ricochet ×3 + Spread ×2  
**Strategy**: Explosive damage against crowds. Weak single-target but destroys groups.  
**Best Against**: Swarm waves, densely packed enemies

### 5. Mixed DPS Build
**Composition**: Striker ×2 + Laser ×2 + Burst ×2  
**Strategy**: Diversified consistent damage. No weak points, no specific strengths.  
**Best Against**: General purpose, all-around performance

### 6. Support Core Build
**Composition**: Support ×2 + Heavy ×2 + Striker ×2  
**Strategy**: Amplify existing damage dealers. Support multiplies effectiveness.  
**Best Against**: Maximizing team DPS, scaling late game

---

## Visual Differentiation System

### Color Coding
- **DPS Classes**: Warm colors (Red, Orange, Yellow, Cyan)
  - Striker: Cyan
  - Heavy: Yellow
  - Burst: Orange
  - Charge: Cyan-White
  
- **Utility Classes**: Cool colors (Blue, Purple, Silver)
  - Spread: Purple
  - Shield: Blue
  - Laser: Red
  - Ricochet: Silver
  
- **Special Classes**: Unique colors (Gold, White)
  - Support: Gold
  - Missile: Gray

### Shape Recognition
- **Circular/Stars**: Sustained DPS (Striker, Charge, Support)
- **Square/Diamond**: Heavy/Special mechanics (Heavy, Ricochet)
- **Triangle**: Area attacks (Spread)
- **Special Shapes**: Functional roles (Shield hexagon, Missile rocket, Laser cross, Burst triple-star)

---

## Balance Considerations

### DPS Tiers (Approximate)
**High DPS**: Striker, Heavy (with synergy), Laser (with synergy)  
**Medium DPS**: Spread, Burst, Ricochet, Charge, Missile  
**Low DPS**: Shield  
**No DPS**: Support (but amplifies others)

### Skill Floor/Ceiling
**Easy**: Striker, Laser (auto-targeting)  
**Medium**: Heavy, Spread, Shield, Support  
**Hard**: Burst (timing), Charge (rhythm), Ricochet (positioning)

### Synergy Requirements
- **Low Threshold** (2 units): Most classes unlock basic synergy
- **Medium Threshold** (3 units): Meaningful power spike
- **High Threshold** (4 units): Build-defining effects

---

## Implementation Priority

### Phase 1: Core Mechanics (Implemented)
1. **Burst** ✅ - Burst firing patterns
2. **Laser** ✅ - Continuous beam mechanics

### Phase 2: Advanced Mechanics
4. **Ricochet** - Tests bounce/chain mechanics
5. **Charge** - Tests state machine patterns

### Phase 3: Support Systems
6. **Shield** - Tests defensive mechanics
7. **Support** - Tests buff/aura systems

---

## Future Expansion Ideas

- Elite variants (upgraded versions with enhanced visuals)
- Combination mechanics (certain pairs trigger special effects)
- Ultimate abilities (activated on synergy milestones)
- Visual evolution (classes change appearance at level thresholds)

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-02  
**Status**: Design phase - awaiting implementation
