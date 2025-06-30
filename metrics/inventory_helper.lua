-- Safe inventory access helper
local inventory_helper = {}

-- Safely get inventory with error handling
function inventory_helper.safe_get_inventory(entity, inventory_type)
  if not entity or not entity.get_inventory then
    return nil
  end

  local success, inventory = pcall(entity.get_inventory, entity, inventory_type)
  if success and inventory then
    return inventory
  end
  return nil
end

-- Get inventory contents safely
function inventory_helper.get_inventory_contents(inventory)
  if not inventory then
    return {}
  end

  local contents = {}
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read then
      table.insert(contents, {
        name = stack.name,
        count = stack.count
      })
    end
  end
  return contents
end

return inventory_helper
