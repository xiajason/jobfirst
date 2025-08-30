'use client';

import FileUpload from '@/components/common/file-upload';

export default function UploadResume() {
	return (
		<section className="relative flex h-screen items-center justify-center overflow-hidden p-2 bg-gradient-to-br from-blue-600 to-purple-700">
			<div className="relative z-10 flex h-full w-full flex-col items-center justify-center bg-zinc-950 p-8 rounded-2xl">
				<div className="w-full max-w-md mx-auto flex flex-col items-center gap-6">
					<h1 className="text-4xl font-bold text-center text-white mb-6">
						Upload Your Resume
					</h1>
					<p className="text-center text-gray-300 mb-8">
						Drag and drop your resume file below or click to browse. Supported formats: PDF,
						DOC, DOCX (Upto 2 MB).
					</p>
					<div className="w-full">
						<FileUpload />
					</div>
				</div>
			</div>
		</section>
	);
}
