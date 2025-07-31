/**
 * 示例页面模块
 * 展示如何创建自定义页面
 */
class ExamplePage {
  constructor() {
    // 初始化页面数据
    this.data = {
      items: [],
      loading: false,
      counter: 0
    };
    
    // 事件监听器数组（用于清理）
    this.eventListeners = [];
    
    // 页面状态
    this.isInitialized = false;
  }

  /**
   * 渲染页面HTML
   * @returns {string} 页面HTML内容
   */
  async render() {
    return `
      <div class="example-page">
        <div class="page-header">
          <h2>${window.i18n.t('examplePage.title')}</h2>
          <p class="page-description">${window.i18n.t('examplePage.description')}</p>
        </div>
        
        <div class="content-section">
          <div class="card">
            <h3>${window.i18n.t('examplePage.counter.title')}</h3>
            <div class="counter-display">
              <span id="counter-value">${this.data.counter}</span>
            </div>
            <div class="button-group">
              <button id="increment-btn" class="btn btn-primary">
                ${window.i18n.t('examplePage.counter.increment')}
              </button>
              <button id="decrement-btn" class="btn btn-secondary">
                ${window.i18n.t('examplePage.counter.decrement')}
              </button>
              <button id="reset-btn" class="btn btn-outline">
                ${window.i18n.t('examplePage.counter.reset')}
              </button>
            </div>
          </div>
          
          <div class="card">
            <h3>${window.i18n.t('examplePage.actions.title')}</h3>
            <div class="button-group">
              <button id="toast-btn" class="btn btn-info">
                ${window.i18n.t('examplePage.actions.showToast')}
              </button>
              <button id="dialog-btn" class="btn btn-warning">
                ${window.i18n.t('examplePage.actions.showDialog')}
              </button>
              <button id="command-btn" class="btn btn-success">
                ${window.i18n.t('examplePage.actions.execCommand')}
              </button>
            </div>
          </div>
          
          <div class="card">
            <h3>${window.i18n.t('examplePage.list.title')}</h3>
            <div id="item-list" class="item-list">
              ${this.renderItemList()}
            </div>
            <button id="add-item-btn" class="btn btn-primary">
              ${window.i18n.t('examplePage.list.addItem')}
            </button>
          </div>
        </div>
      </div>
    `;
  }

  /**
   * 渲染项目列表
   * @returns {string} 列表HTML
   */
  renderItemList() {
    if (this.data.items.length === 0) {
      return `<p class="empty-message">${window.i18n.t('examplePage.list.empty')}</p>`;
    }
    
    return this.data.items.map((item, index) => `
      <div class="list-item" data-index="${index}">
        <span class="item-text">${item.text}</span>
        <span class="item-time">${item.time}</span>
        <button class="btn btn-small btn-danger remove-item" data-index="${index}">
          ${window.i18n.t('examplePage.list.remove')}
        </button>
      </div>
    `).join('');
  }

  /**
   * 页面显示时调用
   */
  async onShow() {
    window.core.logDebug('Example page shown', 'PAGE');
    
    // 添加事件监听器
    this.addEventListeners();
    
    // 触发自定义事件供插件监听
    if (window.app.pluginManager) {
      await window.app.pluginManager.triggerHook('example-page:shown', {
        page: this,
        data: this.data
      });
    }
    
    this.isInitialized = true;
  }

