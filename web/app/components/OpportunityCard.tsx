import ScoreRing from './ScoreRing'
import { MapPin, TrendingUp } from 'lucide-react'

export interface Opportunity {
  id: string
  title: string
  market: string
  score: number
  geography: string
  estimatedRevenue: string
  trend: 'up' | 'down' | 'stable'
  sector: string
}

interface OpportunityCardProps {
  opportunity: Opportunity
  rank: number
}

const sectorColours: Record<string, string> = {
  Technology: 'rgba(0, 212, 255, 0.15)',
  Energy: 'rgba(245, 166, 35, 0.15)',
  Finance: 'rgba(0, 200, 150, 0.15)',
  Healthcare: 'rgba(139, 92, 246, 0.15)',
  Infrastructure: 'rgba(59, 130, 246, 0.15)',
}

const sectorTextColours: Record<string, string> = {
  Technology: '#00D4FF',
  Energy: '#F5A623',
  Finance: '#00C896',
  Healthcare: '#a78bfa',
  Infrastructure: '#60a5fa',
}

export default function OpportunityCard({ opportunity, rank }: OpportunityCardProps) {
  const sectorBg = sectorColours[opportunity.sector] ?? 'rgba(255,255,255,0.08)'
  const sectorText = sectorTextColours[opportunity.sector] ?? '#ffffff'

  return (
    <div className="group relative flex items-start gap-3 p-3 rounded-xl glass-card hover:border-[rgba(0,212,255,0.18)] transition-all duration-300 hover:bg-[rgba(0,212,255,0.03)] animate-fade-in">
      {/* Rank badge */}
      <span className="absolute -top-1.5 -left-1.5 w-5 h-5 rounded-full bg-[#0A2540] border border-[rgba(0,212,255,0.3)] flex items-center justify-center text-[10px] font-bold text-[#00D4FF] tabular-nums z-10">
        {rank}
      </span>

      {/* Score ring */}
      <ScoreRing score={opportunity.score} size={52} strokeWidth={3.5} />

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2 mb-1">
          <h4 className="text-sm font-semibold text-white leading-snug truncate">
            {opportunity.title}
          </h4>
          <span
            className="flex-shrink-0 text-[10px] font-semibold px-2 py-0.5 rounded-full"
            style={{ background: sectorBg, color: sectorText }}
          >
            {opportunity.sector}
          </span>
        </div>

        <p className="text-[11px] text-white/40 font-medium mb-2">{opportunity.market}</p>

        <div className="flex items-center gap-3 text-[11px]">
          <span className="flex items-center gap-1 text-white/50">
            <MapPin className="w-3 h-3" />
            {opportunity.geography}
          </span>
          <span className="flex items-center gap-1 text-[#00C896] font-semibold">
            <TrendingUp className="w-3 h-3" />
            {opportunity.estimatedRevenue}
          </span>
        </div>
      </div>
    </div>
  )
}
