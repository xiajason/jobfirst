
// components/FeatureBanner/FeatureBanner.js
Component({
  /**
   * 组件的属性列表
   */
  properties: {
    bannerList: {
      type: Array,
      value: []
    },
    height: {
      type: String,
      value: '150px'
    },
    autoplay: {
      type: Boolean,
      value: true
    },
    interval: {
      type: Number,
      value: 3000
    },
    duration: {
      type: Number,
      value: 500
    },
    indicatorDots: {
      type: Boolean,
      value: true
    },
    indicatorColor: {
      type: String,
      value: 'rgba(0, 0, 0, .3)'
    },
    indicatorActiveColor: {
      type: String,
      value: '#000000'
    }
  },

  /**
   * 组件的初始数据
   */
  data: {
    currentIndex: 0
  },

  /**
   * 组件的方法列表
   */
  methods: {
    onBannerTap(e) {
      const index = e.currentTarget.dataset.index;
      const item = this.data.bannerList[index];
      
      // 触发点击事件，传递被点击的banner数据
      this.triggerEvent('bannerclick', {
        index: index,
        item: item
      });
    },
    
    onSwiperChange(e) {
      this.setData({
        currentIndex: e.detail.current
      });
      
      // 触发切换事件
      this.triggerEvent('bannerchange', {
        index: e.detail.current,
        item: this.data.bannerList[e.detail.current]
      });
    }
  }
})