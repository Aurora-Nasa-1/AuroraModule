/**
 * 示例插件
 * 展示如何创建WebUI插件并与页面交互
 */
class ExamplePlugin {
  constructor() {
    this.name = 'ExamplePlugin';
    this.version = '1.0.0';
    this.description = 'Aurora Module WebUI示例插件';
    
    // 插件状态
    this.isEnabled = true;
    this.settings = {
      autoGreeting: true,
      greetingMessage: 'Welcome to Aurora Module!',
      showNotifications: true,
      debugMode: false
    };
    
    // 统计数据
    this.stats = {
      pageVisits: 0,
      buttonsClicked: 0,
      commandsExecuted: 0
    };
  }

  /**
   * 插件初始化
   * @param {Object} api 插件API对象
   */
  async init(api) {
    this.api = api;
    
    // 从存储中加载设置
    this.loadSettings();
    
    // 添加插件按钮
    this.addPluginButtons();
    
    // 注册事件监听器
    this.registerEventListeners();
    
    // 显示初始化消息
    if (this.settings.showNotifications) {
      api.showToast('示例插件已加载', 'success');
    }
    
    // 调试日志
    if (this.settings.debugMode) {
      window.core.logDebug('Example plugin initialized', 'PLUGIN');
    }
  }

  /**
   * 添加插件按钮
   */
  addPluginButtons() {
    // 头部按钮 - 插件设置
    this.api.addButton('header', {
      icon: 'tune',
      title: '插件设置',
      action: () => this.showPluginSettings()
    });
    
    // 头部按钮 - 统计信息
    this.api.addButton('header', {
      icon: 'analytics',
      title: '使用统计',
      action: () => this.showStatistics()
    });
    
    // 侧边栏按钮 - 快速操作
    this.api.addButton('sidebar', {
      icon: 'flash_on',
      title: '快速操作',
      action: () => this.showQuickActions()
    });
    
    // 底部按钮 - 插件信息
    this.api.addButton('bottom', {
      icon: 'info',
      title: '插件信息',
      action: () => this.showPluginInfo()
    });
  }

  /**
   * 注册事件监听器
   */
  registerEventListeners() {
    // 监听页面加载事件
    this.api.addHook('page:loaded', (data) => {
      this.onPageLoaded(data);
    });
    
    // 监听示例页面特定事件
    this.api.addHook('example-page:shown', (data) => {
      this.onExamplePageShown(data);
    });
    
    this.api.addHook('example-page:cleanup', (data) => {
      this.onExamplePageCleanup(data);
    });
    
    // 监听应用事件
    this.api.addHook('app:ready', () => {
      this.onAppReady();
    });
  }

  /**
   * 页面加载事件处理
   * @param {Object} data 页面数据
   */
  onPageLoaded(data) {
    this.stats.pageVisits++;
    this.saveStats();
    
    if (this.settings.debugMode) {
      window.core.logDebug(`Page loaded: ${data.page}`, 'PLUGIN');
    }
    
    // 特定页面的处理
    switch (data.page) {
      case 'home':
        this.onHomePageLoaded();
        break;
      case 'example-page':
        this.onExamplePageLoaded();
        break;
      case 'settings':
        this.onSettingsPageLoaded();
        break;
    }
  }

  /**
   * 首页加载处理
   */
  onHomePageLoaded() {
    if (this.settings.autoGreeting && this.settings.showNotifications) {
      setTimeout(() => {
        this.api.showToast(this.settings.greetingMessage, 'info');
      }, 1000);
    }
  }

  /**
   * 示例页面加载处理
   */
  onExamplePageLoaded() {
    if (this.settings.showNotifications) {
      this.api.showToast('示例页面已加载，插件功能已激活', 'success');
    }
  }

  /**
   * 设置页面加载处理
   */
  onSettingsPageLoaded() {
    // 可以在设置页面添加插件相关的设置项
    if (this.settings.debugMode) {
      window.core.logDebug('Settings page loaded, plugin settings available', 'PLUGIN');
    }
  }

  /**
   * 示例页面显示事件处理
   * @param {Object} data 页面数据
   */
  onExamplePageShown(data) {
    if (this.settings.debugMode) {
      window.core.logDebug('Example page shown, enhancing with plugin features', 'PLUGIN');
    }
    
    // 为示例页面添加额外功能
    this.enhanceExamplePage(data.page);
  }

  /**
   * 示例页面清理事件处理
   * @param {Object} data 页面数据
   */
  onExamplePageCleanup(data) {
    if (this.settings.debugMode) {
      window.core.logDebug('Example page cleanup, removing plugin enhancements', 'PLUGIN');
    }
  }

  /**
   * 应用就绪事件处理
   */
  onAppReady() {
    if (this.settings.debugMode) {
      window.core.logDebug('App ready, plugin fully initialized', 'PLUGIN');
    }
  }

