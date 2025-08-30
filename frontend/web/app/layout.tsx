import type { Metadata } from 'next';
import { Geist, Space_Grotesk } from 'next/font/google';
import './(default)/css/globals.css';

const spaceGrotesk = Space_Grotesk({
  variable: '--font-space-grotesk',
  subsets: ['latin'],
  display: 'swap',
});

const geist = Geist({
  variable: '--font-geist',
  subsets: ['latin'],
  display: 'swap',
});

export const metadata: Metadata = {
  	title: 'Smart Job',
	description: 'Build your resume with Smart Job',
	applicationName: 'Smart Job',
  keywords: ['resume', 'matcher', 'job', 'application'],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en-US">
      <body
        className={`${geist.variable} ${spaceGrotesk.variable} antialiased bg-white text-gray-900`}
      >
        <div>{children}</div>
      </body>
    </html>
  );
}
