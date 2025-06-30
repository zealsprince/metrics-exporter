-- Circuit Network Metrics Module
local circuits = {}

function circuits.collect(surface)
  local circuit_data = {
    constant_combinators = {},
    arithmetic_combinators = {},
    decider_combinators = {},
    power_switches = {},
    programmable_speakers = {}
  }

  -- Constant combinators
  for _, entity in pairs(surface.find_entities_filtered { name = "constant-combinator" }) do
    local combinator_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      enabled = entity.enabled,
      signals = {}
    }
    -- Get circuit network signals (simplified to avoid API issues)
    if entity.get_control_behavior() then
      local behavior = entity.get_control_behavior()
      -- Safe access to signals - only get basic info
      combinator_data.has_signals = true
    else
      combinator_data.has_signals = false
    end

    table.insert(circuit_data.constant_combinators, combinator_data)
  end

  -- Arithmetic combinators
  for _, entity in pairs(surface.find_entities_filtered { name = "arithmetic-combinator" }) do
    local combinator_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      enabled = entity.enabled
    }
    if entity.get_control_behavior() then
      local behavior = entity.get_control_behavior()
      combinator_data.has_conditions = true
    else
      combinator_data.has_conditions = false
    end

    table.insert(circuit_data.arithmetic_combinators, combinator_data)
  end

  -- Decider combinators
  for _, entity in pairs(surface.find_entities_filtered { name = "decider-combinator" }) do
    local combinator_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      enabled = entity.enabled
    }
    if entity.get_control_behavior() then
      local behavior = entity.get_control_behavior()
      combinator_data.has_conditions = true
    else
      combinator_data.has_conditions = false
    end

    table.insert(circuit_data.decider_combinators, combinator_data)
  end

  return circuit_data
end

return circuits
