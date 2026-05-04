'use client'

import { useState } from 'react'
import { Search, Globe, Shield, TrendingUp, AlertTriangle, CheckCircle, Loader2 } from 'lucide-react'
import ScoreRing from './ScoreRing'

interface ScanResult {
  domain: string
  registrar: string
  age: string
  trustScore: number
  trafficRank: string
  category: string
  flags: { type: 'safe' | 'warning' | 'alert'; message: string }[]
  technologies: string[]
  marketPresence: string
}

const MOCK_RESULTS: Record<string, ScanResult> = {
  default: {
    domain: '',
    registrar: 'NameCheap Inc.',
    age: '4 years, 7 months',
    trustScore: 82,
    trafficRank: '#14,203 globally',
    category: 'Financial Services',
    flags: [
      { type: 'safe', message: 'Valid SSL certificate (EV)' },
      { type: 'safe', message: 'DMARC policy enforced' },
      { type: 'warning', message: 'No CDN detected — latency risk' },
    ],
    technologies: ['React', 'Node.js', 'Cloudflare', 'PostgreSQL'],
    marketPresence: 'Strong in APAC, emerging in EMEA',
  },
}

function FlagIcon({ type }: { type: 'safe' | 'warning' | 'alert' }) {
  if (type === 'safe') return <CheckCircle className="w-3.5 h-3.5 text-[#00C896] flex-shrink-0" />
  if (type === 'warning') return <AlertTriangle className="w-3.5 h-3.5 text-[#F5A623] flex-shrink-0" />
  return <AlertTriangle className="w-3.5 h-3.5 text-[#FF4757] flex-shrink-0" />
}

const flagTextColour: Record<string, string> = {
  safe: 'text-white/60',
  warning: 'text-[#F5A623]/80',
  alert: 'text-[#FF4757]/80',
}

const RECENT_SCANS = [
  { domain: 'bloomberg.com', score: 94 },
  { domain: 'refinitiv.com', score: 88 },
  { domain: 'factset.com', score: 91 },
]

