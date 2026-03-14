# 🏗️ 魔塔游戏框架化设计文档

**版本:** v1.0  
**日期:** 2026-03-14  
**基于:** Godot 魔塔 1.0 (50 层完整版)

---

## 📋 目录

1. [概述](#1-概述)
2. [框架架构](#2-框架架构)
3. [关卡编辑器设计](#3-关卡编辑器设计)
4. [MOD 系统](#4-mod 系统)
5. [数据驱动设计](#5-数据驱动设计)
6. [插件系统](#6-插件系统)
7. [资源管理](#7-资源管理)
8. [API 设计](#8-api 设计)
9. [使用示例](#9-使用示例)
10. [开发路线图](#10-开发路线图)

---

## 1. 概述

### 1.1 目标

将魔塔游戏框架化，实现：
- **游戏编辑器** - 可视化关卡编辑
- **MOD 支持** - 玩家自制内容
- **模板系统** - 快速创建新游戏
- **插件扩展** - 功能可扩展

### 1.2 核心价值

| 用户类型 | 价值 |
|----------|------|
| **玩家** | 安装 MOD，体验新内容 |
| **创作者** | 无需编程，制作关卡 |
| **开发者** | 快速原型，插件扩展 |

### 1.3 技术栈

- **引擎:** Godot 4.x
- **语言:** GDScript
- **数据格式:** JSON
- **MOD 格式:** ZIP 包

---

## 2. 框架架构

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    魔塔框架 (Magic Tower Framework)      │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  游戏核心   │  │  编辑器核心  │  │  MOD 加载器  │     │
│  │   Core      │  │   Editor    │  │   Loader    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  战斗系统   │  │  地图系统   │  │  数据系统   │     │
│  │   Battle    │  │     Map     │  │    Data     │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  UI 系统    │  │  音频系统   │  │  存档系统   │     │
│  │     UI      │  │   Audio     │  │    Save     │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│                    Godot 引擎 (4.x)                      │
└─────────────────────────────────────────────────────────┘
```

### 2.2 目录结构

```
magic-tower-framework/
├── core/                      # 框架核心
│   ├── GameManager.gd
│   ├── SceneManager.gd
│   ├── EventBus.gd
│   └── FrameworkConfig.gd
├── game/                      # 游戏核心
│   ├── battle/
│   │   ├── BattleManager.gd
│   │   ├── BattleUI.gd
│   │   └── formulas.gd
│   ├── entities/
│   │   ├── Player.gd
│   │   ├── Enemy.gd
│   │   └── NPC.gd
│   ├── systems/
│   │   ├── SaveSystem.gd
│   │   ├── ItemSystem.gd
│   │   └── AchievementSystem.gd
│   └── world/
│       ├── MapLoader.gd
│       ├── FloorGenerator.gd
│       └── TeleportSystem.gd
├── editor/                    # 编辑器核心
│   ├── FloorEditor.gd
│   ├── EnemyEditor.gd
│   ├── ItemEditor.gd
│   ├── MapPainter.gd
│   └── PreviewPanel.gd
├── mod/                       # MOD 系统
│   ├── ModLoader.gd
│   ├── ModManager.gd
│   ├── ModInfo.gd
│   └── ModDownloader.gd
├── plugin/                    # 插件系统
│   ├── PluginAPI.gd
│   ├── PluginManager.gd
│   └── hooks/
├── data/                      # 数据模板
│   ├── templates/
│   ├── schemas/
│   └── defaults/
├── assets/                    # 资源
│   ├── sprites/
│   ├── audio/
│   └── ui/
├── mods/                      # MOD 目录
│   └── [MOD 文件夹]/
├── plugins/                   # 插件目录
│   └── [插件文件夹]/
├── projects/                  # 项目目录
│   └── [游戏项目]/
└── project.godot
```

### 2.3 核心类关系

```
GameManager (单例)
├── SceneManager - 管理场景切换
├── EventBus - 全局事件总线
├── DataManager - 数据管理
│   ├── EnemyDatabase
│   ├── ItemDatabase
│   └── FloorDatabase
├── ModManager - MOD 管理
└── PluginManager - 插件管理

BattleManager
├── BattleSystem - 战斗计算
├── EnemyAI - 敌人 AI
└── BattleUI - 战斗界面

MapLoader
├── FloorParser - 楼层解析
├── TilePlacer - 地块放置
├── EntitySpawner - 实体生成
└── CollisionBuilder - 碰撞构建
```

---

## 3. 关卡编辑器设计

### 3.1 编辑器界面

```
┌─────────────────────────────────────────────────────────────┐
│  魔塔关卡编辑器 v1.0                              [保存] [导出] │
├──────────────┬──────────────────────────────────┬───────────┤
│              │                                  │           │
│  工具面板    │         地图编辑区                │  属性面板  │
│              │                                  │           │
│  ┌────────┐  │  ┌──┬──┬──┬──┬──┬──┐           │  ┌──────┐ │
│  │ 墙壁  │  │  │  │  │  │  │  │  │           │  │名称  │ │
│  ├────────┤  │  ├──┼──┼──┼──┼──┼──┤           │  ├──────┤ │
│  │ 地板  │  │  │  │  │👦│  │  │  │           │  │类型  │ │
│  ├────────┤  │  ├──┼──┼──┼──┼──┼──┤           │  ├──────┤ │
│  │ 敌人  │  │  │  │  │  │  │  │  │           │  │HP    │ │
│  ├────────┤  │  ├──┼──┼──┼──┼──┼──┤           │  ├──────┤ │
│  │ 道具  │  │  │  │  │  │  │  │  │           │  │攻击  │ │
│  ├────────┤  │  ├──┼──┼──┼──┼──┼──┤           │  ├──────┤ │
│  │ NPC   │  │  │  │  │  │  │  │  │           │  │防御  │ │
│  ├────────┤  │  └──┴──┴──┴──┴──┴──┘           │  ├──────┤ │
│  │ 传送  │  │     17x17 网格                    │  │金币  │ │
│  └────────┘  │                                  │  └──────┘ │
│              │  [1F] [2F] [3F] ... [50F]        │           │
│  资源库      │                                  │  预览     │
│  ┌────────┐  │                                  │  ┌──────┐ │
│  │🧱 🚪  │  │                                  │  │      │ │
│  │💊 💎  │  │                                  │  │      │ │
│  └────────┘  │                                  │  └──────┘ │
│              │                                  │           │
└──────────────┴──────────────────────────────────┴───────────┘
```

### 3.2 编辑器功能

#### 核心功能
| 功能 | 描述 | 快捷键 |
|------|------|--------|
| 地图绘制 | 放置墙壁、地板、门 | 鼠标拖拽 |
| 实体放置 | 放置敌人、道具、NPC | 拖拽 |
| 楼层管理 | 创建/删除/复制楼层 | Ctrl+N/D/C |
| 批量操作 | 区域选择、批量修改 | Ctrl+ 拖拽 |
| 预览 | 实时预览楼层效果 | F5 |
| 保存 | 保存为 JSON | Ctrl+S |
| 导出 | 导出为 MOD 包 | Ctrl+E |

#### 高级功能
| 功能 | 描述 |
|------|------|
| 模板导入 | 导入预设楼层模板 |
| 脚本编辑 | 编辑楼层事件脚本 |
| 碰撞编辑 | 可视化碰撞区域 |
| 路径编辑 | 编辑敌人巡逻路径 |
| 触发器 | 设置事件触发器 |

### 3.3 编辑器数据结构

```json
{
  "floor_id": 1,
  "floor_name": "试炼第一层",
  "size": {"width": 17, "height": 17},
  "tiles": [
    {"x": 0, "y": 0, "type": "wall"},
    {"x": 1, "y": 0, "type": "floor"},
    ...
  ],
  "entities": [
    {
      "id": "enemy_001",
      "type": "enemy",
      "enemy_id": "slime_green",
      "x": 8,
      "y": 5,
      "direction": "down"
    },
    {
      "id": "item_001",
      "type": "item",
      "item_id": "potion_small",
      "x": 12,
      "y": 8
    }
  ],
  "events": [
    {
      "id": "event_001",
      "trigger": "player_enter",
      "actions": [
        {"type": "show_dialogue", "text": "欢迎来到魔塔！"}
      ]
    }
  ],
  "settings": {
    "background": "dungeon_01",
    "music": "floor_01.ogg",
    "ambient": "dungeon_ambience"
  }
}
```

### 3.4 编辑器脚本 API

```gdscript
# 编辑器脚本示例
extends EditorScript

func on_floor_load(floor_id: int):
    # 楼层加载时调用
    pass

func on_tile_place(x: int, y: int, tile_type: String):
    # 放置地块时调用
    pass

func on_entity_place(entity: Entity):
    # 放置实体时调用
    pass

func on_save():
    # 保存前调用
    pass

func validate_floor() -> bool:
    # 验证楼层合法性
    # 检查：玩家入口、楼梯连通性、可达性
    return true
```

---

## 4. MOD 系统

### 4.1 MOD 结构

```
my-mod/
├── mod_info.json        # MOD 信息
├── mod_icon.png         # MOD 图标
├── floors/              # 楼层数据
│   ├── floor_001.json
│   ├── floor_002.json
│   └── ...
├── enemies/             # 新敌人
│   ├── enemy_definitions.json
│   └── sprites/
├── items/               # 新道具
│   ├── item_definitions.json
│   └── sprites/
├── scripts/             # 脚本
│   ├── events.gd
│   └── quests.gd
├── assets/              # 资源
│   ├── music/
│   ├── sfx/
│   └── graphics/
└── translations/        # 翻译
    └── zh_CN.po
```

### 4.2 MOD 信息格式

```json
{
  "mod_id": "my_custom_tower",
  "name": "我的自定义魔塔",
  "version": "1.0.0",
  "author": "创作者名字",
  "description": "一个 50 层的全新魔塔 MOD",
  "framework_version": ">=1.0.0",
  "dependencies": [],
  "tags": ["tower", "custom", "hard"],
  "floors": 50,
  "new_enemies": 10,
  "new_items": 15,
  "has_custom_music": true,
  "has_custom_graphics": true,
  "download_url": "https://...",
  "homepage": "https://..."
}
```

### 4.3 MOD 加载器

```gdscript
# ModLoader.gd
class_name ModLoader

var loaded_mods: Array = []
var mod_directory: String = "res://mods/"

func load_mod(mod_path: String) -> ModInfo:
    # 加载 MOD
    var mod_info = load_mod_info(mod_path)
    if not validate_mod(mod_info):
        return null
    
    # 加载楼层数据
    load_floor_data(mod_path, mod_info)
    
    # 加载新敌人
    load_enemy_data(mod_path, mod_info)
    
    # 加载新道具
    load_item_data(mod_path, mod_info)
    
    # 加载资源
    load_assets(mod_path, mod_info)
    
    loaded_mods.append(mod_info)
    return mod_info

func unload_mod(mod_id: String):
    # 卸载 MOD
    pass

func enable_mod(mod_id: String):
    # 启用 MOD
    pass

func disable_mod(mod_id: String):
    # 禁用 MOD
    pass

func get_active_mods() -> Array:
    # 获取启用的 MOD 列表
    return loaded_mods.filter(func(m): return m.enabled)
```

### 4.4 MOD 管理器界面

```
┌─────────────────────────────────────────────────┐
│              MOD 管理器                          │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │
│  │ 🔍 搜索 MOD...                  [刷新]  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ☑ 魔塔原版 (必需)                    [设置]   │
│  ☑ 新敌人包                           [卸载]   │
│  ☐ 寒冰扩展包                         [下载]   │
│  ☐ 火焰扩展包                         [下载]   │
│  ☐ 虚空扩展包                         [下载]   │
│                                                 │
│  ────────────────────────────────────────────   │
│  [+ 安装 MOD]  [打开 MOD 文件夹]  [创意工坊]     │
└─────────────────────────────────────────────────┘
```

### 4.5 MOD 安装流程

```
1. 用户下载 MOD 包 (.zip)
         ↓
2. 解压到 mods/ 目录
         ↓
3. 读取 mod_info.json
         ↓
4. 验证兼容性 (framework_version)
         ↓
5. 检查依赖 (dependencies)
         ↓
6. 注册到 MOD 管理器
         ↓
7. 用户启用 MOD
         ↓
8. 重启游戏加载 MOD
```

---

## 5. 数据驱动设计

### 5.1 数据 Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Enemy Definition",
  "type": "object",
  "properties": {
    "id": {"type": "string", "pattern": "^[a-z_]+$"},
    "name": {"type": "string"},
    "stats": {
      "type": "object",
      "properties": {
        "hp": {"type": "integer", "minimum": 1},
        "attack": {"type": "integer", "minimum": 0},
        "defense": {"type": "integer", "minimum": 0}
      }
    },
    "rewards": {
      "type": "object",
      "properties": {
        "gold": {"type": "integer"},
        "experience": {"type": "integer"}
      }
    }
  },
  "required": ["id", "name", "stats"]
}
```

### 5.2 敌人数据模板

```json
{
  "id": "slime_green",
  "name": "绿色史莱姆",
  "description": "最常见的魔物",
  "sprite": "res://assets/enemies/slime_green.png",
  "stats": {
    "hp": 50,
    "attack": 10,
    "defense": 5,
    "speed": 3
  },
  "rewards": {
    "gold": 5,
    "experience": 2
  },
  "behavior": "passive",
  "ai_type": "basic_melee",
  "weaknesses": ["fire"],
  "resistances": ["water"],
  "drops": [
    {"item_id": "slime_jelly", "chance": 0.1}
  ]
}
```

### 5.3 道具数据模板

```json
{
  "id": "potion_small",
  "name": "小药水",
  "description": "恢复 50 点生命值",
  "sprite": "res://assets/items/potion_small.png",
  "type": "consumable",
  "effect": {
    "type": "heal",
    "target": "hp",
    "value": 50
  },
  "rarity": "common",
  "stack_size": 99,
  "sell_price": 10
}
```

### 5.4 楼层数据模板

```json
{
  "id": 1,
  "name": "试炼第一层",
  "size": {"width": 17, "height": 17},
  "tileset": "dungeon_basic",
  "tiles": [],
  "entities": [],
  "events": [],
  "settings": {
    "background": "dungeon_01",
    "music": "floor_01.ogg",
    "lighting": "dim",
    "weather": "none"
  },
  "difficulty": 1,
  "recommended_level": 1
}
```

### 5.5 数据验证器

```gdscript
# DataValidator.gd
class_name DataValidator

static func validate_enemy(data: Dictionary) -> bool:
    # 验证敌人数据
    if not data.has("id"):
        push_error("Enemy missing 'id'")
        return false
    if not data.has("name"):
        push_error("Enemy missing 'name'")
        return false
    if not data.has("stats"):
        push_error("Enemy missing 'stats'")
        return false
    return true

static func validate_item(data: Dictionary) -> bool:
    # 验证道具数据
    if not data.has("id"):
        return false
    if not data.has("type"):
        return false
    return true

static func validate_floor(data: Dictionary) -> bool:
    # 验证楼层数据
    if not data.has("id"):
        return false
    if not data.has("size"):
        return false
    # 检查玩家入口存在
    # 检查楼梯连通性
    return true
```

---

## 6. 插件系统

### 6.1 插件 API

```gdscript
# PluginAPI.gd
class_name PluginAPI

# 生命周期钩子
func on_init():
    # 插件初始化时调用
    pass

func on_game_start():
    # 游戏开始时调用
    pass

func on_game_end():
    # 游戏结束时调用
    pass

func on_save(data: Dictionary) -> Dictionary:
    # 保存前调用，可修改存档数据
    return data

func on_load(data: Dictionary) -> Dictionary:
    # 加载后调用，可读取存档数据
    return data

# 事件钩子
func on_battle_start(enemy: Enemy):
    # 战斗开始时调用
    pass

func on_battle_end(victory: bool):
    # 战斗结束时调用
    pass

func on_item_use(item: Item):
    # 使用道具时调用
    pass

func on_floor_enter(floor_id: int):
    # 进入楼层时调用
    pass

# 扩展点
func register_custom_battle_action(action: BattleAction):
    # 注册自定义战斗动作
    pass

func register_custom_ui_element(element: Control):
    # 注册自定义 UI 元素
    pass
```

### 6.2 插件结构

```
my-plugin/
├── plugin.cfg           # 插件配置
├── plugin.gd            # 主脚本
├── scripts/             # 插件脚本
├── assets/              # 插件资源
└── README.md
```

### 6.3 插件配置

```json
{
  "plugin_id": "custom_battle_ui",
  "name": "自定义战斗 UI",
  "version": "1.0.0",
  "author": "插件作者",
  "description": "替换默认战斗界面",
  "framework_version": ">=1.0.0",
  "main_script": "plugin.gd",
  "hooks": [
    "on_init",
    "on_battle_start",
    "register_custom_ui_element"
  ],
  "dependencies": [],
  "load_order": 100
}
```

### 6.4 插件示例

```gdscript
# custom_battle_ui/plugin.gd
extends PluginAPI

var custom_ui: Control

func on_init():
    # 加载自定义 UI
    custom_ui = preload("res://plugins/custom_battle_ui/BattleUI.tscn").instantiate()

func on_battle_start(enemy: Enemy):
    # 战斗开始时显示自定义 UI
    get_tree().current_scene.add_child(custom_ui)
    custom_ui.setup(enemy)

func on_battle_end(victory: bool):
    # 战斗结束时隐藏自定义 UI
    custom_ui.queue_free()
```

---

## 7. 资源管理

### 7.1 资源加载器

```gdscript
# ResourceManager.gd
class_name ResourceManager

var resource_cache: Dictionary = {}

func load_sprite(path: String) -> Texture2D:
    if resource_cache.has(path):
        return resource_cache[path]
    
    var texture = load(path)
    resource_cache[path] = texture
    return texture

func load_audio(path: String, type: String = "music") -> AudioStream:
    # 加载音频
    pass

func load_tileset(path: String) -> TileSet:
    # 加载 tileset
    pass

func unload_unused():
    # 卸载未使用的资源
    pass

func get_memory_usage() -> int:
    # 获取内存使用
    return resource_cache.size()
```

### 7.2 资源包

```
assets/
├── base/                # 基础资源 (必需)
│   ├── enemies/
│   ├── items/
│   ├── tiles/
│   └── ui/
├── expansions/          # 扩展资源
│   ├── mist_tower/
│   ├── ice_tower/
│   └── fire_tower/
└── mods/                # MOD 资源
    └── [MOD 名]/
```

### 7.3 资源引用

```json
{
  "enemy": {
    "sprite": "res://assets/base/enemies/slime.png",
    "attack_sfx": "res://assets/base/sfx/attack.wav",
    "death_sfx": "res://assets/base/sfx/death.wav"
  },
  "item": {
    "sprite": "res://assets/base/items/potion.png",
    "use_sfx": "res://assets/base/sfx/use_item.wav"
  },
  "floor": {
    "tileset": "res://assets/base/tiles/dungeon.tsx",
    "bgm": "res://assets/base/music/floor_01.ogg"
  }
}
```

---

## 8. API 设计

### 8.1 框架 API

```gdscript
# MagicTowerFramework - 主 API 类

# 游戏控制
static func start_game(project_path: String)
static func pause_game()
static func resume_game()
static func end_game()

# 数据访问
static func get_enemy(enemy_id: String) -> EnemyData
static func get_item(item_id: String) -> ItemData
static func get_floor(floor_id: int) -> FloorData

# MOD 管理
static func install_mod(mod_path: String) -> bool
static func uninstall_mod(mod_id: String) -> bool
static func enable_mod(mod_id: String) -> bool
static func disable_mod(mod_id: String) -> bool
static func list_mods() -> Array

# 插件管理
static func install_plugin(plugin_path: String) -> bool
static func uninstall_plugin(plugin_id: String) -> bool
static func list_plugins() -> Array

# 编辑器
static func open_editor()
static func create_new_floor(floor_id: int) -> FloorData
static func save_floor(floor: FloorData) -> bool
static func export_project(output_path: String) -> bool
```

### 8.2 事件系统

```gdscript
# EventBus.gd
class_name EventBus

# 游戏事件
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended(victory: bool)

# 玩家事件
signal player_moved(x: int, y: int)
signal player_stats_changed()
signal player_item_used(item: Item)
signal player_level_up()

# 战斗事件
signal battle_started(enemy: Enemy)
signal battle_ended(victory: bool, rewards: Dictionary)
signal battle_turn_changed()

# 楼层事件
signal floor_entered(floor_id: int)
signal floor_cleared(floor_id: int)

# MOD 事件
signal mod_installed(mod_id: String)
signal mod_uninstalled(mod_id: String)
signal mod_enabled(mod_id: String)
signal mod_disabled(mod_id: String)
```

### 8.3 保存/加载 API

```gdscript
# SaveSystem.gd
class_name SaveSystem

func create_save(slot: int, data: SaveData) -> bool:
    # 创建存档
    pass

func load_save(slot: int) -> SaveData:
    # 加载存档
    pass

func delete_save(slot: int) -> bool:
    # 删除存档
    pass

func get_save_list() -> Array:
    # 获取存档列表
    pass

func export_save(slot: int, output_path: String) -> bool:
    # 导出存档
    pass

func import_save(input_path: String, slot: int) -> bool:
    # 导入存档
    pass
```

---

## 9. 使用示例

### 9.1 创建新游戏项目

```bash
# 使用框架创建新项目
magic-tower create my_tower
cd my_tower

# 项目结构
my_tower/
├── project.godot
├── floors/
├── enemies/
├── items/
└── mod_info.json
```

### 9.2 使用编辑器创建楼层

```gdscript
# 在编辑器中
var floor = FloorData.new()
floor.id = 1
floor.name = "第一层"
floor.size = Vector2i(17, 17)

# 添加墙壁
for x in range(17):
    floor.add_tile(x, 0, "wall")
    floor.add_tile(x, 16, "wall")

# 添加玩家入口
floor.add_entity("player_start", 8, 8)

# 添加敌人
floor.add_entity("enemy", 5, 5, {"enemy_id": "slime_green"})

# 保存
Editor.save_floor(floor)
```

### 9.3 安装 MOD

```gdscript
# 安装 MOD
var success = MagicTowerFramework.install_mod("res://downloads/my_mod.zip")
if success:
    MagicTowerFramework.enable_mod("my_mod")
    print("MOD 安装成功！")
```

### 9.4 创建插件

```gdscript
# my_plugin/plugin.gd
extends PluginAPI

func on_init():
    print("插件初始化")

func on_battle_start(enemy: Enemy):
    # 战斗开始时播放特殊音效
    Audio.play("res://plugins/my_plugin/sfx/battle_start.wav")

func on_floor_enter(floor_id: int):
    # 进入楼层时显示提示
    UI.show_notification("进入第 %d 层" % floor_id)
```

### 9.5 自定义战斗公式

```gdscript
# custom_formulas/plugin.gd
extends PluginAPI

func register_custom_battle_formula() -> Callable:
    return _calculate_damage

func _calculate_damage(attacker: Character, defender: Character) -> int:
    # 自定义伤害公式
    var base_damage = attacker.attack - defender.defense
    var crit_chance = 0.1
    if randf() < crit_chance:
        return base_damage * 2
    return base_damage
```

---

## 10. 开发路线图

### 阶段 1: 核心框架 (2 周)
- [ ] 提取游戏核心逻辑
- [ ] 创建数据管理系统
- [ ] 实现基础 API
- [ ] 编写文档

### 阶段 2: 编辑器 (3 周)
- [ ] 可视化地图编辑器
- [ ] 实体编辑器
- [ ] 数据验证器
- [ ] 预览功能

### 阶段 3: MOD 系统 (2 周)
- [ ] MOD 加载器
- [ ] MOD 管理器 UI
- [ ] MOD 安装/卸载
- [ ] 兼容性检查

### 阶段 4: 插件系统 (2 周)
- [ ] 插件 API
- [ ] 插件管理器
- [ ] 钩子系统
- [ ] 示例插件

### 阶段 5: 完善 (1 周)
- [ ] 性能优化
- [ ] 文档完善
- [ ] 示例项目
- [ ] 测试

---

## 附录

### A. 术语表

| 术语 | 定义 |
|------|------|
| MOD | 游戏修改/扩展包 |
| 插件 | 功能扩展模块 |
| 实体 | 游戏中的对象 (敌人、道具、NPC) |
| 地块 | 地图的基本单元 |
| 钩子 | 事件回调点 |

### B. 兼容性说明

| 框架版本 | 兼容 MOD | 兼容插件 |
|----------|----------|----------|
| 1.0.x | 1.0.x | 1.0.x |
| 1.1.x | 1.0.x, 1.1.x | 1.0.x, 1.1.x |
| 2.0.x | 需更新 | 需更新 |

### C. 资源

- **GitHub:** https://github.com/chengxy-ai-develop/godot-magic-tower-framework
- **文档:** https://docs.magictower.framework
- **社区:** Discord/QQ 群
- **MOD 仓库:** https://mod.magictower.framework

---

**文档版本:** v1.0  
**最后更新:** 2026-03-14  
**维护者:** 123 (AI 助理)
