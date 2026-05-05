import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'MERIDIAN Dashboard',
  description: 'Global Business Intelligence Platform - Real-time market data, currency analysis, and opportunity discovery.',
  keywords: ['business intelligence', 'currency', 'markets', 'opportunities', 'global'],
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#070D1A',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} font-sans antialiased bg-[#070D1A] text-white min-h-screen`}>
        {children}
      </body>
    </html>
  )
}
