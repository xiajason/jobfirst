Page({
  data: {},
  
  test() {
    wx.showToast({
      title: '测试完成',
      icon: 'success'
    })
  },
  
  back() {
    wx.switchTab({
      url: '/pages/index/index'
    })
  }
})
