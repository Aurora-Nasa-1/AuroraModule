# Aurora Module Build System

现代化的Magisk模块构建系统，支持多架构C++组件、WebUI和智能打包。

## 开始

### 1. 配置模块

克隆此仓库或下载此仓库

模块在`module`目录下，作为模块的根目录

可以从Magisk现有模块复制到`module`目录，或者将模块仓库导入为文件夹（gitmodules），但必须有`module/settings.json`.

然后编辑 `module/settings.json` [JSON设置详细说明](#配置选项详解)：

### 2. 一键构建
**建议使用GitHub Action进行自动构建与版本控制（提交tag触发，tag格式为v'*'，会自动同步到模块版本与版本代码）**
```bash
# 查看当前配置
./build/build.sh -c

# 开始构建
./build/build.sh

# 自动构建（CI/CD）
./build/build.sh -a
```

## 配置选项详解

### 核心配置

| 选项 | 类型 | 说明 |
|------|------|------|
| `build_module` | boolean | 是否启用构建 |
| `build_type` | string | 构建类型：Release/Debug |
| `architectures` | array | 目标架构列表 |
| `package_mode` | string | 打包模式 |

| 打包模式 | 说明 | 适用场景 |
|------|------|----------|
| `single_zip` | 多架构单包，运行时自动选择 | 通用分发，减少包数量 |
| `separate_zip` | 每个架构单独打包 | 精确控制，减少包大小 |

### 组件配置

| 选项 | 类型 | 说明 |
|------|------|------|
| `Aurora_webui_build` | boolean | 是否构建WebUI组件 |
| `script.add_Aurora_function_for_script` | boolean | 集成Aurora核心函数到安装脚本 |
| `script.add_log_support_for_script` | boolean | 集成高级日志系统到安装脚本 |

### WebUI组件

| 选项 | 类型 | 说明 |
|------|------|------|
| `Aurora_webui_build` | boolean | 是否构建WebUI组件 |
| `webui.webui_overlay_src_path` | string | WebUI覆盖层源码路径，用于自定义修改 |
| `webui.webui_build_output_path` | string | WebUI构建输出路径，默认为webroot |

### 工具获取配置

| 选项 | 类型 | 说明 |
|------|------|------|
| `use_tools_form` | string | 工具来源：`build`从源码构建/`release`从GitHub Release下载 |
| `Github_update_repo` | string | GitHub仓库路径，用于release模式和更新检查 |

### 版本控制配置

| 选项 | 类型 | 说明 |
|------|------|------|
| `rewrite_module_properties` | boolean | 是否从settings.json重写module.prop |
| `version_sync.sync_with_git_tag` | boolean | 是否从Git标签同步版本号 |
| `version_sync.tag_prefix` | string | Git标签前缀，默认为"v" |

### 自定义构建

| 选项 | 类型 | 说明 |
|------|------|------|
| `custom_build_script` | boolean | 是否启用自定义构建脚本 |
| `build_script.script_path` | string | 自定义构建脚本路径 |

### 高级配置

| 选项 | 类型 | 说明 |
|------|------|------|
| `advanced.enable_debug_logging` | boolean | 启用C++组件的调试日志输出 |
| `advanced.strip_binaries` | boolean | 是否剥离二进制文件的调试符号以减小体积 |
| `advanced.compress_resources` | boolean | 是否使用最大压缩率打包模块 |
| `advanced.validate_config` | boolean | 是否启用配置验证检查 |

## 构建输出

构建完成后生成的文件结构：

```
build_output/
├── module/                          # 模块源文件
│   ├── META-INF/                    # META-INF
│   ├── bin/                         # 多架构二进制文件
│   │   └── filewatcher_ModuleName_*
│   ├── webroot/                     # WebUI文件（可选）
│   ├── module.prop                  # 模块属性
│   └── customize.sh                 # 智能安装脚本
└── 输出包：
    ├── AuroraModule-1.0.1-multi-arch.zip  # 单包模式
    ├── AuroraModule-1.0.1-arm64-v8a.zip   # 分包模式
    └── AuroraModule-1.0.1-x86_64.zip      # 分包模式
```

### 架构处理机制

- **构建时**：为每个架构生成带后缀的二进制文件
- **安装时**：`customize.sh` 自动检测设备架构并清理无关文件
- **运行时**：只保留当前架构的二进制文件，优化存储空间

### 常见错误

| 问题 | 解决方案 |
|------|----------|
| NDK未找到 | 设置 `ANDROID_NDK_ROOT` 环境变量 |
| WebUI构建失败 | 检查Node.js安装，运行 `npm install` |
| 权限错误 | `chmod +x build/build.sh` |
| 配置无效 | 检查 `settings.json` 语法 |

## 高级用法

### CI/CD 自动化

**GitHub Actions 示例：**
```yaml
name: Build Module
on: 
  push:
    tags: ['v*']
  pull_request:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    - name: Setup Android NDK
      uses: nttld/setup-ndk@v1
      with:
        ndk-version: r25c
    - name: Build Module
      run: |
        chmod +x build/build.sh
        ./build/build.sh -a
    - name: Upload Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: aurora-module
        path: build_output/*.zip
```

### 自定义构建脚本

```json
{
  "build": {
    "custom_build_script": true,
    "build_script": {
      "script_path": "scripts/custom_build.sh"
    }
  }
}
```

### WebUI覆盖层开发

项目包含完整的WebUI覆盖层示例，展示如何创建自定义页面和插件：

```json
{
  "webui": {
    "webui_default": true,
    "webui_overlay_src_path": "webui_overlay_example"
  }
}
```


**开发文档**:
- [WebUI覆盖层示例](webui_overlay_example/README.md) - 完整的开发示例和使用指南
- [WebUI开发指南](github.com/APMMDEVS/ModuleWebUI/docs/develop.md) - 核心API和功能说明
- [页面模块开发](github.com/APMMDEVS/ModuleWebUI/docs/page-module-development.md) - 页面开发详细教程
- [插件开发指南](github.com/APMMDEVS/ModuleWebUI/docs/plugin-development.md) - 插件开发完整指南

## 贡献

欢迎提交Issue和Pull Request来改进这个构建系统。

## 许可证

本项目采用MIT许可证。
