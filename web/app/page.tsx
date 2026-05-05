import { Bell, BellRing, BarChart3, Globe2, Zap, Activity, ArrowUpRight, ToggleLeft, ToggleRight } from 'lucide-react'
import CurrencyTicker, { CurrencyPair } from './components/CurrencyTicker'
import OpportunityCard, { Opportunity } from './components/OpportunityCard'
import DomainScanner from './components/DomainScanner'

// Mock currency pairs
const CURRENCY_PAIRS: CurrencyPair[] = [
  {
    pair: 'EUR/USD',
    rate: '1.0842',
    change: 0.34,
    sparkline: [1.077, 1.078, 1.081, 1.079, 1.082, 1.083, 1.084],
  },
  {
    pair: 'GBP/USD',
    rate: '1.2714',
    change: -0.18,
    sparkline: [1.274, 1.273, 1.272, 1.271, 1.272, 1.271, 1.271],
  },
  {
    pair: 'USD/JPY',
    rate: '149.73',
    change: 0.62,
    sparkline: [148.2, 148.5, 149.1, 149.3, 149.5, 149.6, 149.7],
  },
  {
    pair: 'USD/CHF',
    rate: '0.9021',
    change: -0.09,
    sparkline: [0.904, 0.903, 0.903, 0.902, 0.902, 0.902, 0.902],
  },
  {
    pair: 'AUD/USD',
    rate: '0.6481',
    change: 0.21,
    sparkline: [0.644, 0.645, 0.646, 0.647, 0.647, 0.648, 0.648],
  },
  {
    pair: 'USD/CAD',
    rate: '1.3652',
    change: -0.31,
    sparkline: [1.370, 1.368, 1.367, 1.366, 1.365, 1.365, 1.365],
  },
  {
    pair: 'NZD/USD',
    rate: '0.5978',
    change: 0.14,
    sparkline: [0.595, 0.596, 0.596, 0.597, 0.597, 0.598, 0.598],
  },
  {
    pair: 'USD/SGD',
    rate: '1.3418',
    change: 0.07,
    sparkline: [1.340, 1.341, 1.341, 1.342, 1.342, 1.342, 1.342],
  },
]

// Mock opportunities
const OPPORTUNITIES: Opportunity[] = [
  {
    id: '1',
    title: 'Southeast Asian Fintech Corridor',
    market: 'Cross-border payments infrastructure',
    score: 94,
    geography: 'SG / MY / TH',
    estimatedRevenue: '$2.4M ARR',
    trend: 'up',
    sector: 'Finance',
  },
  {
    id: '2',
    title: 'Gulf Region Clean Energy Grid',
    market: 'Renewable energy procurement',
    score: 87,
    geography: 'UAE / SA / QA',
    estimatedRevenue: '$8.1M ARR',
    trend: 'up',
    sector: 'Energy',
  },
  {
    id: '3',
    title: 'EU AI Compliance Platform',
    market: 'Regulatory technology (RegTech)',
    score: 81,
    geography: 'DE / FR / NL',
    estimatedRevenue: '$1.7M ARR',
    trend: 'up',
    sector: 'Technology',
  },
  {
    id: '4',
    title: 'African Telecoms Expansion Zone',
    market: 'Mobile infrastructure & data',
    score: 73,
    geography: 'NG / KE / ZA',
    estimatedRevenue: '$3.9M ARR',
    trend: 'stable',
    sector: 'Infrastructure',
  },
  {
    id: '5',
    title: 'LATAM Medtech Distribution',
    market: 'Medical devices & diagnostics',
    score: 66,
    geography: 'BR / MX / CO',
    estimatedRevenue: '$1.2M ARR',
    trend: 'up',
    sector: 'Healthcare',
  },
]

// Mock rate alerts
const RATE_ALERTS = [
  {
    id: '1',
    pair: 'EUR/USD',
    condition: 'above',
    threshold: '1.0900',
    active: true,
    triggered: false,
  },
  {
    id: '2',
    pair: 'GBP/USD',
    condition: 'below',
    threshold: '1.2600',
    active: true,
    triggered: false,
  },
  {
    id: '3',
    pair: 'USD/JPY',
    condition: 'above',
    threshold: '152.00',
    active: false,
    triggered: false,
  },
  {
    id: '4',
    pair: 'AUD/USD',
    condition: 'below',
    threshold: '0.6400',
    active: true,
    triggered: true,
  },
]

// Nav items
const NAV_ITEMS = ['Dashboard', 'Scanner', 'Currency', 'Opportunities']

// Stat cards for header area
const HEADER_STATS = [
  { label: 'Active Markets', value: '91', icon: Globe2, colour: '#00D4FF' },
  { label: 'Open Alerts', value: '7', icon: BellRing, colour: '#F5A623' },
  { label: 'Opportunities', value: '24', icon: Zap, colour: '#00C896' },
  { label: 'Signals Today', value: '138', icon: Activity, colour: '#a78bfa' },
]

