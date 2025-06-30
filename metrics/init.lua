-- Main Metrics Coordinator Module
local metrics = {}

-- Import all metric modules
local assembling_machines = require("metrics.assembling_machines")
local mining_drills = require("metrics.mining_drills")
local power_generation = require("metrics.power_generation")
local research = require("metrics.research")
local furnaces = require("metrics.furnaces")
local players = require("metrics.players")
local logistics = require("metrics.logistics")
local transport = require("metrics.transport")
local resources = require("metrics.resources")
local circuits = require("metrics.circuits")
local production = require("metrics.production")
local enemies = require("metrics.enemies")
local rockets = require("metrics.rockets")
local electric = require("metrics.electric")
local logging = require("metrics.logging")

function metrics.collect_all()
  local state = {
    timestamp = game.tick,
    game_time = math.floor(game.tick / 60), -- Game time in seconds
    surfaces = {},
    global_statistics = {}
  }
  -- Collect surface-specific metrics
  for _, surface in pairs(game.surfaces) do
    local surface_data = {
      name = surface.name,
      entities = {
        assembling_machines = assembling_machines.collect(surface),
        mining_drills = mining_drills.collect(surface),
        power_generation = power_generation.collect(surface),
        labs = research.collect(surface),
        furnaces = furnaces.collect(surface),
        logistics = logistics.collect(surface),
        transport = transport.collect(surface),
        circuits = circuits.collect(surface)
      },
      statistics = {
        pollution = surface.get_total_pollution(),
        entity_count = surface.count_entities_filtered {},
        resources = resources.collect_surface_resources(surface)
      }
    }

    -- NEW: Enhanced metrics with error handling
    local enemies_data = {}
    local military_data = {}
    local electric_networks_data = {}
    local power_infrastructure_data = {}

    -- Safely collect enemy data
    local success1, result1 = pcall(function()
      return enemies.collect_enemy_entities(surface)
    end)
    if success1 then
      enemies_data = result1
    else
      log("Error collecting enemy entities: " .. tostring(result1))
      enemies_data = { error = "Failed to collect enemy data" }
    end

    -- Safely collect military data
    local success2, result2 = pcall(function()
      return enemies.collect_player_military_assets(surface)
    end)
    if success2 then
      military_data = result2
    else
      log("Error collecting military assets: " .. tostring(result2))
      military_data = { error = "Failed to collect military data" }
    end

    -- Safely collect electric networks data
    local success3, result3 = pcall(function()
      return electric.collect_electric_network_statistics(surface)
    end)
    if success3 then
      electric_networks_data = result3
    else
      log("Error collecting electric networks: " .. tostring(result3))
      electric_networks_data = { error = "Failed to collect electric networks data" }
    end

    -- Safely collect power infrastructure data
    local success4, result4 = pcall(function()
      return electric.collect_power_entities(surface)
    end)
    if success4 then
      power_infrastructure_data = result4
    else
      log("Error collecting power infrastructure: " .. tostring(result4))
      power_infrastructure_data = { error = "Failed to collect power infrastructure data" }
    end

    surface_data.enemies = enemies_data
    surface_data.military = military_data
    surface_data.electric_networks = electric_networks_data
    surface_data.power_infrastructure = power_infrastructure_data

    state.surfaces[surface.name] = surface_data
  end

  -- Collect global metrics
  state.global_statistics = {
    players = players.collect(),
    total_entities = 0,
    forces = {}
  } -- Collect force-specific data
  for _, force in pairs(game.forces) do
    if force.name ~= "neutral" then
      local force_data = research.collect_force_data(force)

      -- NEW: Enhanced production and combat statistics with error handling
      local production_success1, item_production = pcall(function()
        return production.collect_item_statistics(force)
      end)
      if production_success1 then
        force_data.item_production = item_production
      else
        force_data.item_production = { error = "Failed to collect item production statistics" }
      end

      local production_success2, fluid_production = pcall(function()
        return production.collect_fluid_statistics(force)
      end)
      if production_success2 then
        force_data.fluid_production = fluid_production
      else
        force_data.fluid_production = { error = "Failed to collect fluid production statistics" }
      end

      local production_success3, kill_statistics = pcall(function()
        return production.collect_kill_statistics(force)
      end)
      if production_success3 then
        force_data.kill_statistics = kill_statistics
      else
        force_data.kill_statistics = { error = "Failed to collect kill statistics" }
      end

      local production_success4, build_statistics = pcall(function()
        return production.collect_build_statistics(force)
      end)
      if production_success4 then
        force_data.build_statistics = build_statistics
      else
        force_data.build_statistics = { error = "Failed to collect build statistics" }
      end

      local rockets_success1, rocket_statistics = pcall(function()
        return rockets.collect_rocket_statistics(force)
      end)
      if rockets_success1 then
        force_data.rocket_statistics = rocket_statistics
      else
        force_data.rocket_statistics = { error = "Failed to collect rocket statistics" }
      end

      local rockets_success2, technology_statistics = pcall(function()
        return rockets.collect_technology_statistics(force)
      end)
      if rockets_success2 then
        force_data.technology_statistics = technology_statistics
      else
        force_data.technology_statistics = { error = "Failed to collect technology statistics" }
      end

      state.global_statistics.forces[force.name] = force_data
    end
  end

  -- Evolution factor removed - not accessible via force.evolution_factor
  state.global_statistics.evolution_factor = 0 -- Placeholder for compatibility

  return state
