'use client'

export interface CurrencyPair {
  pair: string
  rate: string
  change: number
  sparkline: number[]
}

interface CurrencyTickerProps {
  pairs: CurrencyPair[]
}

function MiniSparkline({ values, positive }: { values: number[]; positive: boolean }) {
  const min = Math.min(...values)
  const max = Math.max(...values)
  const range = max - min || 1
  const width = 48
  const height = 20
  const step = width / (values.length - 1)

  const points = values
    .map((v, i) => {
      const x = i * step
      const y = height - ((v - min) / range) * height
      return `${x},${y}`
    })
    .join(' ')

  const colour = positive ? '#00C896' : '#FF4757'

  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="opacity-80">
      <defs>
        <linearGradient id={`grad-${positive}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={colour} stopOpacity="0.3" />
          <stop offset="100%" stopColor={colour} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polyline
        points={points}
        fill="none"
        stroke={colour}
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function TickerItem({ pair }: { pair: CurrencyPair }) {
  const positive = pair.change >= 0
  const changeColour = positive ? '#00C896' : '#FF4757'
  const changePrefix = positive ? '+' : ''

  return (
    <div className="flex items-center gap-3 px-5 py-2 border-r border-[rgba(255,255,255,0.05)] flex-shrink-0 min-w-[190px]">
      <div className="flex flex-col">
        <span className="text-xs font-bold text-white tracking-widest">{pair.pair}</span>
        <span className="text-[11px] font-semibold text-white/70 tabular-nums mt-0.5">
          {pair.rate}
        </span>
      </div>

      <MiniSparkline values={pair.sparkline} positive={positive} />

      <span
        className="text-[11px] font-bold tabular-nums rounded px-1.5 py-0.5"
        style={{
          color: changeColour,
          background: positive ? 'rgba(0,200,150,0.12)' : 'rgba(255,71,87,0.12)',
        }}
      >
        {changePrefix}{pair.change.toFixed(2)}%
      </span>
    </div>
  )
}

export default function CurrencyTicker({ pairs }: CurrencyTickerProps) {
  const doubled = [...pairs, ...pairs]

  return (
    <div className="relative overflow-hidden border-y border-[rgba(255,255,255,0.05)] bg-[rgba(10,37,64,0.4)] backdrop-blur-sm">
      {/* Left fade */}
      <div className="absolute left-0 top-0 bottom-0 w-12 z-10 bg-gradient-to-r from-[#070D1A] to-transparent pointer-events-none" />
      {/* Right fade */}
      <div className="absolute right-0 top-0 bottom-0 w-12 z-10 bg-gradient-to-l from-[#070D1A] to-transparent pointer-events-none" />

      {/* Ticker label */}
      <div className="absolute left-0 top-0 bottom-0 z-20 flex items-center px-3 bg-[#0A2540] border-r border-[rgba(0,212,255,0.2)]">
        <span className="text-[10px] font-black tracking-[0.2em] text-[#00D4FF] uppercase whitespace-nowrap">
          FX Live
        </span>
      </div>

      <div className="pl-20 flex">
        <div className="ticker-track flex">
          {doubled.map((pair, i) => (
            <TickerItem key={`${pair.pair}-${i}`} pair={pair} />
          ))}
        </div>
      </div>
    </div>
  )
}