export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-[#070D1A] flex flex-col">
      {/* ── Header ── */}
      <header className="sticky top-0 z-30 border-b border-[rgba(255,255,255,0.05)] bg-[rgba(7,13,26,0.85)] backdrop-blur-xl">
        <div className="max-w-[1440px] mx-auto px-6 py-3 flex items-center justify-between gap-6">
          {/* Logo block */}
          <div className="flex items-center gap-3 flex-shrink-0">
            <div className="relative w-8 h-8">
              <div className="absolute inset-0 rounded-lg bg-[#00D4FF] opacity-15 blur-md" />
              <div className="relative w-8 h-8 rounded-lg border border-[rgba(0,212,255,0.4)] bg-[#0A2540] flex items-center justify-center">
                <BarChart3 className="w-4 h-4 text-[#00D4FF]" />
              </div>
            </div>
            <div>
              <h1 className="text-base font-black tracking-[0.15em] text-white leading-none">
                MERIDIAN
              </h1>
              <p className="text-[10px] text-[#00D4FF]/60 tracking-[0.12em] uppercase leading-none mt-0.5">
                Global Business Intelligence
              </p>
            </div>
          </div>

          {/* Nav */}
          <nav className="hidden md:flex items-center gap-1">
            {NAV_ITEMS.map((item, i) => (
              <a
                key={item}
                href="#"
                className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all duration-200 ${
                  i === 0
                    ? 'bg-[rgba(0,212,255,0.1)] text-[#00D4FF] border border-[rgba(0,212,255,0.2)]'
                    : 'text-white/50 hover:text-white/80 hover:bg-[rgba(255,255,255,0.04)]'
                }`}
              >
                {item}
              </a>
            ))}
          </nav>

          {/* Right actions */}
          <div className="flex items-center gap-3">
            {/* Status dot */}
            <div className="flex items-center gap-1.5 text-[11px] text-[#00C896] font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-[#00C896] pulse-ring" />
              Live
            </div>

            <button className="relative p-2 rounded-lg bg-[rgba(255,255,255,0.04)] hover:bg-[rgba(255,255,255,0.07)] border border-[rgba(255,255,255,0.05)] transition-colors">
              <Bell className="w-4 h-4 text-white/60" />
              <span className="absolute -top-0.5 -right-0.5 w-3.5 h-3.5 rounded-full bg-[#F5A623] flex items-center justify-center text-[8px] font-black text-[#070D1A]">
                7
              </span>
            </button>

            <div className="w-7 h-7 rounded-full bg-gradient-to-br from-[#00D4FF] to-[#0A2540] border border-[rgba(0,212,255,0.3)] flex items-center justify-center text-[10px] font-black text-white">
              B
            </div>
          </div>
        </div>
      </header>

      {/* ── Currency Ticker ── */}
      <CurrencyTicker pairs={CURRENCY_PAIRS} />

      {/* ── Main content ── */}
      <main className="flex-1 max-w-[1440px] mx-auto w-full px-6 py-6 flex flex-col gap-6">

        {/* Quick stats row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {HEADER_STATS.map(({ label, value, icon: Icon, colour }) => (
            <div
              key={label}
              className="glass-card rounded-xl px-4 py-3 flex items-center gap-3 hover:border-[rgba(255,255,255,0.1)] transition-all duration-200"
            >
              <div
                className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
                style={{ background: `${colour}15` }}
              >
                <Icon className="w-4 h-4" style={{ color: colour }} />
              </div>
              <div>
                <p className="text-xl font-black text-white leading-none tabular-nums">{value}</p>
                <p className="text-[11px] text-white/40 mt-0.5">{label}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Three-column grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

          {/* ── Column 1: Top Opportunities ── */}
          <section className="glass-card rounded-2xl p-5 flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-bold text-white tracking-wide">Top Opportunities</h2>
                <p className="text-[11px] text-white/35 mt-0.5">Ranked by MERIDIAN Intelligence Score</p>
              </div>
              <a
                href="#"
                className="flex items-center gap-1 text-[11px] text-[#00D4FF]/70 hover:text-[#00D4FF] transition-colors"
              >
                View all
                <ArrowUpRight className="w-3 h-3" />
              </a>
            </div>

            <div className="flex flex-col gap-2.5">
              {OPPORTUNITIES.map((opp, i) => (
                <OpportunityCard key={opp.id} opportunity={opp} rank={i + 1} />
              ))}
            </div>
          </section>

          {/* ── Column 2: Domain Scanner ── */}
          <section className="glass-card rounded-2xl p-5 flex flex-col gap-4">
            <div>
              <h2 className="text-sm font-bold text-white tracking-wide">Domain Scanner</h2>
              <p className="text-[11px] text-white/35 mt-0.5">Analyse any domain for business intelligence</p>
            </div>

            <DomainScanner />
          </section>

          {/* ── Column 3: Rate Alerts ── */}
          <section className="glass-card rounded-2xl p-5 flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-bold text-white tracking-wide">Rate Alerts</h2>
                <p className="text-[11px] text-white/35 mt-0.5">
                  {RATE_ALERTS.filter((a) => a.active).length} active ·{' '}
                  {RATE_ALERTS.filter((a) => a.triggered).length} triggered
                </p>
              </div>
              <button className="flex items-center gap-1.5 text-[11px] font-semibold text-[#00D4FF] bg-[rgba(0,212,255,0.08)] hover:bg-[rgba(0,212,255,0.14)] border border-[rgba(0,212,255,0.15)] px-2.5 py-1 rounded-lg transition-colors">
                + New Alert
              </button>
            </div>

            <div className="flex flex-col gap-2.5">
              {RATE_ALERTS.map((alert) => (
                <RateAlertRow key={alert.id} alert={alert} />
              ))}
            </div>

            {/* Alert summary box */}
            <div className="mt-auto rounded-xl bg-[rgba(245,166,35,0.06)] border border-[rgba(245,166,35,0.12)] p-3">
              <div className="flex items-center gap-2 mb-1.5">
                <BellRing className="w-3.5 h-3.5 text-[#F5A623]" />
                <span className="text-[11px] font-semibold text-[#F5A623]">Alert Triggered</span>
              </div>
              <p className="text-[11px] text-white/50 leading-relaxed">
                AUD/USD dropped below your threshold of 0.6400. Consider reviewing your exposure in the APAC corridor.
              </p>
            </div>
          </section>

        </div>
      </main>

      {/* ── Footer ── */}
      <footer className="border-t border-[rgba(255,255,255,0.04)] bg-[rgba(7,13,26,0.6)] backdrop-blur-sm">
        <div className="max-w-[1440px] mx-auto px-6 py-3 flex flex-col sm:flex-row items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-black tracking-[0.2em] text-[#00D4FF]/50">MERIDIAN</span>
            <span className="text-white/10">|</span>
            <span className="text-[10px] text-white/30">Web Companion v1.0</span>
          </div>

          {/* Codebase stats */}
          <div className="flex items-center gap-4 flex-wrap justify-center sm:justify-end">
            {[
              { label: 'files', value: '162' },
              { label: 'lines', value: '18,750' },
              { label: 'intelligence modules', value: '7' },
              { label: 'languages', value: '91' },
            ].map(({ label, value }) => (
              <span key={label} className="text-[10px] text-white/30">
                <span className="font-bold text-white/50 tabular-nums">{value}</span>{' '}
                {label}
              </span>
            ))}
          </div>

          <div className="flex items-center gap-1.5 text-[10px] text-white/25">
            <span className="w-1.5 h-1.5 rounded-full bg-[#00C896]/60" />
            All systems operational
          </div>
        </div>
      </footer>
    </div>
  )
}

// ── Rate alert row (static/display only - toggles would need client component) ──
function RateAlertRow({
  alert,
}: {
  alert: { id: string; pair: string; condition: string; threshold: string; active: boolean; triggered: boolean }
}) {
  const isTriggered = alert.triggered

  return (
    <div
      className={`flex items-center gap-3 p-3 rounded-xl border transition-all duration-200 ${
        isTriggered
          ? 'bg-[rgba(255,71,87,0.06)] border-[rgba(255,71,87,0.15)]'
          : 'glass-card hover:border-[rgba(255,255,255,0.1)]'
      }`}
    >
      {/* Pair tag */}
      <div className="flex-shrink-0">
        <span
          className="text-[11px] font-black tracking-wider px-2 py-1 rounded-lg"
          style={{
            background: isTriggered ? 'rgba(255,71,87,0.12)' : 'rgba(0,212,255,0.08)',
            color: isTriggered ? '#FF4757' : '#00D4FF',
          }}
        >
          {alert.pair}
        </span>
      </div>

      {/* Condition */}
      <div className="flex-1 min-w-0">
        <p className="text-xs text-white/70">
          Rate{' '}
          <span className="font-semibold text-white/90">
            {alert.condition} {alert.threshold}
          </span>
        </p>
        {isTriggered && (
          <p className="text-[10px] text-[#FF4757] font-semibold mt-0.5">
            Triggered
          </p>
        )}
      </div>

      {/* Toggle icon */}
      <div className="flex-shrink-0">
        {alert.active ? (
          <ToggleRight className="w-5 h-5 text-[#00C896]" />
        ) : (
          <ToggleLeft className="w-5 h-5 text-white/20" />
        )}
      </div>
    </div>
  )
}
