// pages/register/register.js
const app = getApp()

Page({
  data: {
    phone: '',
    code: '',
    password: '',
    confirmPassword: '',
    userType: 'jobseeker', // jobseeker, employer
    agreed: false,
    showPassword: false,
    codeBtnText: '获取验证码',
    codeBtnDisabled: false,
    registerBtnText: '注册',
    registerBtnDisabled: true,
    countdown: 60
  },

  onLoad() {
    // 如果已经登录，跳转到首页
    if (app.globalData.token) {
      this.redirectToHome()
    }
  },

  // 手机号输入
  onPhoneInput(e) {
    this.setData({
      phone: e.detail.value
    })
    this.checkFormValid()
  },

  // 验证码输入
  onCodeInput(e) {
    this.setData({
      code: e.detail.value
    })
    this.checkFormValid()
  },

  // 密码输入
  onPasswordInput(e) {
    this.setData({
      password: e.detail.value
    })
    this.checkFormValid()
  },

  // 确认密码输入
  onConfirmPasswordInput(e) {
    this.setData({
      confirmPassword: e.detail.value
    })
    this.checkFormValid()
  },

  // 选择用户类型
  selectUserType(e) {
    const type = e.currentTarget.dataset.type
    this.setData({
      userType: type
    })
  },

  // 协议勾选
  onAgreementChange(e) {
    this.setData({
      agreed: e.detail.value.length > 0
    })
    this.checkFormValid()
  },

  // 检查表单是否有效
  checkFormValid() {
    const { phone, code, password, confirmPassword, agreed } = this.data
    
    const phoneValid = this.validatePhone(phone)
    const codeValid = code.length === 6
    const passwordValid = password.length >= 6 && password.length <= 20
    const confirmValid = password === confirmPassword && confirmPassword.length > 0
    
    const isValid = phoneValid && codeValid && passwordValid && confirmValid && agreed
    
    this.setData({
      registerBtnDisabled: !isValid
    })
  },

  // 验证手机号
  validatePhone(phone) {
    const phoneReg = /^1[3-9]\d{9}$/
    return phoneReg.test(phone)
  },

  // 发送验证码
  async sendCode() {
    const { phone } = this.data
    
    if (!this.validatePhone(phone)) {
      app.showToast('请输入正确的手机号')
      return
    }

    try {
      this.setData({
        codeBtnDisabled: true,
        codeBtnText: '发送中...'
      })

      const res = await app.request({
        url: '/api/user/sendCode',
        method: 'POST',
        data: {
          phone,
          type: 'register'
        }
      })

      if (res.success) {
        app.showToast('验证码已发送')
        this.startCountdown()
      } else {
        app.showToast(res.message || '发送失败')
        this.setData({
          codeBtnDisabled: false,
          codeBtnText: '获取验证码'
        })
      }
    } catch (error) {
      console.error('发送验证码失败:', error)
      app.showToast('发送失败，请重试')
      this.setData({
        codeBtnDisabled: false,
        codeBtnText: '获取验证码'
      })
    }
  },

  // 开始倒计时
  startCountdown() {
    let countdown = this.data.countdown
    
    const timer = setInterval(() => {
      countdown--
      
      if (countdown <= 0) {
        clearInterval(timer)
        this.setData({
          codeBtnText: '获取验证码',
          codeBtnDisabled: false,
          countdown: 60
        })
      } else {
        this.setData({
          codeBtnText: `${countdown}s后重发`,
          countdown
        })
      }
    }, 1000)
  },

  // 注册
  async register() {
    const { phone, code, password, confirmPassword, userType, agreed } = this.data

    if (!agreed) {
      app.showToast('请先同意用户协议和隐私政策')
      return
    }

    if (password !== confirmPassword) {
      app.showToast('两次输入的密码不一致')
      return
    }

    try {
      this.setData({
        registerBtnText: '注册中...',
        registerBtnDisabled: true
      })

      const res = await app.request({
        url: '/api/user/register',
        method: 'POST',
        data: {
          phone,
          code,
          password,
          userType
        }
      })

      if (res.success) {
        app.showToast('注册成功')
        
        // 自动登录
        await app.login({
          phone,
          password
        })
        
        // 跳转到首页
        this.redirectToHome()
      } else {
        app.showToast(res.message || '注册失败')
        this.setData({
          registerBtnText: '注册',
          registerBtnDisabled: false
        })
      }
    } catch (error) {
      console.error('注册失败:', error)
      app.showToast('注册失败，请重试')
      this.setData({
        registerBtnText: '注册',
        registerBtnDisabled: false
      })
    }
  },

  // 微信注册
  async wechatRegister() {
    try {
      app.showLoading('注册中...')
      
      const res = await app.request({
        url: '/api/user/wechatRegister',
        method: 'POST'
      })

      if (res.success) {
        app.showToast('注册成功')
        this.redirectToHome()
      } else {
        app.showToast(res.message || '注册失败')
      }
    } catch (error) {
      console.error('微信注册失败:', error)
      app.showToast('注册失败，请重试')
    } finally {
      app.hideLoading()
    }
  },

  // QQ注册
  async qqRegister() {
    app.showToast('QQ注册功能开发中')
  },

  // 显示用户协议
  showAgreement() {
    wx.navigateTo({
      url: '/pages/agreement/agreement'
    })
  },

  // 显示隐私政策
  showPrivacy() {
    wx.navigateTo({
      url: '/pages/privacy/privacy'
    })
  },

  // 跳转到登录页
  goToLogin() {
    wx.navigateTo({
      url: '/pages/login/login'
    })
  },

  // 跳转到首页
  redirectToHome() {
    wx.switchTab({
      url: '/pages/index/index'
    })
  }
})
