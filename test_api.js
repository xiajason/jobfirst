// 测试API连接
const testAPIs = async () => {
  console.log('开始测试API连接...')
  
  const baseUrl = 'http://localhost:8080'
  const headers = {
    'Content-Type': 'application/json',
    'API-Version': 'v2'
  }
  
  try {
    // 测试职位API
    console.log('测试职位API...')
    const jobsResponse = await fetch(`${baseUrl}/api/v2/jobs/`, {
      method: 'GET',
      headers
    })
    const jobsData = await jobsResponse.json()
    console.log('职位API响应:', jobsData)
    
    // 测试轮播图API
    console.log('测试轮播图API...')
    const bannersResponse = await fetch(`${baseUrl}/api/v2/banners/`, {
      method: 'GET',
      headers
    })
    const bannersData = await bannersResponse.json()
    console.log('轮播图API响应:', bannersData)
    
    // 测试企业API
    console.log('测试企业API...')
    const companiesResponse = await fetch(`${baseUrl}/api/v2/companies/`, {
      method: 'GET',
      headers
    })
    const companiesData = await companiesResponse.json()
    console.log('企业API响应:', companiesData)
    
    console.log('所有API测试完成！')
    
  } catch (error) {
    console.error('API测试失败:', error)
  }
}

// 运行测试
testAPIs()