export default function DomainScanner() {
  const [query, setQuery] = useState('')
  const [scanning, setScanning] = useState(false)
  const [result, setResult] = useState<ScanResult | null>(null)
  const [scanned, setScanned] = useState(false)

  const handleScan = () => {
    if (!query.trim()) return

    setScanning(true)
    setResult(null)

    setTimeout(() => {
      const mockResult: ScanResult = {
        ...MOCK_RESULTS.default,
        domain: query.trim().replace(/^https?:\/\//, '').split('/')[0],
        trustScore: Math.floor(55 + Math.random() * 40),
      }
      setResult(mockResult)
      setScanning(false)
      setScanned(true)
    }, 1800)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleScan()
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Search input */}
      <div className="relative">
        <Globe className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#00D4FF]/60 pointer-events-none" />
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Enter domain or company name..."
          className="w-full pl-9 pr-24 py-2.5 rounded-xl bg-[rgba(10,37,64,0.5)] border border-[rgba(0,212,255,0.15)] text-sm text-white placeholder-white/30 focus:outline-none focus:border-[rgba(0,212,255,0.5)] focus:bg-[rgba(10,37,64,0.7)] transition-all duration-200"
        />
        <button
          onClick={handleScan}
          disabled={scanning || !query.trim()}
          className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#00D4FF] text-[#070D1A] text-xs font-bold hover:bg-[#00C4EF] transition-colors duration-200 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {scanning ? (
            <Loader2 className="w-3.5 h-3.5 animate-spin" />
          ) : (
            <Search className="w-3.5 h-3.5" />
          )}
          {scanning ? 'Scanning' : 'Analyse'}
        </button>
      </div>

      {/* Scanning indicator */}
      {scanning && (
        <div className="relative overflow-hidden rounded-xl glass-card p-4">
          <div className="scan-line absolute inset-x-0 h-0.5 bg-gradient-to-r from-transparent via-[#00D4FF] to-transparent top-0 pointer-events-none" />
          <div className="flex flex-col gap-2">
            {['Resolving DNS records...', 'Analysing SSL certificates...', 'Checking domain reputation...'].map(
              (step, i) => (
                <div key={i} className="flex items-center gap-2 text-[11px] text-white/50">
                  <Loader2 className="w-3 h-3 animate-spin text-[#00D4FF]" />
                  {step}
                </div>
              )
            )}
          </div>
        </div>
      )}

      {/* Scan result */}
      {result && !scanning && (
        <div className="rounded-xl glass-card p-4 animate-fade-in border border-[rgba(0,212,255,0.1)] glow-cyan">
          {/* Header */}
          <div className="flex items-start justify-between mb-3">
            <div>
              <h4 className="text-sm font-bold text-white">{result.domain}</h4>
              <p className="text-[11px] text-white/40 mt-0.5">{result.category}</p>
            </div>
            <ScoreRing score={result.trustScore} size={44} strokeWidth={3} />
          </div>

          {/* Stats row */}
          <div className="grid grid-cols-2 gap-2 mb-3">
            {[
              { label: 'Registrar', value: result.registrar },
              { label: 'Domain Age', value: result.age },
              { label: 'Traffic Rank', value: result.trafficRank },
              { label: 'Market', value: result.marketPresence },
            ].map(({ label, value }) => (
              <div key={label} className="rounded-lg bg-[rgba(255,255,255,0.03)] px-2.5 py-1.5">
                <p className="text-[10px] text-white/35 uppercase tracking-wider">{label}</p>
                <p className="text-[11px] font-semibold text-white/80 mt-0.5 leading-tight">{value}</p>
              </div>
            ))}
          </div>

          {/* Intelligence flags */}
          <div className="flex flex-col gap-1.5 mb-3">
            {result.flags.map((flag, i) => (
              <div key={i} className="flex items-center gap-2">
                <FlagIcon type={flag.type} />
                <span className={`text-[11px] ${flagTextColour[flag.type]}`}>{flag.message}</span>
              </div>
            ))}
          </div>

          {/* Technologies */}
          <div className="flex flex-wrap gap-1.5">
            {result.technologies.map((tech) => (
              <span
                key={tech}
                className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-[rgba(0,212,255,0.08)] text-[#00D4FF]/70 border border-[rgba(0,212,255,0.12)]"
              >
                {tech}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Recent scans */}
      <div>
        <p className="text-[10px] font-semibold text-white/30 uppercase tracking-widest mb-2">
          Recent Scans
        </p>
        <div className="flex flex-col gap-1.5">
          {RECENT_SCANS.map((scan) => (
            <button
              key={scan.domain}
              onClick={() => {
                setQuery(scan.domain)
              }}
              className="flex items-center justify-between px-3 py-2 rounded-lg bg-[rgba(255,255,255,0.025)] hover:bg-[rgba(0,212,255,0.05)] border border-transparent hover:border-[rgba(0,212,255,0.1)] transition-all duration-200 text-left group"
            >
              <div className="flex items-center gap-2">
                <Shield className="w-3.5 h-3.5 text-[#00D4FF]/40 group-hover:text-[#00D4FF]/70 transition-colors" />
                <span className="text-xs text-white/60 group-hover:text-white/80 transition-colors">
                  {scan.domain}
                </span>
              </div>
              <span
                className="text-[11px] font-bold"
                style={{
                  color: scan.score >= 80 ? '#00C896' : scan.score >= 60 ? '#F5A623' : '#FF4757',
                }}
              >
                {scan.score}
              </span>
            </button>
          ))}
        </div>
      </div>

      {!scanned && !scanning && (
        <div className="flex items-center gap-2 text-[11px] text-white/25 mt-auto">
          <TrendingUp className="w-3.5 h-3.5" />
          <span>Intelligence updated every 15 minutes</span>
        </div>
      )}
    </div>
  )
}
