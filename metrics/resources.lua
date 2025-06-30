-- Enhanced Resource and Production Metrics Module
local resources = {}

function resources.collect_surface_resources(surface)
  local surface_resources = {}

  -- Use the built-in optimized method for total resource counts
  local resource_counts = surface.get_resource_counts()

  -- Also collect detailed resource patch information
  local resource_entities = surface.find_entities_filtered { type = "resource" }

  for resource_name, total_amount in pairs(resource_counts) do
    surface_resources[resource_name] = {
      total_amount = total_amount,
      patch_count = 0,
      patches = {},
      entities_sampled = {}
    }
  end

  -- Analyze patches and collect sample entity data (limit for performance)
  local entity_limit = 100 -- Limit entity details for performance
  local entity_count = 0
  local patch_tracker = {} -- Track patches by clustering nearby entities

  for _, entity in pairs(resource_entities) do
    local resource_name = entity.name

    if not surface_resources[resource_name] then
      surface_resources[resource_name] = {
        total_amount = entity.amount,
        patch_count = 0,
        patches = {},
        entities_sampled = {}
      }
    end

    -- Sample entity details (limited for performance)
    if entity_count < entity_limit then
      table.insert(surface_resources[resource_name].entities_sampled, {
        position = { x = math.floor(entity.position.x), y = math.floor(entity.position.y) },
        amount = entity.amount
      })
      entity_count = entity_count + 1
    end

    -- Simple patch detection by proximity
    local pos_key = math.floor(entity.position.x / 32) .. "," .. math.floor(entity.position.y / 32)
    if not patch_tracker[resource_name] then
      patch_tracker[resource_name] = {}
    end
    if not patch_tracker[resource_name][pos_key] then
      patch_tracker[resource_name][pos_key] = {
        chunk_x = math.floor(entity.position.x / 32),
        chunk_y = math.floor(entity.position.y / 32),
        entity_count = 0,
        total_amount = 0
      }
      surface_resources[resource_name].patch_count = surface_resources[resource_name].patch_count + 1
    end

    patch_tracker[resource_name][pos_key].entity_count = patch_tracker[resource_name][pos_key].entity_count + 1
    patch_tracker[resource_name][pos_key].total_amount = patch_tracker[resource_name][pos_key].total_amount +
    entity.amount
  end

  -- Store patch information
  for resource_name, patches in pairs(patch_tracker) do
    surface_resources[resource_name].patches = patches
  end

  return surface_resources
end

function resources.collect_production_statistics(force)
  -- This function is now handled by the production module
  -- Kept for compatibility
  local production_stats = {
    force_name = force.name,
    note = "Use production module for detailed statistics"
  }
  return production_stats
end

function resources.collect_fluid_statistics(force)
  -- This function is now handled by the production module
  -- Kept for compatibility
  local fluid_stats = {
    force_name = force.name,
    note = "Use production module for detailed statistics"
  }
  return fluid_stats
end

return resources