  /**
   * 增强示例页面功能
   * @param {Object} page 页面实例
   */
  enhanceExamplePage(page) {
    // 添加插件特定的功能到示例页面
    setTimeout(() => {
      const pluginSection = document.createElement('div');
      pluginSection.className = 'card plugin-enhancement';
      pluginSection.innerHTML = `
        <h3>🔌 插件增强功能</h3>
        <p>这个区域由示例插件动态添加</p>
        <div class="button-group">
          <button id="plugin-action-1" class="btn btn-primary">插件操作 1</button>
          <button id="plugin-action-2" class="btn btn-secondary">插件操作 2</button>
          <button id="plugin-batch-cmd" class="btn btn-info">批量命令</button>
        </div>
      `;
      
      const contentSection = document.querySelector('.content-section');
      if (contentSection) {
        contentSection.appendChild(pluginSection);
        
        // 添加插件按钮事件
        document.getElementById('plugin-action-1')?.addEventListener('click', () => {
          this.executePluginAction1();
        });
        
        document.getElementById('plugin-action-2')?.addEventListener('click', () => {
          this.executePluginAction2();
        });
        
        document.getElementById('plugin-batch-cmd')?.addEventListener('click', () => {
          this.executeBatchCommands();
        });
      }
    }, 500);
  }

  /**
   * 执行插件操作1
   */
  executePluginAction1() {
    this.stats.buttonsClicked++;
    this.saveStats();
    
    this.api.showToast('插件操作1已执行', 'success');
    
    // 模拟一些插件特定的操作
    if (this.settings.debugMode) {
      window.core.logDebug('Plugin action 1 executed', 'PLUGIN');
    }
  }

  /**
   * 执行插件操作2
   */
  async executePluginAction2() {
    this.stats.buttonsClicked++;
    this.saveStats();
    
    const confirmed = await this.api.showDialog.confirm(
      '插件操作确认',
      '这将执行插件的高级操作，是否继续？'
    );
    
    if (confirmed) {
      this.api.showToast('插件高级操作已执行', 'success');
      
      // 模拟高级操作
      setTimeout(() => {
        this.api.showToast('高级操作完成', 'info');
      }, 2000);
    }
  }

