-- Production and Consumption Statistics Module
local production = {}

function production.collect_item_statistics(force)
  local stats = {
    items = {},
    summary = {
      total_input_items = 0,
      total_output_items = 0,
      unique_items_produced = 0,
      unique_items_consumed = 0
    }
  }

  -- Collect for each surface separately
  for _, surface in pairs(game.surfaces) do
    local item_stats = force.get_item_production_statistics(surface)

    if item_stats and item_stats.valid then
      -- Process input counts (consumption)
      for item_name, count in pairs(item_stats.input_counts) do
        if not stats.items[item_name] then
          stats.items[item_name] = {
            total_produced = 0,
            total_consumed = 0,
            surfaces = {}
          }
        end

        stats.items[item_name].total_consumed = stats.items[item_name].total_consumed + count
        stats.items[item_name].surfaces[surface.name] = stats.items[item_name].surfaces[surface.name] or {}
        stats.items[item_name].surfaces[surface.name].consumed = count

        stats.summary.total_input_items = stats.summary.total_input_items + count
      end

      -- Process output counts (production)
      for item_name, count in pairs(item_stats.output_counts) do
        if not stats.items[item_name] then
          stats.items[item_name] = {
            total_produced = 0,
            total_consumed = 0,
            surfaces = {}
          }
        end

        stats.items[item_name].total_produced = stats.items[item_name].total_produced + count
        stats.items[item_name].surfaces[surface.name] = stats.items[item_name].surfaces[surface.name] or {}
        stats.items[item_name].surfaces[surface.name].produced = count

        stats.summary.total_output_items = stats.summary.total_output_items + count
      end
    end
  end

  -- Calculate summary statistics
  for item_name, data in pairs(stats.items) do
    if data.total_produced > 0 then
      stats.summary.unique_items_produced = stats.summary.unique_items_produced + 1
    end
    if data.total_consumed > 0 then
      stats.summary.unique_items_consumed = stats.summary.unique_items_consumed + 1
    end
  end

  return stats
end

function production.collect_fluid_statistics(force)
  local stats = {
    fluids = {},
    summary = {
      total_input_fluids = 0,
      total_output_fluids = 0,
      unique_fluids_produced = 0,
      unique_fluids_consumed = 0
    }
  }

  -- Collect for each surface separately
  for _, surface in pairs(game.surfaces) do
    local fluid_stats = force.get_fluid_production_statistics(surface)

    if fluid_stats and fluid_stats.valid then
      -- Process input counts (consumption)
      for fluid_name, count in pairs(fluid_stats.input_counts) do
        if not stats.fluids[fluid_name] then
          stats.fluids[fluid_name] = {
            total_produced = 0,
            total_consumed = 0,
            surfaces = {}
          }
        end

        stats.fluids[fluid_name].total_consumed = stats.fluids[fluid_name].total_consumed + count
        stats.fluids[fluid_name].surfaces[surface.name] = stats.fluids[fluid_name].surfaces[surface.name] or {}
        stats.fluids[fluid_name].surfaces[surface.name].consumed = count

        stats.summary.total_input_fluids = stats.summary.total_input_fluids + count
      end

      -- Process output counts (production)
      for fluid_name, count in pairs(fluid_stats.output_counts) do
        if not stats.fluids[fluid_name] then
          stats.fluids[fluid_name] = {
            total_produced = 0,
            total_consumed = 0,
            surfaces = {}
          }
        end

        stats.fluids[fluid_name].total_produced = stats.fluids[fluid_name].total_produced + count
        stats.fluids[fluid_name].surfaces[surface.name] = stats.fluids[fluid_name].surfaces[surface.name] or {}
        stats.fluids[fluid_name].surfaces[surface.name].produced = count

        stats.summary.total_output_fluids = stats.summary.total_output_fluids + count
      end
    end
  end

  -- Calculate summary statistics
  for fluid_name, data in pairs(stats.fluids) do
    if data.total_produced > 0 then
      stats.summary.unique_fluids_produced = stats.summary.unique_fluids_produced + 1
    end
    if data.total_consumed > 0 then
      stats.summary.unique_fluids_consumed = stats.summary.unique_fluids_consumed + 1
    end
  end

  return stats
