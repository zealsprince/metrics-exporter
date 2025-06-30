-- Furnace Metrics Module
local furnaces = {}
local inventory_helper = require("metrics.inventory_helper")

function furnaces.collect(surface)
  local furnace_list = {}

  for _, entity in pairs(surface.find_entities_filtered { type = "furnace" }) do
    local furnace_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      recipe = entity.get_recipe() and entity.get_recipe().name or nil,
      productivity_bonus = entity.productivity_bonus,
      speed_bonus = entity.speed_bonus,
      energy_usage = entity.prototype.energy_usage or 0,
      crafting_progress = entity.crafting_progress or 0,
      smelting_categories = {}
    } -- Add smelting categories
    for category, _ in pairs(entity.prototype.crafting_categories) do
      table.insert(furnace_data.smelting_categories, category)
    end

    local input_inv = inventory_helper.safe_get_inventory(entity, defines.inventory.furnace_source)
    if input_inv then
      furnace_data.input_inventory = inventory_helper.get_inventory_contents(input_inv)
    end

    local output_inv = inventory_helper.safe_get_inventory(entity, defines.inventory.furnace_result)
    if output_inv then
      furnace_data.output_inventory = inventory_helper.get_inventory_contents(output_inv)
    end

    -- Fuel inventory for non-electric furnaces
    local fuel_inv = inventory_helper.safe_get_inventory(entity, defines.inventory.fuel)
    if fuel_inv then
      furnace_data.fuel_inventory = inventory_helper.get_inventory_contents(fuel_inv)
    end

    table.insert(furnace_list, furnace_data)
  end

  return furnace_list
end

return furnaces
