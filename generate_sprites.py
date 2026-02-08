import os
from PIL import Image, ImageDraw

def create_sprite(filename, draw_func, size=(256, 256)):
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(draw, size)

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename)
    print(f"Generated {filename}")

# ==================== PLAYER ====================
def draw_player_ship(draw, size):
    w, h = size
    # Blue and white futuristic jet
    # Body
    draw.polygon([(w/2, h*0.1), (w*0.8, h*0.8), (w*0.5, h*0.7), (w*0.2, h*0.8)], fill=(200, 200, 255), outline=(0, 100, 255))
    # Wings
    draw.polygon([(w*0.5, h*0.4), (w*0.9, h*0.7), (w*0.8, h*0.8)], fill=(0, 100, 255))
    draw.polygon([(w*0.5, h*0.4), (w*0.1, h*0.7), (w*0.2, h*0.8)], fill=(0, 100, 255))
    # Cockpit
    draw.ellipse((w*0.45, h*0.3, w*0.55, h*0.5), fill=(0, 255, 255))
    # Engines
    draw.rectangle((w*0.3, h*0.8, w*0.4, h*0.9), fill=(50, 50, 200))
    draw.rectangle((w*0.6, h*0.8, w*0.7, h*0.9), fill=(50, 50, 200))
    # Glow
    draw.ellipse((w*0.3, h*0.9, w*0.4, h*1.0), fill=(0, 255, 255, 128))
    draw.ellipse((w*0.6, h*0.9, w*0.7, h*1.0), fill=(0, 255, 255, 128))

# ==================== BOSS ====================
def draw_boss(draw, size):
    w, h = size
    # Giant red boss spaceship
    cx, cy = w/2, h/2
    # Main Body
    draw.polygon([(cx, h*0.1), (w*0.9, cy), (w*0.7, h*0.9), (w*0.3, h*0.9), (w*0.1, cy)], fill=(100, 0, 0), outline=(255, 0, 0))
    # Core
    draw.ellipse((cx-30, cy-30, cx+30, cy+30), fill=(255, 0, 0))
    # Eyes
    draw.ellipse((w*0.3, h*0.3, w*0.35, h*0.35), fill=(255, 50, 50))
    draw.ellipse((w*0.65, h*0.3, w*0.7, h*0.35), fill=(255, 50, 50))
    # Armor plates
    draw.line((cx, h*0.1, cx, h*0.9), fill=(50, 0, 0), width=5)
    draw.line((w*0.1, cy, w*0.9, cy), fill=(50, 0, 0), width=5)

# ==================== ENEMIES ====================
def draw_enemy_basic(draw, size):
    w, h = size
    # Small red drone
    cx, cy = w/2, h/2
    draw.rectangle((w*0.3, h*0.3, w*0.7, h*0.7), fill=(150, 0, 0), outline=(255, 0, 0))
    draw.ellipse((cx-10, cy-10, cx+10, cy+10), fill=(255, 0, 0)) # Eye

def draw_enemy_dasher(draw, size):
    w, h = size
    # Arrow shaped
    draw.polygon([(w/2, h*0.1), (w*0.8, h*0.8), (w/2, h*0.6), (w*0.2, h*0.8)], fill=(200, 50, 50), outline=(255, 0, 0))
    # Thrusters
    draw.rectangle((w*0.4, h*0.8, w*0.6, h*0.9), fill=(255, 100, 0))

def draw_enemy_shooter(draw, size):
    w, h = size
    # Heavy red spaceship with cannon
    cx, cy = w/2, h/2
    draw.rectangle((w*0.2, h*0.2, w*0.8, h*0.8), fill=(100, 0, 0), outline=(255, 0, 0))
    # Cannon
    draw.rectangle((w*0.4, h*0.1, w*0.6, h*0.5), fill=(50, 0, 0))
    draw.ellipse((w*0.4, h*0.1, w*0.6, h*0.2), fill=(200, 0, 200)) # Purple glow

# ==================== WINGMEN ====================
def draw_wingman_striker(draw, size):
    w, h = size
    # Cyan drone, twin blasters
    draw.polygon([(w/2, h*0.2), (w*0.8, h*0.8), (w*0.2, h*0.8)], fill=(0, 200, 255))
    draw.rectangle((w*0.2, h*0.4, w*0.25, h*0.7), fill=(200, 255, 255))
    draw.rectangle((w*0.75, h*0.4, w*0.8, h*0.7), fill=(200, 255, 255))

