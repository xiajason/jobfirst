import React from 'react';
import Link from 'next/link';

export default function HeroSimple() {
	return (
		<section className="relative flex h-screen items-center justify-center overflow-hidden p-2 bg-gradient-to-br from-blue-600 to-purple-700">
			<div className="relative z-10 flex h-full w-full flex-col items-center justify-center bg-zinc-950 p-8 rounded-2xl">
				<div className="relative z-10 w-full h-full flex flex-col items-center justify-center">
					<div className="relative mb-4 h-[30vh] w-full">
											<h1 className="text-center text-6xl font-semibold text-white mb-8">
						Smart Job
					</h1>
					</div>
					<p className="mb-12 text-center text-lg text-gray-300 md:text-xl">
						Increase your interview chances with a perfectly tailored resume.
					</p>
					<Link
						href="/resume"
						className="inline-flex h-10 items-center justify-center rounded-full bg-blue-600 px-6 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
					>
						Get Started
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
				</div>
			</div>
		</section>
	);
}
