CTRL_FORWARD = 1
CTRL_BACK = 2
CTRL_LEFT = 4
CTRL_RIGHT = 8

CAMERA_DISTANCE = 10.0
YAW_SENSITIVITY = 0.1
ENGINE_POWER = 40.0
DOWN_FORCE = 50.0
MAX_WHEEL_ANGLE = 22.5

AMMO_COUNT_FOR_POWERUP = 5

GAME_STATE = "START_MENU"

TAG_POWERUP = "PowerUp"
TAG_WEAPON = "Weapon"

EVENT_BULLET_FIRED = "EVENT_BULLET_FIRED"
EVENT_POWERUP_COLLECTED = "EVENT_POWERUP_COLLECTED"
EVENT_MUSHROOM_COLLECTED = "EVENT_MUSHROOM_COLLECTED"

collectedPowerupsCount = 5

function ChangeState(state)
    GAME_STATE = state
end
