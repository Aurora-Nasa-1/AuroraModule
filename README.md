# Aurora Module Build System

现代化的Magisk模块构建系统，支持C++组件、WebUI界面和智能打包。

## 核心特性

- **一键构建**：自动化构建流程，支持多架构
- **WebUI支持**：内置WebUI构建和实时开发预览
- **智能打包**：单包/分包模式，自动架构处理
- **灵活配置**：丰富的构建选项和高级设置
- **版本控制**：自动从Git标签同步版本号，支持自动更新管理器更新检查

## 快速开始

### 1. 准备模块
将现有Magisk模块复制到 `module/` 目录（或新建模块），确保包含 `module/settings.json` 配置文件。
*可以不包含META-INF文件夹，并且customize.sh文件默认自动处理*

### 2. 配置构建
编辑 `module/settings.json`，设置模块信息：
```json
{
  "build_module": true,
  "build": {
    "module_properties": {
      "module_name": "YourModuleID",
      "module_version": "1.0.0",
      "module_author": "YourName",
      "module_description": "模块描述"
    }
  }
}
```

### 3. 开始构建
```bash
cd build
bash build.sh          # 交互式构建
bash build.sh -a       # 自动构建
bash build.sh -c       # 查看配置
bash build.sh -d       # WebUI开发模式
```

## 配置说明

参考配置文件：`module/settings.json`
“.”用于分隔配置项在json中的层级关系

### 构建控制
- `build.build_type` - 构建类型：`Release`（发布版）或 `Debug`（调试版）

### 模块属性
- `build.rewrite_module_properties` - 是否从配置重写module.prop文件
- `build.module_properties.module_name` - 模块ID和名称
- `build.module_properties.module_version` - 模块版本号
- `build.module_properties.module_author` - 模块作者
- `build.module_properties.module_description` - 模块描述
- `build.module_properties.updateJson` - 更新检查URL（请将your_name/your_repo替换为你的GitHub用户名和仓库名）

### WebUI设置
- `build.Aurora_webui_build` - 是否构建WebUI界面
- `build.webui.webui_overlay_src_path` - WebUI覆盖层源码路径
- `build.webui.webui_build_output_path` - WebUI构建输出目录

### 脚本增强
- `build.script.add_Aurora_function_for_script` - 为安装脚本添加Aurora核心函数
- `build.script.add_log_support_for_script` - 为安装脚本添加日志支持

### 版本同步
- `build.version_sync.sync_with_git_tag` - 是否与Git标签同步版本（如果是，将使用Git标签作为版本号,并且启用updateJson以及更新检查（需要在GitHub上创建Release））
- `build.version_sync.tag_prefix` - Git标签前缀，默认为"v"

### 自定义构建
- `build.custom_build_script` - 是否启用自定义构建脚本
- `build.build_script.script_path` - 自定义构建脚本路径

### 高级选项
- `build.advanced.compress_resources` - 使用最大压缩率打包
- `build.advanced.validate_config` - 启用配置验证检查

### CPP工具构建选项（filewatcher）
- `build.advanced.skip_cpp_build` - 跳过C++编译，仅构建脚本模块

- `build.package_mode` - 打包模式：`single_zip`（单包多架构）或 `separate_zip`（分包单架构）仅在构建可执行文件时使用
- `build.architectures` - 目标架构列表，如 `["arm64-v8a", "x86_64"]`（仅在构建可执行文件时使用）
- `build.use_tools_form` - 工具获取方式：`build`（源码构建）或 `release`（下载发布版）
- `build.Github_update_repo` - GitHub仓库路径，用于工具下载和更新检查

- `build.advanced.strip_binaries` - 剥离二进制文件调试符号以减小体积
- `build.advanced.enable_debug_logging` - 启用C++组件调试日志

## 构建模式

### 标准模式（默认）
- 构建C++组件和WebUI
- 支持多架构自动处理
- 生成完整功能模块

### 脚本模式
```json
{
  "build": {
    "advanced": {
      "skip_cpp_build": true
    }
  }
}
```
- 跳过C++编译，仅打包脚本
- 构建速度快，适合纯脚本模块
- 无需Android NDK环境

### WebUI开发模式
```bash
bash build.sh -d
```
- 实时预览WebUI界面
- 支持热重载和文件监控
- 需要Node.js环境

### WebUI覆盖层开发
```json
{
  "build": {
    "webui": {
      "webui_overlay_src_path": "webui_overlay_example"
    }
  }
}
```
- 自定义WebUI界面
- 支持页面模块和插件
- 详见 [WebUI开发文档](webui/docs/README.md)
*注意，编译时会将这些文件复制到webui源码上，所以请在webui_overlay_src_path中只包含需要修改或新增的文件，并且做好pages.json的处理*

### 常见错误

| 问题 | 解决方案 |
|------|----------|
| NDK未找到 | 设置 `ANDROID_NDK_ROOT` 环境变量 |
| WebUI构建失败 | 检查Node.js安装，运行 `npm install` |
| 权限错误 | `chmod +x build/build.sh` |
| 配置无效 | 检查 `settings.json` 语法 |

## 高级用法

### WebUI开发

支持自定义WebUI界面开发：
- 页面模块和插件系统
- 国际化支持
- 实时开发预览
- 详见 [WebUI开发文档](webui/docs/develop.md)