# Godot 4 多人游戏 Demo（完整重写版）

## 文件结构

```
godot_multiplayer/
├── project.godot              # GameManager 注册为 Autoload
├── scenes/
│   ├── Main.tscn              # 启动 UI
│   ├── World.tscn             # 游戏世界（MultiplayerSpawner spawn_path = Players）
│   └── Player.tscn            # 玩家节点（MultiplayerSynchronizer 内嵌 RepConfig）
└── scripts/
    ├── GameManager.gd         # Autoload：ENet 初始化、信号
    ├── Main.gd                # 启动 UI 逻辑
    ├── World.gd               # Server spawn/despawn
    └── Player.gd              # 输入 RPC + 位置同步
```

## 关键修复点

| 问题 | 修复方式 |
|---|---|
| `Sprite2D` 无纹理不显示 | 改用 `ColorRect`，直接设 `color` 属性 |
| `MultiplayerSynchronizer` 无同步属性 | `.tscn` 内嵌 `SceneReplicationConfig` |
| `spawn_path = ../Players` 路径错误 | 改为 `spawn_path = Players` |
| 客户端不显示方块 | Spawner 路径修正 + RepConfig 正确定义 |
| 键盘无效 | `_receive_input` RPC 去掉 authority 冲突 |

## 启动方式

### 编辑器（推荐）

```
Debug → Run Multiple Instances → 2
F5 启动
窗口1: Start Server
窗口2: Connect as Client
```

### 命令行

```bash
godot --headless -- server
godot -- client 127.0.0.1
```

## 操作

`WASD` 或方向键移动。每个客户端分配不同 HSV 颜色。
