const express = require('express')
const bodyParser = require('body-parser')
const app = express()

app.use(bodyParser.json())
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Headers', 'Authorization, Content-Type')
  next()
})

const db = {
  overview: [
    { id: '1', title: '项目总览', desc: '当前项目总体进度' },
    { id: '2', title: '任务统计', desc: '各状态任务数量分布' }
  ],
  annotations: [
    { id: 'a1', tool: 'pen', content: { x: 100, y: 200 } },
    { id: 'a2', tool: 'text', content: { text: '重要标注', x: 150, y: 180 } }
  ],
  demoContent: [
    { step: 0, title: '欢迎', content: '欢迎使用本演示系统' },
    { step: 1, title: '功能展示', content: '主要功能特点介绍' }
  ]
}

// 认证模拟
app.post('/v1/auth', (req, res) => {
  res.json({ token: 'mock-token-' + Date.now() })
})

// 数据接口
app.get('/v1/overview-data', (req, res) => {
  res.json(db.overview)
})

app.get('/v1/annotations', (req, res) => {
  res.json(db.annotations)
})

app.post('/v1/annotations', (req, res) => {
  const newItem = { id: 'a' + (db.annotations.length + 1), ...req.body }
  db.annotations.push(newItem)
  res.json(newItem)
})

app.get('/v1/demo-content', (req, res) => {
  res.json(db.demoContent)
})

app.listen(3000, () => {
  console.log('Mock server running on http://localhost:3000')
})