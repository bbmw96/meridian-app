package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type IntelligenceHandler struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger
}

func NewIntelligenceHandler(baseURL string, logger *zap.Logger) *IntelligenceHandler {
	return &IntelligenceHandler{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: logger,
	}
}

type ScanDomainRequest struct {
	Domain string `json:"domain" binding:"required"`
}

func (h *IntelligenceHandler) ScanDomain(c *gin.Context) {
	var req ScanDomainRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "domain field is required",
		})
		return
	}

	req.Domain = strings.TrimSpace(strings.ToLower(req.Domain))
	if req.Domain == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "domain cannot be empty",
		})
		return
	}

	parsed, err := url.Parse("https://" + req.Domain)
	if err != nil || parsed.Host == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_domain",
			"message": "domain format is invalid",
		})
		return
	}

	payload, err := json.Marshal(map[string]string{"domain": req.Domain})
	if err != nil {
		h.logger.Error("Failed to marshal scan request", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	resp, err := h.httpClient.Post(
		fmt.Sprintf("%s/scan", h.baseURL),
		"application/json",
		bytes.NewReader(payload),
	)
	if err != nil {
		h.logger.Error("Intelligence service unreachable", zap.String("url", h.baseURL+"/scan"), zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "intelligence service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		h.logger.Error("Failed to read intelligence response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	if resp.StatusCode != http.StatusOK {
		h.logger.Warn("Intelligence service returned non-200",
			zap.Int("status", resp.StatusCode),
			zap.String("domain", req.Domain),
		)
		c.JSON(resp.StatusCode, json.RawMessage(body))
		return
	}

	c.Data(http.StatusOK, "application/json", body)
}

type CompetitorsRequest struct {
	Domain string `form:"domain" binding:"required"`
	Limit  int    `form:"limit"`
}

func (h *IntelligenceHandler) GetCompetitors(c *gin.Context) {
	var req CompetitorsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "domain query parameter is required",
		})
		return
	}

	req.Domain = strings.TrimSpace(strings.ToLower(req.Domain))
	if req.Domain == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "domain cannot be empty",
		})
		return
	}

	limit := req.Limit
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	upstreamURL := fmt.Sprintf("%s/competitors?domain=%s&limit=%d",
		h.baseURL,
		url.QueryEscape(req.Domain),
		limit,
	)

	resp, err := h.httpClient.Get(upstreamURL)
	if err != nil {
		h.logger.Error("Intelligence service unreachable", zap.String("url", upstreamURL), zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "intelligence service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		h.logger.Error("Failed to read competitors response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	if resp.StatusCode != http.StatusOK {
		h.logger.Warn("Intelligence service returned non-200",
			zap.Int("status", resp.StatusCode),
			zap.String("domain", req.Domain),
		)
		c.JSON(resp.StatusCode, json.RawMessage(body))
		return
	}

	c.Data(http.StatusOK, "application/json", body)
}

type OpportunityHandler struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger
}

func NewOpportunityHandler(baseURL string, logger *zap.Logger) *OpportunityHandler {
	return &OpportunityHandler{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
		logger:     logger,
	}
}

func (h *OpportunityHandler) GetOpportunities(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to read request body"})
		return
	}

	resp, err := h.httpClient.Post(
		fmt.Sprintf("%s/opportunities", h.baseURL),
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		h.logger.Error("Intelligence service unreachable", zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "intelligence service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	c.Data(resp.StatusCode, "application/json", respBody)
}

type AlertHandler struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger
}

func NewAlertHandler(baseURL string, logger *zap.Logger) *AlertHandler {
	return &AlertHandler{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 15 * time.Second},
		logger:     logger,
	}
}

func (h *AlertHandler) CreateAlert(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to read request body"})
		return
	}

	resp, err := h.httpClient.Post(
		fmt.Sprintf("%s/alerts", h.baseURL),
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		h.logger.Error("Intelligence service unreachable", zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "upstream_unavailable",
			"message": "intelligence service is currently unavailable",
		})
		return
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	c.Data(resp.StatusCode, "application/json", respBody)
}
