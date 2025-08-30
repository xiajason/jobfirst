// components/job-card/job-card.js
Component({
  /**
   * 组件的属性列表
   */
  properties: {
    job: {
      type: Object,
      value: {}
    }
  },

  /**
   * 组件的初始数据
   */
  data: {

  },

  /**
   * 组件的方法列表
   */
  methods: {
    // 卡片点击事件
    onCardTap() {
      this.triggerEvent('cardtap', { job: this.data.job })
    },

    // 收藏点击事件
    onFavoriteTap() {
      this.triggerEvent('favoritetap', { job: this.data.job })
    },

    // 投递点击事件
    onApplyTap() {
      this.triggerEvent('applytap', { job: this.data.job })
    }
  }
})