  /**
   * 执行批量命令
   */
  async executeBatchCommands() {
    this.stats.buttonsClicked++;
    this.stats.commandsExecuted++;
    this.saveStats();
    
    const commands = [
      'echo "插件批量命令 1"',
      'echo "插件批量命令 2"',
      'echo "插件批量命令 3"'
    ];
    
    this.api.showToast('开始执行批量命令...', 'info');
    
    for (let i = 0; i < commands.length; i++) {
      try {
        const result = await window.core.exec(commands[i]);
        if (result.success) {
          this.api.showToast(`命令 ${i + 1} 执行成功: ${result.stdout.trim()}`, 'success');
        } else {
          this.api.showToast(`命令 ${i + 1} 执行失败`, 'error');
        }
      } catch (error) {
        this.api.showToast(`命令 ${i + 1} 执行出错: ${error.message}`, 'error');
      }
      
      // 添加延迟避免过快执行
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    this.api.showToast('批量命令执行完成', 'success');
  }

  /**
   * 显示插件设置
   */
  async showPluginSettings() {
    const settingsHtml = `
      <div class="plugin-settings">
        <div class="setting-item">
          <label>
            <input type="checkbox" id="auto-greeting" ${this.settings.autoGreeting ? 'checked' : ''}>
            自动问候
          </label>
        </div>
        <div class="setting-item">
          <label>
            问候消息:
            <input type="text" id="greeting-message" value="${this.settings.greetingMessage}" style="width: 100%; margin-top: 5px;">
          </label>
        </div>
        <div class="setting-item">
          <label>
            <input type="checkbox" id="show-notifications" ${this.settings.showNotifications ? 'checked' : ''}>
            显示通知
          </label>
        </div>
        <div class="setting-item">
          <label>
            <input type="checkbox" id="debug-mode" ${this.settings.debugMode ? 'checked' : ''}>
            调试模式
          </label>
        </div>
      </div>
    `;
    
    await window.DialogManager.showGeneric({
      title: '插件设置',
      content: settingsHtml,
      buttons: [
        {
          text: '保存',
          action: () => {
            this.savePluginSettings();
            this.api.showToast('插件设置已保存', 'success');
          }
        },
        {
          text: '取消',
          action: () => {}
        }
      ],
      closable: true
    });
  }

  /**
   * 保存插件设置
   */
  savePluginSettings() {
    this.settings.autoGreeting = document.getElementById('auto-greeting')?.checked || false;
    this.settings.greetingMessage = document.getElementById('greeting-message')?.value || 'Welcome to Aurora Module!';
    this.settings.showNotifications = document.getElementById('show-notifications')?.checked || false;
    this.settings.debugMode = document.getElementById('debug-mode')?.checked || false;
    
    this.saveSettings();
  }

  /**
   * 显示使用统计
   */
  showStatistics() {
    const statsHtml = `
      <div class="plugin-stats">
        <h4>插件使用统计</h4>
        <div class="stat-item">
          <span class="stat-label">页面访问次数:</span>
          <span class="stat-value">${this.stats.pageVisits}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">按钮点击次数:</span>
          <span class="stat-value">${this.stats.buttonsClicked}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">命令执行次数:</span>
          <span class="stat-value">${this.stats.commandsExecuted}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">插件版本:</span>
          <span class="stat-value">${this.version}</span>
        </div>
      </div>
      <style>
        .plugin-stats { padding: 16px; }
        .stat-item { display: flex; justify-content: space-between; margin-bottom: 12px; padding: 8px; background: var(--md-sys-color-surface-variant); border-radius: 8px; }
        .stat-label { font-weight: 500; }
        .stat-value { color: var(--md-sys-color-primary); font-weight: 600; }
      </style>
    `;
    
    window.DialogManager.showGeneric({
      title: '使用统计',
      content: statsHtml,
      buttons: [
        {
          text: '重置统计',
          action: () => {
            this.resetStats();
            this.api.showToast('统计数据已重置', 'info');
          }
        },
        {
          text: '关闭',
          action: () => {}
        }
      ],
      closable: true
    });
  }

  /**
   * 显示快速操作
   */
  async showQuickActions() {
    const actions = [
      { text: '清理缓存', value: 'clear-cache' },
      { text: '重新加载配置', value: 'reload-config' },
      { text: '导出日志', value: 'export-logs' },
      { text: '系统信息', value: 'system-info' }
    ];
    
    const selected = await this.api.showDialog.list('选择快速操作', actions);
    
    if (selected) {
      this.executeQuickAction(selected);
    }
  }

  /**
   * 执行快速操作
   * @param {string} action 操作类型
   */
  async executeQuickAction(action) {
    this.stats.buttonsClicked++;
    this.saveStats();
    
    switch (action) {
      case 'clear-cache':
        this.api.showToast('缓存清理完成', 'success');
        break;
      case 'reload-config':
        this.api.showToast('配置重新加载完成', 'success');
        break;
      case 'export-logs':
        this.api.showToast('日志导出完成', 'success');
        break;
      case 'system-info':
        await this.showSystemInfo();
        break;
    }
  }

  /**
   * 显示系统信息
   */
  async showSystemInfo() {
    try {
      const result = await window.core.exec('uname -a');
      const systemInfo = result.success ? result.stdout : '无法获取系统信息';
      
      window.DialogManager.showGeneric({
        title: '系统信息',
        content: `<pre style="background: var(--md-sys-color-surface-variant); padding: 16px; border-radius: 8px; overflow-x: auto;">${systemInfo}</pre>`,
        buttons: [{ text: '关闭', action: () => {} }],
        closable: true
      });
    } catch (error) {
      this.api.showToast('获取系统信息失败', 'error');
    }
  }

  /**
   * 显示插件信息
   */
  showPluginInfo() {
    const infoHtml = `
      <div class="plugin-info">
        <h4>${this.name}</h4>
        <p><strong>版本:</strong> ${this.version}</p>
        <p><strong>描述:</strong> ${this.description}</p>
        <p><strong>状态:</strong> ${this.isEnabled ? '已启用' : '已禁用'}</p>
        <p><strong>功能特性:</strong></p>
        <ul>
          <li>页面增强功能</li>
          <li>事件监听和处理</li>
          <li>设置管理</li>
          <li>使用统计</li>
          <li>快速操作</li>
          <li>批量命令执行</li>
        </ul>
      </div>
    `;
    
    window.DialogManager.showGeneric({
      title: '插件信息',
      content: infoHtml,
      buttons: [{ text: '关闭', action: () => {} }],
      closable: true
    });
  }

  /**
   * 加载设置
   */
  loadSettings() {
    const savedSettings = this.api.getSetting('examplePlugin.settings');
    if (savedSettings) {
      this.settings = { ...this.settings, ...JSON.parse(savedSettings) };
    }
    
    const savedStats = this.api.getSetting('examplePlugin.stats');
    if (savedStats) {
      this.stats = { ...this.stats, ...JSON.parse(savedStats) };
    }
  }

  /**
   * 保存设置
   */
  saveSettings() {
    this.api.setSetting('examplePlugin.settings', JSON.stringify(this.settings));
  }

  /**
   * 保存统计数据
   */
  saveStats() {
    this.api.setSetting('examplePlugin.stats', JSON.stringify(this.stats));
  }

  /**
   * 重置统计数据
   */
  resetStats() {
    this.stats = {
      pageVisits: 0,
      buttonsClicked: 0,
      commandsExecuted: 0
    };
    this.saveStats();
  }
}

export default ExamplePlugin;