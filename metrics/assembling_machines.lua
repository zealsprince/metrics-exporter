-- Assembling Machine Metrics Module
local assembling_machines = {}
local inventory_helper = require("metrics.inventory_helper")

function assembling_machines.collect(surface)
  local machines = {}

  for _, entity in pairs(surface.find_entities_filtered { type = "assembling-machine" }) do
    local machine_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      recipe = entity.get_recipe() and entity.get_recipe().name or nil,
      status = tostring(entity.status),
      productivity_bonus = entity.productivity_bonus,
      speed_bonus = entity.speed_bonus,
      energy_usage = entity.prototype.energy_usage or 0,
      crafting_progress = entity.crafting_progress or 0,
      bonus_progress = entity.bonus_progress or 0
    }

    local input_inv = inventory_helper.safe_get_inventory(entity, defines.inventory.assembling_machine_input)
    if input_inv then
      machine_data.input_inventory = inventory_helper.get_inventory_contents(input_inv)
    end

    local output_inv = inventory_helper.safe_get_inventory(entity, defines.inventory.assembling_machine_output)
    if output_inv then
      machine_data.output_inventory = inventory_helper.get_inventory_contents(output_inv)
    end

    table.insert(machines, machine_data)
  end

  return machines
end

return assembling_machines
