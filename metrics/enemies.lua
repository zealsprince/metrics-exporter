-- Enemy and Combat Metrics Module
local enemies = {}

function enemies.collect_enemy_entities(surface)
  local enemy_data = {
    spawners = {},
    units = {},
    worms = {},
    nests = {},
    summary = {
      total_spawners = 0,
      total_units = 0,
      total_worms = 0,
      total_nests = 0,
      evolution_factor = 0
    }
  }

  -- Get evolution factor for enemy force
  local enemy_force = game.forces.enemy
  if enemy_force and enemy_force.valid then
    enemy_data.summary.evolution_factor = enemy_force.get_evolution_factor(surface)
  end

  -- Count spawners (biter and spitter spawners)
  local spawner_entities = surface.find_entities_filtered {
    type = "unit-spawner",
    force = "enemy"
  }

  for _, spawner in pairs(spawner_entities) do
    local spawner_name = spawner.name
    if not enemy_data.spawners[spawner_name] then
      enemy_data.spawners[spawner_name] = {
        count = 0,
        positions = {}
      }
    end

    enemy_data.spawners[spawner_name].count = enemy_data.spawners[spawner_name].count + 1
    table.insert(enemy_data.spawners[spawner_name].positions, {
      x = math.floor(spawner.position.x),
      y = math.floor(spawner.position.y)
    })
    enemy_data.summary.total_spawners = enemy_data.summary.total_spawners + 1
  end

  -- Count units (biters, spitters)
  local unit_entities = surface.find_entities_filtered {
    type = "unit",
    force = "enemy"
  }

  for _, unit in pairs(unit_entities) do
    local unit_name = unit.name
    if not enemy_data.units[unit_name] then
      enemy_data.units[unit_name] = {
        count = 0,
        health_total = 0,
        health_average = 0
      }
    end

    enemy_data.units[unit_name].count = enemy_data.units[unit_name].count + 1
    enemy_data.units[unit_name].health_total = enemy_data.units[unit_name].health_total + (unit.health or 0)
    enemy_data.summary.total_units = enemy_data.summary.total_units + 1
  end

  -- Calculate average health for each unit type
  for unit_name, data in pairs(enemy_data.units) do
    if data.count > 0 then
      data.health_average = data.health_total / data.count
    end
  end
  -- Count worms (turret type enemies)
  local worm_entities = surface.find_entities_filtered {
    type = "turret",
    force = "enemy"
  }

  for _, worm in pairs(worm_entities) do
    local worm_name = worm.name
    if not enemy_data.worms[worm_name] then
      enemy_data.worms[worm_name] = {
        count = 0,
        positions = {}
      }
    end

    enemy_data.worms[worm_name].count = enemy_data.worms[worm_name].count + 1
    table.insert(enemy_data.worms[worm_name].positions, {
      x = math.floor(worm.position.x),
      y = math.floor(worm.position.y)
    })
    enemy_data.summary.total_worms = enemy_data.summary.total_worms + 1
  end

  -- Count nests (enemy bases and other enemy structures)
  -- In Factorio, nests could be various enemy base structures
  local success, nest_entities = pcall(function()
    return surface.find_entities_filtered {
      type = { "unit-spawner", "turret" },
      force = "enemy"
    }
  end)
  if success and nest_entities then
    -- Group all enemy structures as "nests" - this includes both spawners and worms
    -- but provides a different view for analysis
    for _, nest in pairs(nest_entities) do
      local nest_name = nest.name
      if not enemy_data.nests[nest_name] then
        enemy_data.nests[nest_name] = {
          count = 0,
          entity_type = nest.type,
          positions = {},
          health_data = {
            current_total = 0,
            max_total = 0,
            average_health_percent = 0
          }
        }
      end

      enemy_data.nests[nest_name].count = enemy_data.nests[nest_name].count + 1
      table.insert(enemy_data.nests[nest_name].positions, {
        x = math.floor(nest.position.x),
        y = math.floor(nest.position.y)
      })

      -- Track health information
      if nest.health and nest.max_health then
        enemy_data.nests[nest_name].health_data.current_total =
            enemy_data.nests[nest_name].health_data.current_total + nest.health
        enemy_data.nests[nest_name].health_data.max_total =
            enemy_data.nests[nest_name].health_data.max_total + nest.max_health
      end

      enemy_data.summary.total_nests = enemy_data.summary.total_nests + 1
    end

    -- Calculate average health percentages
    for nest_name, data in pairs(enemy_data.nests) do
      if data.health_data.max_total > 0 then
        data.health_data.average_health_percent =
            (data.health_data.current_total / data.health_data.max_total) * 100
      end
    end
  end

  return enemy_data
end

function enemies.collect_player_military_assets(surface)
  local military_data = {
    defenses = {},
    summary = {
      total_turrets = 0,
      total_walls = 0,
      total_military_entities = 0
    }
  }

  -- Find player military entities
  local player_forces = {}
  for _, player in pairs(game.players) do
    if player.valid and player.force then
      player_forces[player.force.name] = player.force
    end
  end

  for force_name, force in pairs(player_forces) do
    -- Count defensive structures
    local turrets = surface.find_entities_filtered {
      type = { "ammo-turret", "electric-turret", "fluid-turret", "artillery-turret" },
      force = force
    }

    for _, turret in pairs(turrets) do
      local turret_name = turret.name
      if not military_data.defenses[turret_name] then
        military_data.defenses[turret_name] = {
          count = 0,
          force = force_name,
          type = "turret"
        }
      end
      military_data.defenses[turret_name].count = military_data.defenses[turret_name].count + 1
      military_data.summary.total_turrets = military_data.summary.total_turrets + 1
      military_data.summary.total_military_entities = military_data.summary.total_military_entities + 1
    end

    -- Count walls and gates
    local walls = surface.find_entities_filtered {
      type = { "wall", "gate" },
      force = force
    }

    for _, wall in pairs(walls) do
      local wall_name = wall.name
      if not military_data.defenses[wall_name] then
        military_data.defenses[wall_name] = {
          count = 0,
          force = force_name,
          type = "wall"
        }
      end
      military_data.defenses[wall_name].count = military_data.defenses[wall_name].count + 1
      military_data.summary.total_walls = military_data.summary.total_walls + 1
      military_data.summary.total_military_entities = military_data.summary.total_military_entities + 1
    end
  end

  return military_data
end

return enemies
