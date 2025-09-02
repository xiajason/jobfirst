'use client';

import React from 'react';
import Link from 'next/link';
import { useMode } from '@/components/common/ModeProvider';
import { FeatureGate } from '@/components/common/FeatureGate';

export default function HeroSimple() {
	const { currentMode, modeConfig, hasFeature } = useMode();

	return (
		<section className="relative flex h-screen items-center justify-center overflow-hidden p-2 bg-gradient-to-br from-blue-600 to-purple-700">
			<div className="relative z-10 flex h-full w-full flex-col items-center justify-center bg-zinc-950 p-8 rounded-2xl">
				<div className="relative z-10 w-full h-full flex flex-col items-center justify-center">
					<div className="relative mb-4 h-[30vh] w-full">
						<h1 className="text-center text-6xl font-semibold text-white mb-8">
							JobFirst
						</h1>
						<div className="text-center mb-4">
							<span className="inline-block px-3 py-1 text-sm font-medium text-blue-600 bg-blue-100 rounded-full">
								{modeConfig.name}
							</span>
						</div>
					</div>
					<p className="mb-8 text-center text-lg text-gray-300 md:text-xl max-w-2xl">
						基于AI的智能求职平台，支持多模式部署
					</p>
					
					{/* 模式特性展示 */}
					<div className="mb-8 w-full max-w-4xl">
						<div className="grid grid-cols-1 md:grid-cols-3 gap-4">
							{/* 基础功能 */}
							<div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
								<h3 className="text-white font-semibold mb-2">基础功能</h3>
								<ul className="text-gray-300 text-sm space-y-1">
									<li>✓ 用户注册登录</li>
									<li>✓ 基础简历管理</li>
									<li>✓ 职位搜索</li>
								</ul>
							</div>
							
							{/* 增强功能 */}
							<FeatureGate feature="AI简历优化">
								<div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
									<h3 className="text-white font-semibold mb-2">增强功能</h3>
									<ul className="text-gray-300 text-sm space-y-1">
										<li>✓ AI简历优化</li>
										<li>✓ 智能职位推荐</li>
										<li>✓ 积分系统</li>
									</ul>
								</div>
							</FeatureGate>
							
							{/* 专业功能 */}
							<FeatureGate feature="企业级管理">
								<div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
									<h3 className="text-white font-semibold mb-2">专业功能</h3>
									<ul className="text-gray-300 text-sm space-y-1">
										<li>✓ 企业级管理</li>
										<li>✓ 团队协作</li>
										<li>✓ API集成</li>
									</ul>
								</div>
							</FeatureGate>
						</div>
					</div>
					
					<div className="flex flex-col sm:flex-row gap-4">
						<Link
							href="/dashboard"
							className="inline-flex h-12 items-center justify-center rounded-full bg-blue-600 px-8 py-3 text-base font-medium text-white hover:bg-blue-700 transition-colors"
						>
							开始使用
							<svg
								width="16"
								height="16"
								viewBox="0 0 0.3 0.3"
								fill="#FFF"
								xmlns="http://www.w3.org/2000/svg"
								className="ml-2"
							>
								<path d="M.166.046a.02.02 0 0 1 .028 0l.09.09a.02.02 0 0 1 0 .028l-.09.09A.02.02 0 0 1 .166.226L.22.17H.03a.02.02 0 0 1 0-.04h.19L.166.074a.02.02 0 0 1 0-.028" />
							</svg>
						</Link>
						
						{/* 升级按钮 - 仅在非专业版显示 */}
						{currentMode !== 'pro' && (
							<Link
								href="/upgrade"
								className="inline-flex h-12 items-center justify-center rounded-full border-2 border-white/30 px-8 py-3 text-base font-medium text-white hover:bg-white/10 transition-colors"
							>
								升级版本
							</Link>
						)}
					</div>
					
					{/* 当前模式信息 */}
					<div className="mt-8 text-center">
						<p className="text-gray-400 text-sm">
							当前模式: {modeConfig.name} | 
							价格: {modeConfig.price === 0 ? '免费' : `¥${modeConfig.price}/月`} | 
							最大用户数: {modeConfig.maxUsers?.toLocaleString()}
						</p>
					</div>
				</div>
			</div>
		</section>
	);
}
