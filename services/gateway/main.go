package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/meridian/gateway/handlers"
	"github.com/meridian/gateway/middleware"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

func main() {
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	redisAddr := getEnv("REDIS_ADDR", "localhost:6379")
	redisPassword := getEnv("REDIS_PASSWORD", "")
	redisDB := 0

	rdb := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
		DB:       redisDB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := rdb.Ping(ctx).Err(); err != nil {
		logger.Warn("Redis connection failed, rate limiting will be disabled", zap.Error(err))
		rdb = nil
	}

	if getEnv("GIN_MODE", "release") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	router.Use(middleware.RequestLogger(logger))
	router.Use(middleware.CORS())
	if rdb != nil {
		router.Use(middleware.RateLimiter(rdb, 100, time.Minute))
	}

	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"service":   "meridian-gateway",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	jwtSecret := getEnv("JWT_SECRET", "change-me-in-production")
	intelligenceBaseURL := getEnv("INTELLIGENCE_SERVICE_URL", "http://localhost:8001")
	bffBaseURL := getEnv("BFF_SERVICE_URL", "http://localhost:4000")
	realtimeBaseURL := getEnv("REALTIME_SERVICE_URL", "http://localhost:4001")

	_ = bffBaseURL
	_ = realtimeBaseURL

	authMiddleware := middleware.JWTAuth(jwtSecret)

	v1 := router.Group("/api/v1")
	v1.Use(authMiddleware)

	intelligenceHandler := handlers.NewIntelligenceHandler(intelligenceBaseURL, logger)
	v1.POST("/intelligence/scan", intelligenceHandler.ScanDomain)
	v1.GET("/intelligence/competitors", intelligenceHandler.GetCompetitors)

	currencyHandler := handlers.NewCurrencyHandler(logger)
	v1.GET("/currency/rates", currencyHandler.GetRates)
	v1.POST("/currency/convert", currencyHandler.ConvertCurrency)

	creativeHandler := handlers.NewCreativeHandler(intelligenceBaseURL, logger)
	v1.POST("/creative/generate", creativeHandler.GenerateCreative)

	opportunityHandler := handlers.NewOpportunityHandler(intelligenceBaseURL, logger)
	v1.POST("/radar/opportunities", opportunityHandler.GetOpportunities)

	alertHandler := handlers.NewAlertHandler(intelligenceBaseURL, logger)
	v1.POST("/alerts", alertHandler.CreateAlert)

	mqlHandler := handlers.NewMQLHandler(intelligenceBaseURL, logger)
	v1.POST("/mql/execute", mqlHandler.ExecuteMQL)

	port := getEnv("PORT", "8080")
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		logger.Info("MERIDIAN API Gateway starting", zap.String("port", port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Server failed to start", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down gracefully...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server shutdown complete")
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