end

function production.collect_kill_statistics(force)
  local stats = {
    kills = {},
    summary = {
      total_kills = 0,
      total_losses = 0,
      kill_types = 0,
      loss_types = 0
    }
  }

  -- Collect for each surface separately
  for _, surface in pairs(game.surfaces) do
    local kill_stats = force.get_kill_count_statistics(surface)

    if kill_stats and kill_stats.valid then
      -- Process kills (output = what this force killed)
      for entity_name, count in pairs(kill_stats.output_counts) do
        if not stats.kills[entity_name] then
          stats.kills[entity_name] = {
            killed = 0,
            lost = 0,
            surfaces = {}
          }
        end

        stats.kills[entity_name].killed = stats.kills[entity_name].killed + count
        stats.kills[entity_name].surfaces[surface.name] = stats.kills[entity_name].surfaces[surface.name] or {}
        stats.kills[entity_name].surfaces[surface.name].killed = count

        stats.summary.total_kills = stats.summary.total_kills + count
      end

      -- Process losses (input = what killed this force's entities)
      for entity_name, count in pairs(kill_stats.input_counts) do
        if not stats.kills[entity_name] then
          stats.kills[entity_name] = {
            killed = 0,
            lost = 0,
            surfaces = {}
          }
        end

        stats.kills[entity_name].lost = stats.kills[entity_name].lost + count
        stats.kills[entity_name].surfaces[surface.name] = stats.kills[entity_name].surfaces[surface.name] or {}
        stats.kills[entity_name].surfaces[surface.name].lost = count

        stats.summary.total_losses = stats.summary.total_losses + count
      end
    end
  end

  -- Calculate summary statistics
  for entity_name, data in pairs(stats.kills) do
    if data.killed > 0 then
      stats.summary.kill_types = stats.summary.kill_types + 1
    end
    if data.lost > 0 then
      stats.summary.loss_types = stats.summary.loss_types + 1
    end
  end

  return stats
end

function production.collect_build_statistics(force)
  local stats = {
    entities = {},
    summary = {
      total_built = 0,
      total_mined = 0,
      build_types = 0,
      mine_types = 0
    }
  }

  -- Collect for each surface separately
  for _, surface in pairs(game.surfaces) do
    local build_stats = force.get_entity_build_count_statistics(surface)

    if build_stats and build_stats.valid then
      -- Process builds (output = entities built)
      for entity_name, count in pairs(build_stats.output_counts) do
        if not stats.entities[entity_name] then
          stats.entities[entity_name] = {
            built = 0,
            mined = 0,
            surfaces = {}
          }
        end

        stats.entities[entity_name].built = stats.entities[entity_name].built + count
        stats.entities[entity_name].surfaces[surface.name] = stats.entities[entity_name].surfaces[surface.name] or {}
        stats.entities[entity_name].surfaces[surface.name].built = count

        stats.summary.total_built = stats.summary.total_built + count
      end

      -- Process mining (input = entities mined)
      for entity_name, count in pairs(build_stats.input_counts) do
        if not stats.entities[entity_name] then
          stats.entities[entity_name] = {
            built = 0,
            mined = 0,
            surfaces = {}
          }
        end

        stats.entities[entity_name].mined = stats.entities[entity_name].mined + count
        stats.entities[entity_name].surfaces[surface.name] = stats.entities[entity_name].surfaces[surface.name] or {}
        stats.entities[entity_name].surfaces[surface.name].mined = count

        stats.summary.total_mined = stats.summary.total_mined + count
      end
    end
  end

  -- Calculate summary statistics
  for entity_name, data in pairs(stats.entities) do
    if data.built > 0 then
      stats.summary.build_types = stats.summary.build_types + 1
    end
    if data.mined > 0 then
      stats.summary.mine_types = stats.summary.mine_types + 1
    end
  end

  return stats
end

return production
