package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const userIDKey = "userID"
const claimsKey = "claims"

type MeridianClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

func JWTAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "missing_token",
				"message": "authorisation header is required",
			})
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "invalid_token_format",
				"message": "authorisation header must be in the format: Bearer <token>",
			})
			return
		}

		tokenString := strings.TrimSpace(parts[1])
		if tokenString == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "empty_token",
				"message": "token must not be empty",
			})
			return
		}

		claims := &MeridianClaims{}
		token, err := jwt.ParseWithClaims(
			tokenString,
			claims,
			func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return []byte(secret), nil
			},
			jwt.WithValidMethods([]string{"HS256"}),
			jwt.WithExpirationRequired(),
		)

		if err != nil || !token.Valid {
			status := http.StatusUnauthorized
			errCode := "invalid_token"
			message := "token is invalid or has expired"

			switch {
			case strings.Contains(err.Error(), "expired"):
				errCode = "token_expired"
				message = "token has expired, please re-authenticate"
			case strings.Contains(err.Error(), "signature"):
				errCode = "invalid_signature"
				message = "token signature is invalid"
			}

			c.AbortWithStatusJSON(status, gin.H{
				"error":   errCode,
				"message": message,
			})
			return
		}

		c.Set(userIDKey, claims.UserID)
		c.Set(claimsKey, claims)

		c.Next()
	}
}

func GetUserID(c *gin.Context) string {
	if id, exists := c.Get(userIDKey); exists {
		if s, ok := id.(string); ok {
			return s
		}
	}
	return ""
}

func GetClaims(c *gin.Context) *MeridianClaims {
	if claims, exists := c.Get(claimsKey); exists {
		if mc, ok := claims.(*MeridianClaims); ok {
			return mc
		}
	}
	return nil
}
