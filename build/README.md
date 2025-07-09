# Aurora Module Build System

一个完整的Magisk模块构建系统，支持C++组件、WebUI和自动化打包。

## 功能特性

- 🔧 **自动Android NDK安装** - 支持Linux、macOS、Windows
- 🏗️ **C++组件构建** - 使用CMake和Android NDK
- 🌐 **WebUI构建** - 自动化Node.js构建流程
- 📦 **Magisk模块打包** - 完整的ZIP模块生成
- ⚙️ **灵活配置** - JSON配置文件驱动
- 🔄 **跨平台支持** - POSIX兼容的shell脚本

## 快速开始

### 1. 配置设置

复制示例配置文件：
```bash
cp module/settings.example.json module/settings.json
```

编辑 `module/settings.json` 配置你的模块：
```json
{
  "module": {
    "AuroraModuleBuild": true,
    "META_INF_default": false,
    "install_script_default": false,
    "webui_default": false
  },
  "build_module": true,
  "build": {
    "build_type": "Release",
    "Github_update_repo": "your_username/your_repository",
    "use_tools_form": "build"
  }
}
```

### 2. 运行构建

```bash
# 查看配置
./build/build.sh --config

# 交互式构建
./build/build.sh

# 自动构建（无确认）
./build/build.sh --auto
```

## 配置选项详解

### 模块设置 (`module`)

| 选项 | 类型 | 说明 |
|------|------|------|
| `AuroraModuleBuild` | boolean | 是否构建Aurora Core组件 |
| `META_INF_default` | boolean | 是否使用默认META-INF（false=创建标准Magisk META-INF） |
| `install_script_default` | boolean | 是否跳过安装脚本生成 |
| `webui_default` | boolean | 是否跳过WebUI构建 |

### 构建设置 (`build`)

| 选项 | 类型 | 说明 |
|------|------|------|
| `build_type` | string | 构建类型：Release/Debug |
| `Github_update_repo` | string | GitHub仓库用于WebUI更新 |
| `use_tools_form` | string | 工具形式："build"=启用NDK安装 |
| `Aurora_webui_build` | boolean | 是否构建WebUI |

### 脚本设置 (`script`)

| 选项 | 类型 | 说明 |
|------|------|------|
| `add_Aurora_function_for_script` | boolean | 在customize.sh中引入AuroraCore.sh |
| `add_log_support_for_script` | boolean | 在customize.sh中引入日志支持 |

### 模块属性 (`module_properties`)

| 选项 | 类型 | 说明 |
|------|------|------|
| `module_name` | string | 模块名称 |
| `module_version` | string | 模块版本 |
| `module_versioncode` | number | 版本代码 |
| `module_author` | string | 模块作者 |
| `module_description` | string | 模块描述 |
| `updateJson` | string | 更新JSON URL |

## 构建流程

1. **环境检测** - 检测操作系统和可用工具
2. **依赖检查** - 自动安装jq JSON处理器
3. **NDK安装** - 根据配置自动下载安装Android NDK
4. **C++构建** - 使用CMake构建Core组件
5. **WebUI构建** - 使用npm构建前端界面
6. **模块组装** - 创建Magisk模块结构
7. **脚本生成** - 生成customize.sh安装脚本
8. **模块打包** - 创建最终的ZIP文件

## 输出结构

构建完成后，在 `build_output/` 目录下生成：

```
build_output/
├── module/                 # 模块文件结构
│   ├── META-INF/          # Magisk安装器
│   ├── system/            # 系统文件
│   │   ├── bin/          # 可执行文件
│   │   └── lib64/        # 库文件
│   ├── webroot/          # WebUI文件
│   ├── module.prop       # 模块属性
│   ├── customize.sh      # 安装脚本
│   └── *.sh             # 辅助脚本
└── AuroraModule-1.0.1.zip # 最终模块包
```

## 故障排除

### 常见问题

**Q: jq未找到**
```bash
# 脚本会自动提示安装，或手动安装：
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (Chocolatey)
choco install jq
```

**Q: NDK下载失败**
- 检查网络连接
- 确保有足够磁盘空间（~1GB）
- 手动下载NDK到 `android-ndk/` 目录

**Q: WebUI构建失败**
- 确保安装了Node.js和npm
- 检查 `webui/package.json` 是否存在
- 运行 `npm install` 手动安装依赖

**Q: 权限错误**
```bash
# 确保脚本有执行权限
chmod +x build/build.sh build/build_into.sh
```

## 高级用法

### 自定义构建脚本

启用自定义构建脚本：
```json
{
  "build": {
    "custom_build_script": true,
    "build_script": {
      "script_path": "my_custom_build.sh"
    }
  }
}
```

### 多架构构建

修改 `build_into.sh` 中的 `ANDROID_ABI` 参数：
```bash
# 支持的架构
# arm64-v8a, armeabi-v7a, x86, x86_64
-DANDROID_ABI=arm64-v8a
```

### CI/CD集成

在GitHub Actions中使用：
```yaml
- name: Build Aurora Module
  run: |
    chmod +x build/build.sh
    ./build/build.sh --auto
```

## 贡献

欢迎提交Issue和Pull Request来改进这个构建系统。

## 许可证

本项目采用与Aurora项目相同的许可证。