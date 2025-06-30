-- Player Metrics Module
local players = {}

function players.collect()
  local player_data = {}

  for _, player in pairs(game.connected_players) do
    local player_info = {
      name = player.name,
      index = player.index,
      position = { x = player.position.x, y = player.position.y },
      surface = player.surface.name,
      online_time = player.online_time,
      afk_time = player.afk_time,
      force = player.force.name,
      admin = player.admin,
      character_running_speed_modifier = player.character_running_speed_modifier,
      character_crafting_speed_modifier = player.character_crafting_speed_modifier,
      character_mining_speed_modifier = player.character_mining_speed_modifier,
      character_health_bonus = player.character_health_bonus,
      character_reach_distance_bonus = player.character_reach_distance_bonus,
      character_build_distance_bonus = player.character_build_distance_bonus,
      character_item_drop_distance_bonus = player.character_item_drop_distance_bonus,
      character_item_pickup_distance_bonus = player.character_item_pickup_distance_bonus,
      character_loot_pickup_distance_bonus = player.character_loot_pickup_distance_bonus,
      character_resource_reach_distance_bonus = player.character_resource_reach_distance_bonus
    }

    -- Character inventory if available
    if player.character and player.get_main_inventory() then
      player_info.main_inventory = {}
      local main_inv = player.get_main_inventory()
      for i = 1, #main_inv do
        local stack = main_inv[i]
        if stack.valid_for_read then
          table.insert(player_info.main_inventory, {
            name = stack.name,
            count = stack.count
          })
        end
      end
    end
    -- Armor inventory (simplified to avoid defines issues)
    if player.character then
      local armor_inv = player.get_inventory(2) -- armor inventory index
      if armor_inv then
        player_info.armor = {}
        for i = 1, #armor_inv do
          local stack = armor_inv[i]
          if stack.valid_for_read then
            table.insert(player_info.armor, {
              name = stack.name,
              count = stack.count
            })
          end
        end
      end
    end

    table.insert(player_data, player_info)
  end

  return player_data
end

return players
