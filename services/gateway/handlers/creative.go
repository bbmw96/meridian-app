package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type CreativeHandler struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger
}

func NewCreativeHandler(baseURL string, logger *zap.Logger) *CreativeHandler {
	return &CreativeHandler{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 60 * time.Second},
		logger:     logger,
	}
}

type CreativeRequest struct {
	Format      string            `json:"format" binding:"required"`
	Platform    string            `json:"platform" binding:"required"`
	Industry    string            `json:"industry" binding:"required"`
	BrandName   string            `json:"brand_name" binding:"required"`
	Tone        string            `json:"tone"`
	Keywords    []string          `json:"keywords"`
	Template    string            `json:"template"`
	Constraints map[string]string `json:"constraints"`
}

func (h *CreativeHandler) GenerateCreative(c *gin.Context) {
	var req CreativeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "format, platform, industry, and brand_name are required",
			"detail":  err.Error(),
		})
		return
	}

	validFormats := map[string]bool{
		"static": true,
		"video":  true,
		"text":   true,
		"email":  true,
		"social": true,
	}
	if !validFormats[req.Format] {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_format",
			"message": "format must be one of: static, video, text, email, social",
		})
		return
	}

	if req.Tone == "" {
		req.Tone = "professional"
	}

	payload, err := json.Marshal(req)
	if err != nil {
		h.logger.Error("Failed to marshal creative request", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	resp, err := h.httpClient.Post(
		fmt.Sprintf("%s/generate-creative", h.baseURL),
		"application/json",
		bytes.NewReader(payload),
	)
	if err != nil {
		h.logger.Error("Intelligence service unreachable for creative generation",
			zap.String("url", h.baseURL+"/generate-creative"),
			zap.Error(err),
		)
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "creative generation service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		h.logger.Error("Failed to read creative response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	if resp.StatusCode != http.StatusOK {
		h.logger.Warn("Creative service returned non-200",
			zap.Int("status", resp.StatusCode),
			zap.String("format", req.Format),
		)
		c.JSON(resp.StatusCode, json.RawMessage(body))
		return
	}

	c.Data(http.StatusOK, "application/json", body)
}
