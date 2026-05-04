package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type MQLHandler struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger
}

func NewMQLHandler(baseURL string, logger *zap.Logger) *MQLHandler {
	return &MQLHandler{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 45 * time.Second},
		logger:     logger,
	}
}

type MQLRequest struct {
	Query string `json:"query" binding:"required"`
}

type MQLTypedResult struct {
	Query       string          `json:"query"`
	ResultType  string          `json:"result_type"`
	Data        json.RawMessage `json:"data"`
	ExecutedAt  string          `json:"executed_at"`
	DurationMs  int64           `json:"duration_ms"`
}

func (h *MQLHandler) ExecuteMQL(c *gin.Context) {
	var req MQLRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "query field is required",
		})
		return
	}

	query := strings.TrimSpace(req.Query)
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "empty_query",
			"message": "MQL query cannot be empty",
		})
		return
	}

	if len(query) > 10000 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "query_too_long",
			"message": "MQL query must not exceed 10,000 characters",
		})
		return
	}

	start := time.Now()

	payload, err := json.Marshal(map[string]string{"query": query})
	if err != nil {
		h.logger.Error("Failed to marshal MQL request", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	resp, err := h.httpClient.Post(
		fmt.Sprintf("%s/analyse", h.baseURL),
		"application/json",
		bytes.NewReader(payload),
	)
	if err != nil {
		h.logger.Error("Intelligence service unreachable for MQL execution",
			zap.String("url", h.baseURL+"/analyse"),
			zap.Error(err),
		)
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "MQL execution service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		h.logger.Error("Failed to read MQL response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	durationMs := time.Since(start).Milliseconds()

	if resp.StatusCode != http.StatusOK {
		h.logger.Warn("MQL service returned non-200",
			zap.Int("status", resp.StatusCode),
			zap.String("query_preview", truncate(query, 100)),
		)
		c.JSON(resp.StatusCode, json.RawMessage(body))
		return
	}

	resultType := inferResultType(query)

	h.logger.Info("MQL query executed",
		zap.String("query_preview", truncate(query, 100)),
		zap.String("result_type", resultType),
		zap.Int64("duration_ms", durationMs),
	)

	c.JSON(http.StatusOK, MQLTypedResult{
		Query:      query,
		ResultType: resultType,
		Data:       json.RawMessage(body),
		ExecutedAt: time.Now().UTC().Format(time.RFC3339),
		DurationMs: durationMs,
	})
}

func inferResultType(query string) string {
	q := strings.ToLower(query)
	switch {
	case strings.Contains(q, "scan") || strings.Contains(q, "domain"):
		return "scan_result"
	case strings.Contains(q, "opportunit"):
		return "opportunity_list"
	case strings.Contains(q, "creative") || strings.Contains(q, "generat"):
		return "creative_result"
	case strings.Contains(q, "alert"):
		return "alert_result"
	default:
		return "message_result"
	}
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}
