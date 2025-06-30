---
applyTo: '**'
---
# Documentation References & API Links

## Official Factorio API Documentation

### Primary References

- **Main API Docs**: <https://lua-api.factorio.com/latest/>
- **Runtime API Index**: <https://lua-api.factorio.com/latest/index-runtime.html>
- **Classes Overview**: <https://lua-api.factorio.com/latest/classes.html>

### Critical API Classes Used

- **LuaGameScript**: <https://lua-api.factorio.com/latest/classes/LuaGameScript.html>
  - Main game object (`game` global)
  - Methods: `get_map_exchange_string()`, `tick`, `surfaces`, `forces`

- **LuaHelpers**: <https://lua-api.factorio.com/latest/classes/LuaHelpers.html#write_file>
  - **CRITICAL**: `helpers.write_file(path, content, append)` - File writing API
  - **CRITICAL**: `helpers.table_to_json(obj)` - JSON serialization API

- **LuaEntity**: <https://lua-api.factorio.com/latest/classes/LuaEntity.html>
  - Entity properties: `unit_number`, `name`, `position`, `status`
  - Methods: `get_recipe()`, `get_module_inventory()`, `is_crafting()`

- **LuaSurface**: <https://lua-api.factorio.com/latest/classes/LuaSurface.html>
  - `find_entities_filtered(filter)` - Entity searching
  - `name` - Surface identifier

- **LuaForce**: <https://lua-api.factorio.com/latest/classes/LuaForce.html>
  - Production statistics methods
  - Technology and research data

### API Concepts & Types

- **MapTick**: <https://lua-api.factorio.com/latest/concepts/MapTick.html>
- **EntityID**: <https://lua-api.factorio.com/latest/concepts/EntityID.html>
- **ForceID**: <https://lua-api.factorio.com/latest/concepts/ForceID.html>

## Wiki Documentation

### Console Commands & Scripting

- **Console Documentation**: <https://wiki.factorio.com/Console>
  - Contains examples of `helpers.table_to_json()` usage
  - Shows `game.write_file()` examples (but this method doesn't exist!)
  - Scripting patterns and best practices

### Modding Guides

- **Modding Tutorial**: <https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir>
- **Mod Structure**: <https://wiki.factorio.com/Tutorial:Mod_structure>
- **Data Lifecycle**: <https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html>

## Development Issues Resolved

### File Writing API Error

- **Issue**: Used `game.write_file()` which doesn't exist
- **Solution**: Use `helpers.write_file(path, content, false)`
- **Source**: <https://lua-api.factorio.com/latest/classes/LuaHelpers.html#write_file>

### JSON Serialization

- **Built-in Method**: `helpers.table_to_json(obj)`
- **Fallback**: Custom implementation for compatibility
- **Evidence**: Console documentation examples

### Entity Property Access

- **Pattern**: Always use safe access with fallbacks
- **Example**: `entity.energy or 0`
- **Reason**: Properties may not exist on all entity types

## External Resources

### Community References

- **Factorio Forums**: <https://forums.factorio.com/>
- **Modding Section**: <https://forums.factorio.com/viewforum.php?f=233>
- **Reddit r/factorio**: <https://www.reddit.com/r/factorio/>

### Development Tools

- **Factorio Mod Portal**: <https://mods.factorio.com/>
- **Data.raw Reference**: <https://wiki.factorio.com/Data.raw>

## Testing & Validation

### In-Game Testing Commands

- `/c /metrics-exporter` - Trigger metrics collection
- `/c game.player.print("test")` - Basic console output
- `/c helpers.write_file("test.txt", "content", false)` - Test file writing

### File Output Locations

- **Script Output**: `%APPDATA%\Factorio\script-output\`
- **User Data Directory**: <https://wiki.factorio.com/User_data_directory>

## Version Compatibility Notes

### Factorio 2.0.58+

- All API calls verified against this version
- Some properties may not exist in older versions
- Use safe access patterns for backward compatibility

### Lua 5.2 Specifics

- Modified Lua environment in Factorio
- Some standard library functions may not be available
- Global objects (`game`, `helpers`, `defines`) provided by engine

## Research Methodology

### API Verification Process

1. Check official API documentation first
2. Cross-reference with console examples
3. Test in-game with `/c` commands