def draw_wingman_heavy(draw, size):
    w, h = size
    # Yellow tank-like
    draw.rectangle((w*0.2, h*0.2, w*0.8, h*0.8), fill=(255, 200, 0))
    draw.rectangle((w*0.1, h*0.1, w*0.3, h*0.9), fill=(150, 100, 0)) # Treads
    draw.rectangle((w*0.7, h*0.1, w*0.9, h*0.9), fill=(150, 100, 0))

def draw_wingman_spread(draw, size):
    w, h = size
    # Purple wide drone
    draw.polygon([(w*0.1, h*0.5), (w*0.9, h*0.5), (w*0.5, h*0.8)], fill=(150, 0, 200))
    # Barrels
    draw.line((w*0.5, h*0.5, w*0.5, h*0.2), fill=(200, 100, 255), width=10)
    draw.line((w*0.5, h*0.5, w*0.3, h*0.2), fill=(200, 100, 255), width=10)
    draw.line((w*0.5, h*0.5, w*0.7, h*0.2), fill=(200, 100, 255), width=10)

def draw_wingman_burst(draw, size):
    w, h = size
    # Orange crystal shards
    cx, cy = w/2, h/2
    draw.polygon([(cx, h*0.1), (w*0.7, cy), (cx, h*0.9), (w*0.3, cy)], fill=(255, 150, 0))
    draw.polygon([(cx, h*0.2), (w*0.6, cy), (cx, h*0.8), (w*0.4, cy)], fill=(255, 200, 100))

def draw_wingman_laser(draw, size):
    w, h = size
    # Red with lens
    draw.ellipse((w*0.2, h*0.2, w*0.8, h*0.8), fill=(200, 0, 0))
    draw.rectangle((w*0.45, h*0.1, w*0.55, h*0.9), fill=(50, 0, 0)) # Emitter
    draw.ellipse((w*0.4, h*0.4, w*0.6, h*0.6), fill=(255, 0, 0)) # Lens core

def draw_wingman_ricochet(draw, size):
    w, h = size
    # Silver diamond
    draw.polygon([(w/2, h*0.1), (w*0.9, h*0.5), (w/2, h*0.9), (w*0.1, h*0.5)], fill=(200, 200, 200))
    draw.line((w/2, h*0.1, w/2, h*0.9), fill=(255, 255, 255), width=5)
    draw.line((w*0.1, h*0.5, w*0.9, h*0.5), fill=(255, 255, 255), width=5)

def draw_wingman_charge(draw, size):
    w, h = size
    # Cyan/Gold orb
    draw.ellipse((w*0.1, h*0.1, w*0.9, h*0.9), fill=(0, 255, 255))
    draw.ellipse((w*0.3, h*0.3, w*0.7, h*0.7), fill=(255, 255, 0))
    # Lightning
    draw.line((w*0.5, h*0.2, w*0.4, h*0.5), fill=(255, 255, 255), width=5)
    draw.line((w*0.4, h*0.5, w*0.6, h*0.6), fill=(255, 255, 255), width=5)
    draw.line((w*0.6, h*0.6, w*0.5, h*0.8), fill=(255, 255, 255), width=5)

def draw_wingman_shield(draw, size):
    w, h = size
    # Blue hex
    draw.polygon([(w*0.5, h*0.1), (w*0.9, h*0.3), (w*0.9, h*0.7), (w*0.5, h*0.9), (w*0.1, h*0.7), (w*0.1, h*0.3)], fill=(0, 100, 200))
    draw.ellipse((w*0.3, h*0.3, w*0.7, h*0.7), fill=(100, 200, 255, 100)) # Forcefield

def draw_wingman_support(draw, size):
    w, h = size
    # Gold cross
    draw.rectangle((w*0.4, h*0.1, w*0.6, h*0.9), fill=(255, 215, 0))
    draw.rectangle((w*0.1, h*0.4, w*0.9, h*0.6), fill=(255, 215, 0))
    draw.ellipse((w*0.3, h*0.3, w*0.7, h*0.7), fill=(255, 255, 200, 100)) # Aura

# ==================== BULLETS ====================
def draw_bullet_friendly(draw, size):
    w, h = size
    # Blue laser bolt
    draw.ellipse((w*0.3, h*0.1, w*0.7, h*0.9), fill=(100, 200, 255))
    draw.ellipse((w*0.4, h*0.2, w*0.6, h*0.8), fill=(255, 255, 255))

