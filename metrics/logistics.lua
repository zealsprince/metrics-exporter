-- Logistics Network Metrics Module
local logistics = {}
local inventory_helper = require("metrics.inventory_helper")

function logistics.collect(surface)
  local networks = {}

  -- Collect roboport data
  local roboports = {}
  for _, entity in pairs(surface.find_entities_filtered { type = "roboport" }) do
    local roboport_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy_usage = entity.prototype.energy_usage or 0,
      charging_station_count = entity.prototype.charging_station_count or 0,
      robot_slots_count = entity.prototype.robot_slots_count or 0,
      material_slots_count = entity.prototype.material_slots_count or 0,
      construction_radius = entity.prototype.construction_radius or 0,
      logistics_radius = entity.prototype.logistics_radius or 0
    }
    -- Robot inventory using safe helper
    local robot_inv = inventory_helper.safe_get_inventory(entity, 1) -- roboport robot inventory
    if robot_inv then
      roboport_data.robots = inventory_helper.get_inventory_contents(robot_inv)
    end

    -- Material inventory using safe helper
    local material_inv = inventory_helper.safe_get_inventory(entity, 2) -- roboport material inventory
    if material_inv then
      roboport_data.materials = inventory_helper.get_inventory_contents(material_inv)
    end

    table.insert(roboports, roboport_data)
  end

  -- Collect logistic chest data
  local logistic_chests = {}
  for _, entity in pairs(surface.find_entities_filtered { type = "logistic-container" }) do
    local chest_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      type = entity.type
    }
    -- Inventory contents
    local chest_inv = entity.get_inventory(1) -- chest inventory
    if chest_inv then
      chest_data.inventory = {}
      for i = 1, #chest_inv do
        local stack = chest_inv[i]
        if stack.valid_for_read then
          table.insert(chest_data.inventory, {
            name = stack.name,
            count = stack.count
          })
        end
      end
    end

    table.insert(logistic_chests, chest_data)
  end

  return {
    roboports = roboports,
    logistic_chests = logistic_chests
  }
end

return logistics
