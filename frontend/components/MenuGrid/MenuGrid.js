
// components/MenuGrid/MenuGrid.js
Component({
  /**
   * 组件的属性列表
   */
  properties: {
    menuList: {
      type: Array,
      value: []
    },
    columns: {
      type: Number,
      value: 4
    },
    showBorder: {
      type: Boolean,
      value: true
    },
    backgroundColor: {
      type: String,
      value: '#ffffff'
    },
    iconSize: {
      type: String,
      value: '60rpx'
    },
    textColor: {
      type: String,
      value: '#333333'
    },
    textSize: {
      type: String,
      value: '24rpx'
    }
  },

  /**
   * 组件的初始数据
   */
  data: {
    gridStyle: ''
  },

  /**
   * 组件的生命周期
   */
  lifetimes: {
    attached: function() {
      // 计算每个网格项的宽度
      const width = 100 / this.data.columns;
      this.setData({
        gridStyle: `width: ${width}%;`
      });
    }
  },

  /**
   * 组件的方法列表
   */
  methods: {
    onMenuItemTap: function(e) {
      const index = e.currentTarget.dataset.index;
      const item = this.data.menuList[index];
      
      // 触发点击事件，传递被点击的菜单项数据
      this.triggerEvent('menuitemclick', {
        index: index,
        item: item
      });
    }
  }
})