def draw_bullet_enemy(draw, size):
    w, h = size
    # Red orb
    draw.ellipse((w*0.1, h*0.1, w*0.9, h*0.9), fill=(255, 0, 0))
    draw.ellipse((w*0.3, h*0.3, w*0.7, h*0.7), fill=(255, 100, 100))

def draw_bullet_striker(draw, size):
    w, h = size
    # Cyan bolt
    draw.polygon([(w*0.5, h*0.1), (w*0.8, h*0.8), (w*0.5, h*0.7), (w*0.2, h*0.8)], fill=(0, 255, 255))

def draw_bullet_heavy(draw, size):
    w, h = size
    # Yellow shell
    draw.ellipse((w*0.2, h*0.2, w*0.8, h*0.8), fill=(255, 200, 0))
    draw.rectangle((w*0.3, h*0.3, w*0.7, h*0.7), fill=(200, 150, 0))

def draw_bullet_spread(draw, size):
    w, h = size
    # Purple pellet
    draw.ellipse((w*0.2, h*0.2, w*0.8, h*0.8), fill=(150, 0, 200))

def draw_bullet_burst(draw, size):
    w, h = size
    # Orange shard
    draw.polygon([(w*0.5, h*0.1), (w*0.9, h*0.5), (w*0.5, h*0.9), (w*0.1, h*0.5)], fill=(255, 100, 0))

def draw_bullet_ricochet(draw, size):
    w, h = size
    # Silver ball
    draw.ellipse((w*0.1, h*0.1, w*0.9, h*0.9), fill=(200, 200, 200))
    draw.ellipse((w*0.3, h*0.3, w*0.5, h*0.5), fill=(255, 255, 255)) # Shine

def draw_bullet_charge(draw, size):
    w, h = size
    # Cyan energy sphere
    draw.ellipse((w*0.1, h*0.1, w*0.9, h*0.9), fill=(0, 255, 255, 200))
    draw.ellipse((w*0.3, h*0.3, w*0.7, h*0.7), fill=(255, 255, 255))

def draw_bullet_shield(draw, size):
    w, h = size
    # Blue crescent wave
    draw.arc((w*0.1, h*0.1, w*0.9, h*0.9), 180, 360, fill=(0, 100, 255), width=20)

def main():
    base_dir = "assets/sprites"

    # Player
    create_sprite(f"{base_dir}/player_ship.png", draw_player_ship)

    # Boss
    create_sprite(f"{base_dir}/boss.png", draw_boss)

    # Enemies
    create_sprite(f"{base_dir}/enemy_basic.png", draw_enemy_basic)
    create_sprite(f"{base_dir}/enemy_dasher.png", draw_enemy_dasher)
    create_sprite(f"{base_dir}/enemy_shooter.png", draw_enemy_shooter)

    # Wingmen
    create_sprite(f"{base_dir}/wingman_striker.png", draw_wingman_striker)
    create_sprite(f"{base_dir}/wingman_heavy.png", draw_wingman_heavy)
    create_sprite(f"{base_dir}/wingman_spread.png", draw_wingman_spread)
    create_sprite(f"{base_dir}/wingman_burst.png", draw_wingman_burst)
    create_sprite(f"{base_dir}/wingman_laser.png", draw_wingman_laser)
    create_sprite(f"{base_dir}/wingman_ricochet.png", draw_wingman_ricochet)
    create_sprite(f"{base_dir}/wingman_charge.png", draw_wingman_charge)
    create_sprite(f"{base_dir}/wingman_shield.png", draw_wingman_shield)
    create_sprite(f"{base_dir}/wingman_support.png", draw_wingman_support)

    # Bullets
    create_sprite(f"{base_dir}/bullet_friendly.png", draw_bullet_friendly)
    create_sprite(f"{base_dir}/bullet_enemy.png", draw_bullet_enemy)
    create_sprite(f"{base_dir}/bullet_striker.png", draw_bullet_striker)
    create_sprite(f"{base_dir}/bullet_heavy.png", draw_bullet_heavy)
    create_sprite(f"{base_dir}/bullet_spread.png", draw_bullet_spread)
    create_sprite(f"{base_dir}/bullet_burst.png", draw_bullet_burst)
    create_sprite(f"{base_dir}/bullet_ricochet.png", draw_bullet_ricochet)
    create_sprite(f"{base_dir}/bullet_charge.png", draw_bullet_charge)
    create_sprite(f"{base_dir}/bullet_shield.png", draw_bullet_shield)

if __name__ == "__main__":
    main()
