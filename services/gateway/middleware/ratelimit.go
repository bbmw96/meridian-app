package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func RateLimiter(rdb *redis.Client, maxRequests int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		key := fmt.Sprintf("meridian:ratelimit:%s", ip)

		now := time.Now().UnixMilli()
		windowMs := window.Milliseconds()
		windowStart := now - windowMs

		ctx := context.Background()

		pipe := rdb.Pipeline()
		pipe.ZRemRangeByScore(ctx, key, "0", strconv.FormatInt(windowStart, 10))
		pipe.ZCard(ctx, key)
		pipe.ZAdd(ctx, key, redis.Z{Score: float64(now), Member: strconv.FormatInt(now, 10)})
		pipe.Expire(ctx, key, window+time.Second)

		results, err := pipe.Exec(ctx)
		if err != nil {
			c.Next()
			return
		}

		var count int64
		if len(results) >= 2 {
			if cardCmd, ok := results[1].(*redis.IntCmd); ok {
				count, _ = cardCmd.Result()
			}
		}

		remaining := int64(maxRequests) - count
		if remaining < 0 {
			remaining = 0
		}

		resetTime := time.Now().Add(window)

		c.Header("X-RateLimit-Limit", strconv.Itoa(maxRequests))
		c.Header("X-RateLimit-Remaining", strconv.FormatInt(remaining, 10))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(resetTime.Unix(), 10))

		if count >= int64(maxRequests) {
			retryAfter := int(window.Seconds())
			c.Header("Retry-After", strconv.Itoa(retryAfter))
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":       "rate_limit_exceeded",
				"message":     fmt.Sprintf("rate limit of %d requests per %s exceeded", maxRequests, window),
				"retry_after": retryAfter,
			})
			return
		}

		c.Next()
	}
}
