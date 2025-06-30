-- Electric Network and Power Metrics Module
local electric = {}

function electric.collect_electric_network_statistics(surface)
  local electric_data = {
    has_global_network = false,
    networks = {},
    summary = {
      total_networks = 0,
      total_power_production = 0,
      total_power_consumption = 0,
      total_power_storage = 0
    }
  }

  -- Safely check for global electric network
  local success, has_network = pcall(function()
    return surface.has_global_electric_network
  end)
  if success then
    electric_data.has_global_network = has_network
  end

  -- Get global electric network statistics if available
  local success2, global_stats = pcall(function()
    return surface.global_electric_network_statistics
  end)

  if success2 and global_stats then
    electric_data.global_network = {
      input_counts = {},
      output_counts = {},
      storage_counts = {}
    }

    -- Process power statistics safely
    if global_stats.input_counts then
      for entity_name, count in pairs(global_stats.input_counts) do
        electric_data.global_network.input_counts[entity_name] = count
        electric_data.summary.total_power_consumption = electric_data.summary.total_power_consumption + count
      end
    end

    if global_stats.output_counts then
      for entity_name, count in pairs(global_stats.output_counts) do
        electric_data.global_network.output_counts[entity_name] = count
        electric_data.summary.total_power_production = electric_data.summary.total_power_production + count
      end
    end

    if global_stats.storage_counts then
      for entity_name, count in pairs(global_stats.storage_counts) do
        electric_data.global_network.storage_counts[entity_name] = count
        electric_data.summary.total_power_storage = electric_data.summary.total_power_storage + count
      end
    end
  end

  return electric_data
end

function electric.collect_power_entities(surface)
  local power_data = {
    generators = {},
    consumers = {},
    storage = {},
    distribution = {},
    summary = {
      total_generators = 0,
      total_consumers = 0,
      total_storage_entities = 0,
      total_poles = 0
    }
  }
  -- Power generators
  local generator_types = {
    "generator", "solar-panel", "accumulator", "reactor", "burner-generator"
  }

  for _, gen_type in pairs(generator_types) do
    local success, generators = pcall(function()
      return surface.find_entities_filtered { type = gen_type }
    end)

    if success and generators then
      for _, generator in pairs(generators) do
        if generator.valid then
          local gen_name = generator.name
          if not power_data.generators[gen_name] then
            power_data.generators[gen_name] = {
              count = 0,
              type = gen_type,
              total_energy_output = 0
            }
          end

          power_data.generators[gen_name].count = power_data.generators[gen_name].count + 1

          -- Try to get energy output if available (safely)
          local energy_success, energy_data = pcall(function()
            if generator.energy and generator.electric_buffer_size then
              return generator.energy
            end
            return 0
          end)

          if energy_success and energy_data then
            power_data.generators[gen_name].total_energy_output = power_data.generators[gen_name].total_energy_output +
                energy_data
          end

          power_data.summary.total_generators = power_data.summary.total_generators + 1
        end
      end
    end
  end -- Power distribution (electric poles)
  local poles_success, poles = pcall(function()
    return surface.find_entities_filtered { type = "electric-pole" }
  end)

  if poles_success and poles then
    for _, pole in pairs(poles) do
      if pole.valid then
        local pole_name = pole.name
        if not power_data.distribution[pole_name] then
          power_data.distribution[pole_name] = {
            count = 0,
            connections = 0
          }
        end
        power_data.distribution[pole_name].count = power_data.distribution[pole_name].count + 1

        -- Count connections if available (safely)
        local connection_count = 0
        local neighbours_success, neighbours = pcall(function()
          return pole.neighbours
        end)

        if neighbours_success and neighbours then
          -- Count copper wire connections
          if neighbours.copper and type(neighbours.copper) == "table" then
            connection_count = connection_count + #neighbours.copper
          end
          -- Count red wire connections
          if neighbours.red and type(neighbours.red) == "table" then
            connection_count = connection_count + #neighbours.red
          end
          -- Count green wire connections
          if neighbours.green and type(neighbours.green) == "table" then
            connection_count = connection_count + #neighbours.green
          end
        end
        power_data.distribution[pole_name].connections = power_data.distribution[pole_name].connections +
            connection_count

        power_data.summary.total_poles = power_data.summary.total_poles + 1
      end
    end
  end

  return power_data
end

return electric
