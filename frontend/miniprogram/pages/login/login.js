// login.js
const app = getApp()

Page({
  data: {
    phone: '',
    code: '',
    password: '',
    showPassword: false,
    codeBtnText: '获取验证码',
    codeBtnDisabled: false,
    loginBtnText: '登录',
    loginBtnDisabled: true,
    countdown: 60
  },

  onLoad() {
    // 检查是否已登录
    if (app.globalData.token) {
      this.redirectToHome()
    }
  },

  // 手机号输入
  onPhoneInput(e) {
    const phone = e.detail.value
    this.setData({ phone })
    this.checkFormValid()
  },

  // 验证码输入
  onCodeInput(e) {
    const code = e.detail.value
    this.setData({ code })
    this.checkFormValid()
  },

  // 密码输入
  onPasswordInput(e) {
    const password = e.detail.value
    this.setData({ password })
    this.checkFormValid()
  },

  // 检查表单有效性
  checkFormValid() {
    const { phone, code, password, showPassword } = this.data
    let isValid = false

    if (showPassword) {
      // 密码登录模式
      isValid = this.validatePhone(phone) && password.length >= 6
    } else {
      // 验证码登录模式
      isValid = this.validatePhone(phone) && code.length === 6
    }

    this.setData({
      loginBtnDisabled: !isValid
    })
  },

  // 验证手机号
  validatePhone(phone) {
    const phoneRegex = /^1[3-9]\d{9}$/
    return phoneRegex.test(phone)
  },

  // 发送验证码
  async sendCode() {
    const { phone } = this.data
    
    if (!this.validatePhone(phone)) {
      app.showToast('请输入正确的手机号')
      return
    }

    try {
      app.showLoading('发送中...')
      
      const res = await app.request({
        url: '/auth/send-code',
        method: 'POST',
        data: { phone }
      })

      if (res.code === 200) {
        app.showToast('验证码已发送', 'success')
        this.startCountdown()
      } else {
        app.showToast(res.message || '发送失败')
      }
    } catch (error) {
      console.error('发送验证码失败:', error)
      app.showToast('发送失败，请重试')
    } finally {
      app.hideLoading()
    }
  },

  // 开始倒计时
  startCountdown() {
    this.setData({
      codeBtnDisabled: true,
      codeBtnText: `${this.data.countdown}s后重发`
    })

    const timer = setInterval(() => {
      const countdown = this.data.countdown - 1
      
      if (countdown <= 0) {
        clearInterval(timer)
        this.setData({
          codeBtnDisabled: false,
          codeBtnText: '获取验证码',
          countdown: 60
        })
      } else {
        this.setData({
          countdown,
          codeBtnText: `${countdown}s后重发`
        })
      }
    }, 1000)
  },

  // 切换登录模式
  toggleLoginMode() {
    this.setData({
      showPassword: !this.data.showPassword,
      code: '',
      password: ''
    })
    this.checkFormValid()
  },

  // 登录
  async login() {
    const { phone, code, password, showPassword } = this.data

    if (!this.validatePhone(phone)) {
      app.showToast('请输入正确的手机号')
      return
    }

    try {
      app.showLoading('登录中...')
      this.setData({ loginBtnText: '登录中...' })

      let loginData = { phone }
      
      if (showPassword) {
        // 密码登录
        if (password.length < 6) {
          app.showToast('密码至少6位')
          return
        }
        loginData.password = password
      } else {
        // 验证码登录
        if (code.length !== 6) {
          app.showToast('请输入6位验证码')
          return
        }
        loginData.code = code
      }

      const res = await app.request({
        url: '/auth/login',
        method: 'POST',
        data: loginData
      })

      if (res.code === 200) {
        // 登录成功
        app.login(res.data.userInfo, res.data.token)
        app.showToast('登录成功', 'success')
        
        // 延迟跳转，让用户看到成功提示
        setTimeout(() => {
          this.redirectToHome()
        }, 1000)
      } else {
        app.showToast(res.message || '登录失败')
      }
    } catch (error) {
      console.error('登录失败:', error)
      app.showToast('登录失败，请重试')
    } finally {
      app.hideLoading()
      this.setData({ loginBtnText: '登录' })
    }
  },

  // 微信登录
  async wechatLogin() {
    try {
      app.showLoading('登录中...')
      
      // 获取微信登录凭证
      const loginRes = await wx.login()
      
      if (loginRes.code) {
        const res = await app.request({
          url: '/auth/wechat-login',
          method: 'POST',
          data: { code: loginRes.code }
        })

        if (res.code === 200) {
          app.login(res.data.userInfo, res.data.token)
          app.showToast('登录成功', 'success')
          
          setTimeout(() => {
            this.redirectToHome()
          }, 1000)
        } else {
          app.showToast(res.message || '登录失败')
        }
      } else {
        app.showToast('微信登录失败')
      }
    } catch (error) {
      console.error('微信登录失败:', error)
      app.showToast('登录失败，请重试')
    } finally {
      app.hideLoading()
    }
  },

  // QQ登录
  async qqLogin() {
    app.showToast('QQ登录功能开发中')
  },

  // 跳转到首页
  redirectToHome() {
    wx.switchTab({
      url: '/pages/index/index'
    })
  },

  // 跳转到注册页
  goToRegister() {
    wx.navigateTo({
      url: '/pages/register/register'
    })
  },

  // 跳转到用户协议
  goToAgreement() {
    wx.navigateTo({
      url: '/pages/agreement/agreement'
    })
  },

  // 跳转到隐私政策
  goToPrivacy() {
    wx.navigateTo({
      url: '/pages/privacy/privacy'
    })
  }
})
