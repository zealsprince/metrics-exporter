-- Configuration
local EXPORT_INTERVAL_TICKS = 60 * 60 -- 1 minute in ticks (60 ticks/second * 60 seconds)
local EXPORT_TO_FILE = true           -- Set to true to write to script-output folder for easy S3 upload

local function get_comprehensive_factory_state()
  local state = {
    timestamp = game.tick,
    game_time = math.floor(game.tick / 60), -- Game time in seconds
    surfaces = {}
  }

  for _, surface in pairs(game.surfaces) do
    local surface_data = {
      name = surface.name,
      entities = {
        assembling_machines = {},
        mining_drills = {},
        inserters = {},
        transport_belts = {},
        electric_poles = {},
        boilers = {},
        generators = {},
        labs = {}
      },
      statistics = {
        pollution = surface.get_total_pollution(),
        entity_count = surface.count_entities_filtered {}
      }
    }

    -- Assembling machines
    for _, entity in pairs(surface.find_entities_filtered { type = "assembling-machine" }) do
      table.insert(surface_data.entities.assembling_machines, {
        name = entity.name,
        position = { x = entity.position.x, y = entity.position.y },
        recipe = entity.get_recipe() and entity.get_recipe().name or nil,
        status = tostring(entity.status),
        productivity_bonus = entity.productivity_bonus,
        speed_bonus = entity.speed_bonus,
        energy_usage = entity.prototype.energy_usage
      })
    end

    -- Mining drills
    for _, entity in pairs(surface.find_entities_filtered { type = "mining-drill" }) do
      table.insert(surface_data.entities.mining_drills, {
        name = entity.name,
        position = { x = entity.position.x, y = entity.position.y },
        status = tostring(entity.status),
        mining_target = entity.mining_target and entity.mining_target.name or nil,
        productivity_bonus = entity.productivity_bonus,
        speed_bonus = entity.speed_bonus
      })
    end

    -- Power generation
    for _, entity in pairs(surface.find_entities_filtered { type = "generator" }) do
      table.insert(surface_data.entities.generators, {
        name = entity.name,
        position = { x = entity.position.x, y = entity.position.y },
        status = tostring(entity.status)
      })
    end

    -- Labs for research progress
    for _, entity in pairs(surface.find_entities_filtered { type = "lab" }) do
      table.insert(surface_data.entities.labs, {
        name = entity.name,
        position = { x = entity.position.x, y = entity.position.y },
        status = tostring(entity.status)
      })
    end

    state.surfaces[surface.name] = surface_data
  end

  -- Add global statistics
  state.statistics = {
    total_entities = 0,
    forces = {}
  }
  for _, force in pairs(game.forces) do
    if force.name ~= "neutral" then
      local force_data = {
        name = force.name,
        technologies_researched = 0,
        manual_mining_speed_modifier = force.manual_mining_speed_modifier,
        manual_crafting_speed_modifier = force.manual_crafting_speed_modifier,
        rockets_launched = force.rockets_launched,
        research_enabled = force.research_enabled
      }

      -- Count researched technologies
      for _, tech in pairs(force.technologies) do
        if tech.researched then
          force_data.technologies_researched = force_data.technologies_researched + 1
        end
      end

      -- Current research
      if force.current_research then
        force_data.current_research = {
          name = force.current_research.name,
          progress = force.research_progress
        }
      end
      state.statistics.forces[force.name] = force_data
    end
  end
  -- Add evolution factor for enemy forces (if they exist)
  -- Note: Skipping evolution factor for now due to API issues
  state.statistics.evolution_factor = 0

  return state
end

