-- Mining Drill Metrics Module
local mining_drills = {}

function mining_drills.collect(surface)
  local drills = {}

  for _, entity in pairs(surface.find_entities_filtered { type = "mining-drill" }) do
    local drill_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      mining_target = entity.mining_target and entity.mining_target.name or nil,
      productivity_bonus = entity.productivity_bonus,
      speed_bonus = entity.speed_bonus,
      mining_progress = entity.mining_progress or 0,
      mining_speed = entity.prototype.mining_speed or 0
    }

    -- Add resource information in the area
    if entity.mining_target then
      drill_data.mining_target_position = {
        x = entity.mining_target.position.x,
        y = entity.mining_target.position.y
      }
      drill_data.mining_target_amount = entity.mining_target.amount
    end

    -- Mining drills typically don't have accessible output inventories
    -- Most mining drills output directly to belts or inserters
    -- Only some modded mining drills might have output inventories

    table.insert(drills, drill_data)
  end

  return drills
end

return mining_drills
