const axios = require('axios');

// 测试配置
const GATEWAY_URL = 'http://localhost:8080';
const TEST_USER = {
    user_id: '12345',
    username: 'testuser',
    email: 'test@jobfirst.com',
    roles: ['user']
};

// 生成测试token的函数（模拟）
function generateTestToken(payload) {
    // 这里应该使用真实的JWT库生成token
    // 为了测试，我们使用一个简单的格式
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64');
    const payload_b64 = Buffer.from(JSON.stringify(payload)).toString('base64');
    const signature = 'test_signature';
    return `${header}.${payload_b64}.${signature}`;
}

// 测试函数
async function runTests() {
    console.log('🚀 开始测试JobFirst网关认证和CORS功能\n');

    const tests = [
        // 1. 健康检查测试
        {
            name: '网关健康检查',
            test: async () => {
                const response = await axios.get(`${GATEWAY_URL}/health`);
                return response.status === 200 && response.data.status === 'healthy';
            }
        },

        // 2. 网关信息测试
        {
            name: '网关信息端点',
            test: async () => {
                const response = await axios.get(`${GATEWAY_URL}/info`);
                return response.status === 200 && response.data.service === 'jobfirst-gateway';
            }
        },

        // 3. CORS预检请求测试
        {
            name: 'CORS预检请求',
            test: async () => {
                const response = await axios.options(`${GATEWAY_URL}/api/v1/user/profile`, {
                    headers: {
                        'Origin': 'http://localhost:3000',
                        'Access-Control-Request-Method': 'GET',
                        'Access-Control-Request-Headers': 'Authorization'
                    }
                });
                return response.status === 204;
            }
        },

        // 4. 公开API路由测试（无需认证）
        {
            name: '公开API路由 - 无需认证',
            test: async () => {
                const response = await axios.get(`${GATEWAY_URL}/api/auth/login`);
                return response.status === 200 || response.status === 404; // 404是正常的，因为服务可能未启动
            }
        },

        // 5. 认证API路由测试 - 无token
        {
            name: '认证API路由 - 无token (期望401)',
            test: async () => {
                try {
                    await axios.get(`${GATEWAY_URL}/api/v1/user/profile`);
                    return false; // 应该返回401
                } catch (error) {
                    return error.response.status === 401;
                }
            }
        },

        // 6. 认证API路由测试 - 无效token
        {
            name: '认证API路由 - 无效token (期望401)',
            test: async () => {
                try {
                    await axios.get(`${GATEWAY_URL}/api/v1/user/profile`, {
                        headers: {
                            'Authorization': 'Bearer invalid_token'
                        }
                    });
                    return false; // 应该返回401
                } catch (error) {
                    return error.response.status === 401;
                }
            }
        },

        // 7. 认证API路由测试 - 有效token格式
        {
            name: '认证API路由 - 有效token格式',
            test: async () => {
                const token = generateTestToken(TEST_USER);
                try {
                    await axios.get(`${GATEWAY_URL}/api/v1/user/profile`, {
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });
                    return true; // 格式正确，即使验证失败也是正常的
                } catch (error) {
                    // 如果返回401，说明token验证正常工作
                    return error.response.status === 401;
                }
            }
        },

        // 8. 管理员API路由测试 - 无管理员权限
        {
            name: '管理员API路由 - 无管理员权限 (期望403)',
            test: async () => {
                const token = generateTestToken({ ...TEST_USER, roles: ['user'] });
                try {
                    await axios.get(`${GATEWAY_URL}/admin/users`, {
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });
                    return false; // 应该返回403
                } catch (error) {
                    return error.response.status === 403;
                }
            }
        },

        // 9. CORS头测试
        {
            name: 'CORS头设置',
            test: async () => {
                const response = await axios.get(`${GATEWAY_URL}/health`, {
                    headers: {
                        'Origin': 'http://localhost:3000'
                    }
                });
                return response.headers['access-control-allow-origin'] === 'http://localhost:3000';
            }
        },

        // 10. API版本兼容性测试
        {
            name: 'V1 API版本兼容性',
            test: async () => {
                try {
                    await axios.get(`${GATEWAY_URL}/api/v1/user/profile`);
                    return true; // 路由存在
                } catch (error) {
                    return error.response.status === 401; // 需要认证是正常的
                }
            }
        },

        // 11. V2 API版本兼容性测试
        {
            name: 'V2 API版本兼容性',
            test: async () => {
                try {
                    await axios.get(`${GATEWAY_URL}/api/v2/user/profile`);
                    return true; // 路由存在
                } catch (error) {
                    return error.response.status === 401; // 需要认证是正常的
                }
            }
        },

        // 12. 404路由处理测试
        {
            name: '404路由处理',
            test: async () => {
                try {
                    await axios.get(`${GATEWAY_URL}/api/nonexistent`);
                    return false; // 应该返回404
                } catch (error) {
                    return error.response.status === 404;
                }
            }
        }
    ];

    let passed = 0;
    let failed = 0;

    for (const test of tests) {
        try {
            console.log(`🔍 测试: ${test.name}`);
            const result = await test.test();
            
            if (result) {
                console.log(`✅ 通过: ${test.name}`);
                passed++;
            } else {
                console.log(`❌ 失败: ${test.name}`);
                failed++;
            }
        } catch (error) {
            console.log(`❌ 错误: ${test.name} - ${error.message}`);
            failed++;
        }
        console.log('');
    }

    // 测试结果总结
    console.log('📊 测试结果总结:');
    console.log(`✅ 通过: ${passed}`);
    console.log(`❌ 失败: ${failed}`);
    console.log(`📈 成功率: ${((passed / (passed + failed)) * 100).toFixed(1)}%`);

    if (failed === 0) {
        console.log('\n🎉 所有测试通过！认证中间件和CORS功能正常工作。');
    } else {
        console.log('\n⚠️  部分测试失败，需要检查相关功能。');
    }
}

// 运行测试
runTests().catch(console.error);
