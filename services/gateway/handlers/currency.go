package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type CurrencyHandler struct {
	rateEndpoint string
	httpClient   *http.Client
	logger       *zap.Logger
}

func NewCurrencyHandler(logger *zap.Logger) *CurrencyHandler {
	endpoint := os.Getenv("CURRENCY_RATE_ENDPOINT")
	if endpoint == "" {
		endpoint = "https://api.exchangerate-api.com/v4/latest"
	}
	return &CurrencyHandler{
		rateEndpoint: endpoint,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
		logger: logger,
	}
}

type RateResponse struct {
	Base      string             `json:"base"`
	Date      string             `json:"date"`
	Rates     map[string]float64 `json:"rates"`
	Timestamp int64              `json:"timestamp"`
}

type CurrencyRateItem struct {
	Pair          string  `json:"pair"`
	BaseCurrency  string  `json:"base_currency"`
	QuoteCurrency string  `json:"quote_currency"`
	Rate          float64 `json:"rate"`
	Timestamp     string  `json:"timestamp"`
}

func (h *CurrencyHandler) GetRates(c *gin.Context) {
	pairsParam := c.Query("pairs")
	var requestedPairs []string
	if pairsParam != "" {
		for _, p := range strings.Split(pairsParam, ",") {
			p = strings.TrimSpace(strings.ToUpper(p))
			if p != "" {
				requestedPairs = append(requestedPairs, p)
			}
		}
	}

	base := "GBP"
	if len(requestedPairs) > 0 {
		parts := strings.Split(requestedPairs[0], "/")
		if len(parts) == 2 {
			base = parts[0]
		}
	}

	url := fmt.Sprintf("%s/%s", h.rateEndpoint, base)
	resp, err := h.httpClient.Get(url)
	if err != nil {
		h.logger.Error("Failed to fetch rates from external provider", zap.String("url", url), zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "rate_fetch_failed",
			"message": "unable to retrieve currency rates at this time",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		h.logger.Error("Failed to read rate response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	var rateData RateResponse
	if err := json.Unmarshal(body, &rateData); err != nil {
		h.logger.Error("Failed to parse rate response", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "parse_error",
			"message": "failed to parse rate data from provider",
		})
		return
	}

	timestamp := time.Now().UTC().Format(time.RFC3339)

	var result []CurrencyRateItem

	if len(requestedPairs) == 0 {
		defaults := []string{"GBP/USD", "GBP/EUR", "GBP/JPY", "GBP/AUD", "GBP/CAD"}
		for _, pair := range defaults {
			parts := strings.Split(pair, "/")
			if len(parts) != 2 {
				continue
			}
			quote := parts[1]
			rate, ok := rateData.Rates[quote]
			if !ok {
				continue
			}
			result = append(result, CurrencyRateItem{
				Pair:          pair,
				BaseCurrency:  parts[0],
				QuoteCurrency: quote,
				Rate:          rate,
				Timestamp:     timestamp,
			})
		}
	} else {
		for _, pair := range requestedPairs {
			parts := strings.Split(pair, "/")
			if len(parts) != 2 {
				continue
			}
			quote := parts[1]
			rate, ok := rateData.Rates[quote]
			if !ok {
				continue
			}
			result = append(result, CurrencyRateItem{
				Pair:          pair,
				BaseCurrency:  parts[0],
				QuoteCurrency: quote,
				Rate:          rate,
				Timestamp:     timestamp,
			})
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"base":      base,
		"rates":     result,
		"timestamp": timestamp,
	})
}

type ConvertRequest struct {
	From   string  `json:"from" binding:"required"`
	To     string  `json:"to" binding:"required"`
	Amount float64 `json:"amount" binding:"required,gt=0"`
}

type ConvertResponse struct {
	From            string  `json:"from"`
	To              string  `json:"to"`
	OriginalAmount  float64 `json:"original_amount"`
	ConvertedAmount float64 `json:"converted_amount"`
	Rate            float64 `json:"rate"`
	Timestamp       string  `json:"timestamp"`
}

func (h *CurrencyHandler) ConvertCurrency(c *gin.Context) {
	var req ConvertRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "from, to, and a positive amount are required",
		})
		return
	}

	req.From = strings.ToUpper(strings.TrimSpace(req.From))
	req.To = strings.ToUpper(strings.TrimSpace(req.To))

	if len(req.From) != 3 || len(req.To) != 3 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_currency_code",
			"message": "currency codes must be 3-letter ISO 4217 codes",
		})
		return
	}

	url := fmt.Sprintf("%s/%s", h.rateEndpoint, req.From)
	resp, err := h.httpClient.Get(url)
	if err != nil {
		h.logger.Error("Failed to fetch rates for conversion", zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{
			"error":   "rate_fetch_failed",
			"message": "unable to retrieve currency rates at this time",
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
		return
	}

	var rateData RateResponse
	if err := json.Unmarshal(body, &rateData); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "parse_error"})
		return
	}

	rate, ok := rateData.Rates[req.To]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "unsupported_currency",
			"message": fmt.Sprintf("currency %s is not supported", req.To),
		})
		return
	}

	converted := math.Round(req.Amount*rate*100) / 100

	c.JSON(http.StatusOK, ConvertResponse{
		From:            req.From,
		To:              req.To,
		OriginalAmount:  req.Amount,
		ConvertedAmount: converted,
		Rate:            rate,
		Timestamp:       time.Now().UTC().Format(time.RFC3339),
	})
}
