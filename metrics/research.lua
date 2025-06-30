-- Research/Labs Metrics Module
local research = {}
local inventory_helper = require("metrics.inventory_helper")

function research.collect(surface)
  local labs = {}

  for _, entity in pairs(surface.find_entities_filtered { type = "lab" }) do
    local lab_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      status = tostring(entity.status),
      energy_usage = entity.prototype.energy_usage or 0
    }
    -- Check science pack inventory using safe helper
    -- Try common lab inventory indices (simplified to avoid defines issues)
    local lab_inv = inventory_helper.safe_get_inventory(entity, 1) or
        inventory_helper.safe_get_inventory(entity, 2)
    if lab_inv then
      lab_data.science_packs = inventory_helper.get_inventory_contents(lab_inv)
    end

    table.insert(labs, lab_data)
  end

  return labs
end

function research.collect_force_data(force)
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

  return force_data
end

return research