  /**
   * 添加事件监听器
   */
  addEventListeners() {
    // 计数器按钮
    const incrementBtn = document.getElementById('increment-btn');
    const decrementBtn = document.getElementById('decrement-btn');
    const resetBtn = document.getElementById('reset-btn');
    
    if (incrementBtn) {
      const incrementHandler = () => this.incrementCounter();
      incrementBtn.addEventListener('click', incrementHandler);
      this.eventListeners.push({ element: incrementBtn, event: 'click', handler: incrementHandler });
    }
    
    if (decrementBtn) {
      const decrementHandler = () => this.decrementCounter();
      decrementBtn.addEventListener('click', decrementHandler);
      this.eventListeners.push({ element: decrementBtn, event: 'click', handler: decrementHandler });
    }
    
    if (resetBtn) {
      const resetHandler = () => this.resetCounter();
      resetBtn.addEventListener('click', resetHandler);
      this.eventListeners.push({ element: resetBtn, event: 'click', handler: resetHandler });
    }
    
    // 操作按钮
    const toastBtn = document.getElementById('toast-btn');
    const dialogBtn = document.getElementById('dialog-btn');
    const commandBtn = document.getElementById('command-btn');
    
    if (toastBtn) {
      const toastHandler = () => this.showToastExample();
      toastBtn.addEventListener('click', toastHandler);
      this.eventListeners.push({ element: toastBtn, event: 'click', handler: toastHandler });
    }
    
    if (dialogBtn) {
      const dialogHandler = () => this.showDialogExample();
      dialogBtn.addEventListener('click', dialogHandler);
      this.eventListeners.push({ element: dialogBtn, event: 'click', handler: dialogHandler });
    }
    
    if (commandBtn) {
      const commandHandler = () => this.execCommandExample();
      commandBtn.addEventListener('click', commandHandler);
      this.eventListeners.push({ element: commandBtn, event: 'click', handler: commandHandler });
    }
    
    // 列表按钮
    const addItemBtn = document.getElementById('add-item-btn');
    if (addItemBtn) {
      const addItemHandler = () => this.addItem();
      addItemBtn.addEventListener('click', addItemHandler);
      this.eventListeners.push({ element: addItemBtn, event: 'click', handler: addItemHandler });
    }
    
    // 删除按钮事件委托
    const itemList = document.getElementById('item-list');
    if (itemList) {
      const removeHandler = (e) => {
        if (e.target.classList.contains('remove-item')) {
          const index = parseInt(e.target.dataset.index);
          this.removeItem(index);
        }
      };
      itemList.addEventListener('click', removeHandler);
      this.eventListeners.push({ element: itemList, event: 'click', handler: removeHandler });
    }
  }

  /**
   * 增加计数器
   */
  incrementCounter() {
    this.data.counter++;
    this.updateCounterDisplay();
    window.core.showToast(window.i18n.t('examplePage.counter.incremented', { count: this.data.counter }), 'success');
  }

  /**
   * 减少计数器
   */
  decrementCounter() {
    this.data.counter--;
    this.updateCounterDisplay();
    window.core.showToast(window.i18n.t('examplePage.counter.decremented', { count: this.data.counter }), 'info');
  }

  /**
   * 重置计数器
   */
  resetCounter() {
    this.data.counter = 0;
    this.updateCounterDisplay();
    window.core.showToast(window.i18n.t('examplePage.counter.resetted'), 'warning');
  }

  /**
   * 更新计数器显示
   */
  updateCounterDisplay() {
    const counterValue = document.getElementById('counter-value');
    if (counterValue) {
      counterValue.textContent = this.data.counter;
    }
  }

  /**
   * 显示Toast示例
   */
  showToastExample() {
    const messages = [
      { text: window.i18n.t('examplePage.toast.success'), type: 'success' },
      { text: window.i18n.t('examplePage.toast.info'), type: 'info' },
      { text: window.i18n.t('examplePage.toast.warning'), type: 'warning' },
      { text: window.i18n.t('examplePage.toast.error'), type: 'error' }
    ];
    
    const randomMessage = messages[Math.floor(Math.random() * messages.length)];
    window.core.showToast(randomMessage.text, randomMessage.type);
  }

  /**
   * 显示对话框示例
   */
  async showDialogExample() {
    const confirmed = await window.DialogManager.showConfirm(
      window.i18n.t('examplePage.dialog.confirmTitle'),
      window.i18n.t('examplePage.dialog.confirmMessage')
    );
    
    if (confirmed) {
      const userInput = await window.DialogManager.showInput(
        window.i18n.t('examplePage.dialog.inputTitle'),
        window.i18n.t('examplePage.dialog.inputMessage'),
        window.i18n.t('examplePage.dialog.inputPlaceholder'),
        'Hello World'
      );
      
      if (userInput) {
        window.core.showToast(window.i18n.t('examplePage.dialog.inputReceived', { input: userInput }), 'success');
      }
    }
  }

