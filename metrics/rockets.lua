-- Rocket and Space Program Metrics Module
local rockets = {}

function rockets.collect_rocket_statistics(force)
  local rocket_data = {
    total_rockets_launched = force.rockets_launched or 0,
    items_launched = {},
    summary = {
      total_items_launched = 0,
      unique_item_types_launched = 0,
      satellites_launched = 0
    }
  }

  -- Get items launched in rockets
  if force.items_launched then
    for _, item_data in pairs(force.items_launched) do
      local item_name = item_data.name
      local quality = item_data.quality and item_data.quality.name or "normal"
      local count = item_data.count or 0

      local key = item_name .. "_" .. quality
      if not rocket_data.items_launched[key] then
        rocket_data.items_launched[key] = {
          name = item_name,
          quality = quality,
          count = 0
        }
      end

      rocket_data.items_launched[key].count = rocket_data.items_launched[key].count + count
      rocket_data.summary.total_items_launched = rocket_data.summary.total_items_launched + count

      -- Count satellites specifically
      if item_name == "satellite" then
        rocket_data.summary.satellites_launched = rocket_data.summary.satellites_launched + count
      end
    end
  end

  -- Count unique item types
  for _, item_data in pairs(rocket_data.items_launched) do
    if item_data.count > 0 then
      rocket_data.summary.unique_item_types_launched = rocket_data.summary.unique_item_types_launched + 1
    end
  end

  return rocket_data
end

function rockets.collect_technology_statistics(force)
  local tech_data = {
    current_research = nil,
    research_progress = force.research_progress or 0,
    research_queue_size = 0,
    technologies = {
      completed = {},
      available = {},
      locked = {}
    },
    summary = {
      total_completed = 0,
      total_available = 0,
      total_locked = 0,
      research_enabled = force.research_enabled
    }
  }

  -- Current research
  if force.current_research then
    tech_data.current_research = {
      name = force.current_research.name,
      level = force.current_research.level,
      research_unit_count = force.current_research.research_unit_count,
      research_unit_energy = force.current_research.research_unit_energy
    }
  end

  -- Research queue
  if force.research_queue then
    tech_data.research_queue_size = #force.research_queue
  end

  -- Technology status
  for tech_name, technology in pairs(force.technologies) do
    if technology.researched then
      tech_data.technologies.completed[tech_name] = {
        level = technology.level,
        research_unit_count = technology.research_unit_count
      }
      tech_data.summary.total_completed = tech_data.summary.total_completed + 1
    elseif technology.enabled then
      tech_data.technologies.available[tech_name] = {
        level = technology.level,
        research_unit_count = technology.research_unit_count,
        research_unit_energy = technology.research_unit_energy
      }
      tech_data.summary.total_available = tech_data.summary.total_available + 1
    else
      tech_data.technologies.locked[tech_name] = {
        level = technology.level
      }
      tech_data.summary.total_locked = tech_data.summary.total_locked + 1
    end
  end

  return tech_data
end

return rockets
