interface ScoreRingProps {
  score: number
  size?: number
  strokeWidth?: number
  showLabel?: boolean
}

export default function ScoreRing({
  score,
  size = 56,
  strokeWidth = 4,
  showLabel = true,
}: ScoreRingProps) {
  const radius = (size - strokeWidth) / 2
  const circumference = 2 * Math.PI * radius
  const offset = circumference - (score / 100) * circumference

  const colour =
    score >= 80
      ? '#00C896'
      : score >= 60
      ? '#F5A623'
      : '#FF4757'

  const glowColour =
    score >= 80
      ? 'rgba(0, 200, 150, 0.25)'
      : score >= 60
      ? 'rgba(245, 166, 35, 0.25)'
      : 'rgba(255, 71, 87, 0.25)'

  const trackColour = 'rgba(255,255,255,0.06)'

  return (
    <div
      className="relative flex items-center justify-center flex-shrink-0"
      style={{ width: size, height: size }}
    >
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        style={{ transform: 'rotate(-90deg)' }}
      >
        <defs>
          <filter id={`glow-${score}`} x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="2" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={trackColour}
          strokeWidth={strokeWidth}
        />

        {/* Progress arc */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={colour}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          filter={`url(#glow-${score})`}
          style={{
            transition: 'stroke-dashoffset 0.6s ease-out',
            filter: `drop-shadow(0 0 4px ${glowColour})`,
          }}
        />
      </svg>

      {showLabel && (
        <span
          className="absolute text-xs font-bold tabular-nums"
          style={{ color: colour, fontSize: size < 48 ? '0.6rem' : '0.7rem' }}
        >
          {score}
        </span>
      )}
    </div>
  )
}
