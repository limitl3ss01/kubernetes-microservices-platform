package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/google/uuid"
)

// Notification represents a notification message
type Notification struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Type      string    `json:"type"`
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
	ReadAt    *time.Time `json:"read_at,omitempty"`
}

// CreateNotificationRequest represents the request to create a notification
type CreateNotificationRequest struct {
	UserID  string `json:"user_id" binding:"required"`
	Type    string `json:"type" binding:"required"`
	Title   string `json:"title" binding:"required"`
	Message string `json:"message" binding:"required"`
}

// Prometheus metrics
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)
)

// In-memory storage (replace with database in production)
var notifications = []Notification{
	{
		ID:        "1",
		UserID:    "1",
		Type:      "order_status",
		Title:     "Order Confirmed",
		Message:   "Your order #12345 has been confirmed",
		Status:    "unread",
		CreatedAt: time.Now(),
	},
}

func init() {
	// Register Prometheus metrics
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
}

// Metrics middleware
func metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()
		status := fmt.Sprintf("%d", c.Writer.Status())

		httpRequestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), status).Inc()
		httpRequestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
	}
}

func main() {
	// Set Gin to release mode in production
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// Add metrics middleware
	r.Use(metricsMiddleware())

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"service":   "notification-service",
			"timestamp": time.Now().ISO8601(),
			"version":   "1.0.0",
		})
	})

	// Readiness probe
	r.GET("/ready", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ready",
			"service": "notification-service",
		})
	})

	// Metrics endpoint
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API routes
	api := r.Group("/api")
	{
		// Get all notifications
		api.GET("/notifications", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data":    notifications,
				"count":   len(notifications),
			})
		})

		// Get notification by ID
		api.GET("/notifications/:id", func(c *gin.Context) {
			id := c.Param("id")
			for _, notification := range notifications {
				if notification.ID == id {
					c.JSON(http.StatusOK, gin.H{
						"success": true,
						"data":    notification,
					})
					return
				}
			}
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Notification not found",
			})
		})

		// Create new notification
		api.POST("/notifications", func(c *gin.Context) {
			var req CreateNotificationRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"error":   "Invalid request data",
				})
				return
			}

			newNotification := Notification{
				ID:        uuid.New().String(),
				UserID:    req.UserID,
				Type:      req.Type,
				Title:     req.Title,
				Message:   req.Message,
				Status:    "unread",
				CreatedAt: time.Now(),
			}

			notifications = append(notifications, newNotification)

			c.JSON(http.StatusCreated, gin.H{
				"success": true,
				"data":    newNotification,
			})
		})

		// Get notifications by user
		api.GET("/users/:user_id/notifications", func(c *gin.Context) {
			userID := c.Param("user_id")
			var userNotifications []Notification

			for _, notification := range notifications {
				if notification.UserID == userID {
					userNotifications = append(userNotifications, notification)
				}
			}

			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data":    userNotifications,
				"count":   len(userNotifications),
			})
		})

		// Mark notification as read
		api.PATCH("/notifications/:id/read", func(c *gin.Context) {
			id := c.Param("id")
			now := time.Now()

			for i, notification := range notifications {
				if notification.ID == id {
					notifications[i].Status = "read"
					notifications[i].ReadAt = &now

					c.JSON(http.StatusOK, gin.H{
						"success": true,
						"data":    notifications[i],
					})
					return
				}
			}

			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Notification not found",
			})
		})

		// Delete notification
		api.DELETE("/notifications/:id", func(c *gin.Context) {
			id := c.Param("id")

			for i, notification := range notifications {
				if notification.ID == id {
					deletedNotification := notifications[i]
					notifications = append(notifications[:i], notifications[i+1:]...)

					c.JSON(http.StatusOK, gin.H{
						"success": true,
						"data":    deletedNotification,
					})
					return
				}
			}

			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Notification not found",
			})
		})

		// Send notification (webhook endpoint)
		api.POST("/send", func(c *gin.Context) {
			var req CreateNotificationRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"error":   "Invalid request data",
				})
				return
			}

			// In a real application, this would send the notification
			// via email, SMS, push notification, etc.
			newNotification := Notification{
				ID:        uuid.New().String(),
				UserID:    req.UserID,
				Type:      req.Type,
				Title:     req.Title,
				Message:   req.Message,
				Status:    "sent",
				CreatedAt: time.Now(),
			}

			notifications = append(notifications, newNotification)

			// Simulate sending notification
			log.Printf("Sending notification to user %s: %s", req.UserID, req.Title)

			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "Notification sent successfully",
				"data":    newNotification,
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "3003"
	}

	log.Printf("Notification Service running on port %s", port)
	log.Printf("Health check: http://localhost:%s/health", port)
	log.Printf("Metrics: http://localhost:%s/metrics", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
} 