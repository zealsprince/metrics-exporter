-- Power Generation Metrics Module
local power_generation = {}

function power_generation.collect(surface)
  local generators = {}
  -- Generators (steam engines, solar panels, etc.)
  for _, entity in pairs(surface.find_entities_filtered { type = "generator" }) do
    local generator_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy_usage = entity.prototype.energy_usage or 0,
      current_energy = entity.energy or 0
    }

    table.insert(generators, generator_data)
  end

  -- Boilers
  for _, entity in pairs(surface.find_entities_filtered { type = "boiler" }) do
    local boiler_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy_usage = entity.prototype.energy_usage,
      target_temperature = entity.prototype.target_temperature,
      current_temperature = entity.temperature or 0
    }

    table.insert(generators, boiler_data)
  end -- Solar panels
  for _, entity in pairs(surface.find_entities_filtered { type = "solar-panel" }) do
    local solar_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy_usage = entity.prototype.energy_usage or 0,
      current_energy = entity.energy or 0
    }
    table.insert(generators, solar_data)
  end

  -- Accumulators
  for _, entity in pairs(surface.find_entities_filtered { type = "accumulator" }) do
    local accumulator_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy = entity.energy or 0
    }

    -- Calculate charge ratio safely
    if entity.prototype.energy_capacity and entity.prototype.energy_capacity > 0 then
      accumulator_data.charge_ratio = entity.energy / entity.prototype.energy_capacity
      accumulator_data.energy_capacity = entity.prototype.energy_capacity
    else
      accumulator_data.charge_ratio = 0
      accumulator_data.energy_capacity = 0
    end

    table.insert(generators, accumulator_data)
  end

  return generators
end

return power_generation
