# Aurora Module WebUI 覆盖层示例

这是一个完整的WebUI覆盖层示例，展示了如何为Aurora Module创建自定义页面模块和插件。

(由AI开发此示例)

## 目录结构

```
webui_overlay_example/
├── src/
│   ├── pages/
│   │   └── example-page.js          # 示例页面模块
│   ├── assets/css/pages/
│   │   └── example-page.css         # 页面样式
│   ├── i18n/modules/
│   │   ├── zh.json                  # 中文翻译
│   │   └── en.json                  # 英文翻译
│   ├── plugins/
│   │   └── example-plugin/
│   │       └── index.js             # 示例插件
│   └── pages.json                   # 页面配置
└── README.md                        # 本文档
```

## 🎯 功能特性

### 📄 示例页面模块 (ExamplePage)

- **计数器演示**: 展示状态管理和UI更新
- **Toast消息**: 演示不同类型的提示消息
- **对话框交互**: 展示确认和输入对话框
- **命令执行**: 演示Shell命令执行功能
- **动态列表**: 展示列表的增删操作
- **国际化支持**: 支持中英文切换
- **响应式设计**: 适配移动端和桌面端
- **页面操作按钮**: 顶栏刷新和关于按钮

### 🔌 示例插件 (ExamplePlugin)

- **多位置按钮**: 在头部、侧边栏、底部添加功能按钮
- **事件监听**: 监听页面加载和自定义事件
- **页面增强**: 动态为示例页面添加额外功能
- **设置管理**: 可配置的插件设置
- **使用统计**: 跟踪插件使用情况
- **快速操作**: 提供常用操作的快捷入口
- **批量命令**: 演示批量Shell命令执行

## 🚀 使用方法

### 1. 配置构建系统

在 `settings.json` 中配置WebUI覆盖层：

```json
{
  "webui": {
    "webui_default": true,
    "webui_overlay_src_path": "webui_overlay_example",
    "webui_build_output_path": "webui"
  }
}
```

### 2. 构建模块

运行构建命令：

```bash
./build/build.sh -a
```

构建系统会自动：
1. 复制WebUI源码到临时目录
2. 应用覆盖层文件
3. 执行WebUI构建
4. 将构建结果包含到模块中

### 3. 安装和测试

1. 安装生成的模块到设备
2. 打开模块的WebUI界面
3. 在导航中找到"示例页面"
4. 测试各种功能和插件交互

## 📚 开发指南

### 页面模块开发

参考 [页面模块开发指南](../webui/docs/page-module-development.md)

**基本结构**:
```javascript
class MyPage {
  constructor() {
    // 初始化数据和状态
  }
  
  async render() {
    // 返回页面HTML
  }
  
  async onShow() {
    // 页面显示时的逻辑
  }
  
  cleanup() {
    // 页面清理逻辑
  }
}
```

### 插件开发

参考 [插件开发指南](../webui/docs/plugin-development.md)

**基本结构**:
```javascript
class MyPlugin {
  async init(api) {
    // 插件初始化逻辑
    api.addButton('header', {
      icon: 'star',
      title: '我的按钮',
      action: () => api.showToast('Hello!', 'success')
    });
  }
}
```

### 国际化支持

在 `src/i18n/modules/` 目录下添加语言文件：

```json
{
  "myPage": {
    "title": "我的页面",
    "welcome": "欢迎，{name}！"
  }
}
```

在代码中使用：
```javascript
const text = window.i18n.t('myPage.title');
const formatted = window.i18n.t('myPage.welcome', { name: 'User' });
```

### 响应式设计

```css
@media (max-width: 768px) {
  .my-element {
    /* 移动端样式 */
  }
}
```

## 🔧 API参考

### 核心功能 (window.core)

```javascript
// Toast消息
window.core.showToast('消息', 'success'); // success/error/warning/info

// 命令执行
const result = await window.core.exec('ls -la');

// 错误显示
window.core.showError('错误信息', '上下文');

// 调试日志
window.core.logDebug('调试信息', 'TAG');
```

### 对话框 (window.DialogManager)

```javascript
// 确认对话框
const confirmed = await window.DialogManager.showConfirm('标题', '内容');

// 输入对话框
const input = await window.DialogManager.showInput('标题', '提示', '占位符');

// 列表选择
const selected = await window.DialogManager.showList('标题', options);
```

### 插件API

```javascript
// 添加按钮
api.addButton('header', { icon, title, action });

// 事件监听
api.addHook('event:name', callback);

// 设置存储
api.setSetting('key', 'value');
const value = api.getSetting('key', 'default');
```

## 🐛 调试

启用调试模式：
```javascript
localStorage.setItem('debugMode', 'true');
```

查看调试日志：
```javascript
window.core.logDebug('调试信息', 'TAG');
```

## 📝 注意事项

1. **文件命名**: 页面文件名应与类名对应（小写+连字符）
2. **CSS作用域**: 使用页面特定的CSS类名避免样式冲突
3. **事件清理**: 在页面cleanup方法中清理事件监听器
4. **国际化**: 所有用户可见文本都应支持国际化
5. **响应式**: 确保在不同屏幕尺寸下的良好体验

## 🔗 相关文档

- [WebUI开发指南](../webui/docs/develop.md)
- [页面模块开发指南](../webui/docs/page-module-development.md)
- [插件开发指南](../webui/docs/plugin-development.md)
- [Aurora Module构建系统](../README.md)

## 📄 许可证

本示例遵循与Aurora Module相同的许可证。