end

-- Export organized data for file output
function metrics.export_organized_data(state, base_folder, padded_timestamp)
  local exports = {}

  -- Metadata
  local metadata = {
    export_timestamp = state.timestamp,
    game_time_seconds = state.game_time,
    world_identifier = game.get_map_exchange_string(),
    surfaces_count = 0,
    total_entities = {
      assembling_machines = 0,
      mining_drills = 0,
      power_generation = 0,
      labs = 0,
      furnaces = 0,
      logistics_roboports = 0,
      logistics_chests = 0,
      inserters = 0,
      trains = 0,
      stations = 0,
      circuits = 0
    },
    forces = state.global_statistics.forces
  }

  -- Export surface data
  for surface_name, surface_data in pairs(state.surfaces) do
    metadata.surfaces_count = metadata.surfaces_count + 1

    -- Individual entity exports
    local entity_exports = {
      assembling_machines = surface_data.entities.assembling_machines,
      mining_drills = surface_data.entities.mining_drills,
      power_generation = surface_data.entities.power_generation,
      labs = surface_data.entities.labs,
      furnaces = surface_data.entities.furnaces,
      logistics = surface_data.entities.logistics,
      transport = surface_data.entities.transport,
      circuits = surface_data.entities.circuits
    } -- Update totals
    metadata.total_entities.assembling_machines = metadata.total_entities.assembling_machines +
        #entity_exports.assembling_machines
    metadata.total_entities.mining_drills = metadata.total_entities.mining_drills + #entity_exports.mining_drills
    metadata.total_entities.power_generation = metadata.total_entities.power_generation +
        #entity_exports.power_generation
    metadata.total_entities.labs = metadata.total_entities.labs + #entity_exports.labs
    metadata.total_entities.furnaces = metadata.total_entities.furnaces + #entity_exports.furnaces
    metadata.total_entities.logistics_roboports = metadata.total_entities.logistics_roboports +
        #entity_exports.logistics.roboports
    metadata.total_entities.logistics_chests = metadata.total_entities.logistics_chests +
        #entity_exports.logistics.logistic_chests
    metadata.total_entities.inserters = metadata.total_entities.inserters + #entity_exports.transport.inserters
    metadata.total_entities.trains = metadata.total_entities.trains + #entity_exports.transport.trains
    metadata.total_entities.stations = metadata.total_entities.stations + #entity_exports.transport.stations
    metadata.total_entities.circuits = metadata.total_entities.circuits +
        (#entity_exports.circuits.constant_combinators + #entity_exports.circuits.arithmetic_combinators + #entity_exports.circuits.decider_combinators) -- Export enhanced metrics for this surface
    -- Resources export (flatten structure)
    if surface_data.statistics.resources then
      table.insert(exports, {
        file = base_folder .. "resources/resources_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = surface_data.statistics.resources
      })
    end

    -- Enemies exports - split into separate categories for better data pipeline structure
    if surface_data.enemies then
      -- Enemy spawners
      if surface_data.enemies.spawners then
        table.insert(exports, {
          file = base_folder .. "enemy-spawners/spawners_" .. surface_name .. "_" .. padded_timestamp .. ".json",
          data = {
            spawners = surface_data.enemies.spawners,
            summary = {
              total_spawners = surface_data.enemies.summary.total_spawners,
              evolution_factor = surface_data.enemies.summary.evolution_factor
            }
          }
        })
      end

      -- Enemy units
      if surface_data.enemies.units then
        table.insert(exports, {
          file = base_folder .. "enemy-units/units_" .. surface_name .. "_" .. padded_timestamp .. ".json",
          data = {
            units = surface_data.enemies.units,
            summary = {
              total_units = surface_data.enemies.summary.total_units
            }
          }
        })
      end

      -- Enemy worms
      if surface_data.enemies.worms then
        table.insert(exports, {
          file = base_folder .. "enemy-worms/worms_" .. surface_name .. "_" .. padded_timestamp .. ".json",
          data = {
            worms = surface_data.enemies.worms,
            summary = {
              total_worms = surface_data.enemies.summary.total_worms
            }
          }
        })
      end

      -- Enemy nests (if present)
      if surface_data.enemies.nests then
        table.insert(exports, {
          file = base_folder .. "enemy-nests/nests_" .. surface_name .. "_" .. padded_timestamp .. ".json",
          data = {
            nests = surface_data.enemies.nests,
            summary = {
              total_nests = surface_data.enemies.summary.total_nests
            }
          }
        })
      end
    end

    -- Military assets export (flatten structure)
    if surface_data.military then
      table.insert(exports, {
        file = base_folder .. "military-assets/military_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = surface_data.military
      })
    end

    -- Electric networks export (separate from power entities)
    if surface_data.electric_networks then
      table.insert(exports, {
        file = base_folder .. "electric-networks/networks_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = surface_data.electric_networks
      })
    end

    -- Power entities export (separate folder)
    if surface_data.power_infrastructure then
      table.insert(exports, {
        file = base_folder .. "power-entities/entities_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = surface_data.power_infrastructure
      })
    end -- Surface summary (flattened structure - surface name is in filename)
    local surface_summary = {
      timestamp = state.timestamp,
      statistics = surface_data.statistics,
      entity_counts = {
        assembling_machines = #entity_exports.assembling_machines,
        mining_drills = #entity_exports.mining_drills,
        power_generation = #entity_exports.power_generation,
        labs = #entity_exports.labs,
        furnaces = #entity_exports.furnaces,
        logistics_roboports = #entity_exports.logistics.roboports,
        logistics_chests = #entity_exports.logistics.logistic_chests,
        inserters = #entity_exports.transport.inserters,
        trains = #entity_exports.transport.trains,
        stations = #entity_exports.transport.stations,
        circuits = metadata.total_entities.circuits
      },
      -- Enhanced metrics summaries (flattened)
      enemies_summary = surface_data.enemies and surface_data.enemies.summary or nil,
      military_summary = surface_data.military and surface_data.military.summary or nil,
      electric_networks_summary = surface_data.electric_networks and surface_data.electric_networks.summary or nil,
      power_infrastructure_summary = surface_data.power_infrastructure and surface_data.power_infrastructure.summary or
          nil
    }

    table.insert(exports, {
      file = base_folder .. "surfaces/surface_" .. surface_name .. "_" .. padded_timestamp .. ".json",
      data = surface_summary
    })

    -- Individual entity type exports
    if #entity_exports.assembling_machines > 0 then
      table.insert(exports, {
        file = base_folder ..
            "assembling-machines/assembling_machines_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.assembling_machines
      })
    end

    if #entity_exports.mining_drills > 0 then
      table.insert(exports, {
        file = base_folder .. "mining-drills/mining_drills_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.mining_drills
      })
    end

    if #entity_exports.power_generation > 0 then
      table.insert(exports, {
        file = base_folder .. "power-generation/power_generation_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.power_generation
      })
    end

    if #entity_exports.labs > 0 then
      table.insert(exports, {
        file = base_folder .. "labs/labs_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.labs
      })
    end

    if #entity_exports.furnaces > 0 then
      table.insert(exports, {
        file = base_folder .. "furnaces/furnaces_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.furnaces
      })
    end

    if #entity_exports.logistics.roboports > 0 then
      table.insert(exports, {
        file = base_folder .. "logistics/roboports_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.logistics.roboports
      })
    end

    if #entity_exports.logistics.logistic_chests > 0 then
      table.insert(exports, {
        file = base_folder .. "logistics/logistic_chests_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.logistics.logistic_chests
      })
    end
    if #entity_exports.transport.inserters > 0 then
      table.insert(exports, {
        file = base_folder .. "transport/inserters_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.transport.inserters
      })
    end

    if #entity_exports.transport.trains > 0 then
      table.insert(exports, {
        file = base_folder .. "transport/trains_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.transport.trains
      })
    end

    if #entity_exports.transport.stations > 0 then
      table.insert(exports, {
        file = base_folder .. "transport/stations_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.transport.stations
      })
    end

    -- Circuit exports
    if #entity_exports.circuits.constant_combinators > 0 then
      table.insert(exports, {
        file = base_folder .. "circuits/constant_combinators_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.circuits.constant_combinators
      })
    end

    if #entity_exports.circuits.arithmetic_combinators > 0 then
      table.insert(exports, {
        file = base_folder .. "circuits/arithmetic_combinators_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.circuits.arithmetic_combinators
      })
    end

    if #entity_exports.circuits.decider_combinators > 0 then
      table.insert(exports, {
        file = base_folder .. "circuits/decider_combinators_" .. surface_name .. "_" .. padded_timestamp .. ".json",
        data = entity_exports.circuits.decider_combinators
      })
    end
  end
  -- Export global data
  table.insert(exports, {
    file = base_folder .. "players/players_" .. padded_timestamp .. ".json",
    data = state.global_statistics.players
  })

  -- Export production statistics for each force
  for force_name, force_data in pairs(state.global_statistics.forces) do
    if force_data.item_production then
      table.insert(exports, {
        file = base_folder .. "production/item_production_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.item_production
      })
    end

    if force_data.fluid_production then
      table.insert(exports, {
        file = base_folder .. "production/fluid_production_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.fluid_production
      })
    end

    if force_data.kill_statistics then
      table.insert(exports, {
        file = base_folder .. "combat/kill_statistics_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.kill_statistics
      })
    end

    if force_data.build_statistics then
      table.insert(exports, {
        file = base_folder .. "construction/build_statistics_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.build_statistics
      })
    end

    if force_data.rocket_statistics then
      table.insert(exports, {
        file = base_folder .. "rockets/rocket_statistics_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.rocket_statistics
      })
    end

    if force_data.technology_statistics then
      table.insert(exports, {
        file = base_folder .. "research/technology_progress_" .. force_name .. "_" .. padded_timestamp .. ".json",
        data = force_data.technology_statistics
      })
    end
  end

  local research_export = {
    timestamp = state.timestamp,
    evolution_factor = state.global_statistics.evolution_factor,
    forces = state.global_statistics.forces
  }
  table.insert(exports, {
    file = base_folder .. "research/research_" .. padded_timestamp .. ".json",
    data = research_export
  })

  -- Export metadata
  table.insert(exports, {
    file = base_folder .. "metadata/metadata_" .. padded_timestamp .. ".json",
    data = metadata
  })

  return exports
end

return metrics