local function export_state(command)
  -- Check if command was called by a player and if they are admin
  if command and command.player_index then
    local player = game.get_player(command.player_index)
    if not player.admin then
      player.print("[METRIC_EXPORTER] Error: Only admins can use this command.")
      return
    end
  end

  local state = get_comprehensive_factory_state()
  local timestamp = game.tick
  local iso_time = string.format("%04d-%02d-%02d_%02d-%02d-%02d",
    2000 + math.floor(timestamp / (60 * 60 * 24 * 365)),    -- Rough year
    math.floor((timestamp / (60 * 60 * 24 * 30)) % 12) + 1, -- Rough month
    math.floor((timestamp / (60 * 60 * 24)) % 30) + 1,      -- Rough day
    math.floor((timestamp / (60 * 60)) % 24),               -- Hour
    math.floor((timestamp / 60) % 60),                      -- Minute
    math.floor(timestamp % 60)                              -- Second
  )

  -- Optionally write to organized files
  if EXPORT_TO_FILE then
    local base_folder = "metrics-exporter/"

    -- Create metadata file with overall summary
    local metadata = {
      export_timestamp = timestamp,
      game_time_seconds = state.game_time,
      surfaces_count = 0,
      total_entities = {
        assembling_machines = 0,
        mining_drills = 0,
        generators = 0,
        labs = 0
      },
      forces = {}
    }

    -- Export surface data separately
    for surface_name, surface_data in pairs(state.surfaces) do
      metadata.surfaces_count = metadata.surfaces_count + 1

      -- Surface overview
      local surface_summary = {
        name = surface_name,
        timestamp = timestamp,
        statistics = surface_data.statistics,
        entity_counts = {
          assembling_machines = #surface_data.entities.assembling_machines,
          mining_drills = #surface_data.entities.mining_drills,
          generators = #surface_data.entities.generators,
          labs = #surface_data.entities.labs
        }
      }

      metadata.total_entities.assembling_machines = metadata.total_entities.assembling_machines +
          surface_summary.entity_counts.assembling_machines
      metadata.total_entities.mining_drills = metadata.total_entities.mining_drills +
          surface_summary.entity_counts.mining_drills
      metadata.total_entities.generators = metadata.total_entities.generators + surface_summary.entity_counts.generators
      metadata.total_entities.labs = metadata.total_entities.labs + surface_summary.entity_counts.labs
      helpers.write_file(base_folder .. "surfaces/surface_" .. surface_name .. "_" .. timestamp .. ".json",
        helpers.table_to_json(surface_summary))
      -- Individual entity type files - export entities array directly as root
      if #surface_data.entities.assembling_machines > 0 then
        helpers.write_file(
          base_folder .. "assembling-machines/assembling_machines_" .. surface_name .. "_" .. timestamp .. ".json",
          helpers.table_to_json(surface_data.entities.assembling_machines))
      end

      if #surface_data.entities.mining_drills > 0 then
        helpers.write_file(base_folder .. "mining-drills/mining_drills_" .. surface_name .. "_" .. timestamp .. ".json",
          helpers.table_to_json(surface_data.entities.mining_drills))
      end

      if #surface_data.entities.generators > 0 then
        helpers.write_file(base_folder .. "generators/generators_" .. surface_name .. "_" .. timestamp .. ".json",
          helpers.table_to_json(surface_data.entities.generators))
      end

      if #surface_data.entities.labs > 0 then
        helpers.write_file(base_folder .. "labs/labs_" .. surface_name .. "_" .. timestamp .. ".json",
          helpers.table_to_json(surface_data.entities.labs))
      end
    end

    -- Export force/research data
    metadata.forces = state.statistics.forces
    local research_export = {
      timestamp = timestamp,
      evolution_factor = state.statistics.evolution_factor,
      forces = state.statistics.forces
    }
    helpers.write_file(base_folder .. "research/research_" .. timestamp .. ".json",
      helpers.table_to_json(research_export))

    -- Export metadata/summary
    helpers.write_file(base_folder .. "metadata/metadata_" .. timestamp .. ".json",
      helpers.table_to_json(metadata))
  end
end

-- Function to register the periodic export handler
local function register_export_handler()
  script.on_nth_tick(EXPORT_INTERVAL_TICKS, function(event)
    export_state(nil)
  end)
end

-- Register event handlers on init (new game)
script.on_init(function()
  register_export_handler()
end)

-- Register event handlers on load (existing game)
script.on_load(function()
  -- Only re-setup event handlers - no game access allowed here!
  register_export_handler()
end)

-- Add the command correctly, per the API
commands.add_command(
  "metrics-exporter",                            -- command name (no slash)
  "Export comprehensive factory state as JSON.", -- help text
  export_state                                   -- function to call
)
