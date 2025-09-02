import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { ModeProvider } from '@/components/common/ModeProvider';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'JobFirst - 智能求职平台',
  description: '基于AI的智能求职平台，支持多模式部署',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh-CN">
      <body className={inter.className}>
        <ModeProvider>
          {children}
        </ModeProvider>
      </body>
    </html>
  );
}