  /**
   * 执行命令示例
   */
  async execCommandExample() {
    try {
      window.core.showToast(window.i18n.t('examplePage.command.executing'), 'info');
      
      const result = await window.core.exec('echo "Hello from Aurora Module!"');
      
      if (result.success) {
        window.core.showToast(window.i18n.t('examplePage.command.success', { output: result.stdout.trim() }), 'success');
      } else {
        window.core.showError(window.i18n.t('examplePage.command.failed'), result.stderr);
      }
    } catch (error) {
      window.core.showError(window.i18n.t('examplePage.command.error'), error.message);
    }
  }

  /**
   * 添加列表项
   */
  async addItem() {
    const itemText = await window.DialogManager.showInput(
      window.i18n.t('examplePage.list.addTitle'),
      window.i18n.t('examplePage.list.addMessage'),
      window.i18n.t('examplePage.list.addPlaceholder')
    );
    
    if (itemText && itemText.trim()) {
      const newItem = {
        text: itemText.trim(),
        time: new Date().toLocaleTimeString()
      };
      
      this.data.items.push(newItem);
      this.updateItemList();
      window.core.showToast(window.i18n.t('examplePage.list.itemAdded'), 'success');
    }
  }

  /**
   * 删除列表项
   * @param {number} index 项目索引
   */
  removeItem(index) {
    if (index >= 0 && index < this.data.items.length) {
      this.data.items.splice(index, 1);
      this.updateItemList();
      window.core.showToast(window.i18n.t('examplePage.list.itemRemoved'), 'info');
    }
  }

  /**
   * 更新列表显示
   */
  updateItemList() {
    const itemList = document.getElementById('item-list');
    if (itemList) {
      itemList.innerHTML = this.renderItemList();
    }
  }

  /**
   * 获取页面操作按钮
   * @returns {Array} 操作按钮配置
   */
  getPageActions() {
    return [
      {
        icon: 'refresh',
        title: window.i18n.t('examplePage.actions.refresh'),
        action: () => {
          this.data.items = [];
          this.data.counter = 0;
          this.updateCounterDisplay();
          this.updateItemList();
          window.core.showToast(window.i18n.t('examplePage.actions.refreshed'), 'success');
        }
      },
      {
        icon: 'info',
        title: window.i18n.t('examplePage.actions.about'),
        action: () => {
          window.DialogManager.showGeneric({
            title: window.i18n.t('examplePage.about.title'),
            content: `
              <div class="about-content">
                <p>${window.i18n.t('examplePage.about.description')}</p>
                <ul>
                  <li>${window.i18n.t('examplePage.about.feature1')}</li>
                  <li>${window.i18n.t('examplePage.about.feature2')}</li>
                  <li>${window.i18n.t('examplePage.about.feature3')}</li>
                  <li>${window.i18n.t('examplePage.about.feature4')}</li>
                </ul>
              </div>
            `,
            buttons: [
              { 
                text: window.i18n.t('common.close'), 
                action: () => {} 
              }
            ],
            closable: true
          });
        }
      }
    ];
  }

  /**
   * 页面清理
   */
  cleanup() {
    window.core.logDebug('Example page cleanup', 'PAGE');
    
    // 清理事件监听器
    this.eventListeners.forEach(({ element, event, handler }) => {
      if (element && element.removeEventListener) {
        element.removeEventListener(event, handler);
      }
    });
    this.eventListeners = [];
    
    // 触发清理事件
    if (window.app.pluginManager) {
      window.app.pluginManager.triggerHook('example-page:cleanup', {
        page: this
      });
    }
    
    this.isInitialized = false;
  }
}

export { ExamplePage };