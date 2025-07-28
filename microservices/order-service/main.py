from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uuid
import time
from datetime import datetime
import os
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.requests import Request
from starlette.responses import Response

# FastAPI app
app = FastAPI(
    title="Order Service",
    description="Order management microservice",
    version="1.0.0"
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# Pydantic models
class OrderItem(BaseModel):
    product_id: str
    quantity: int
    price: float

class OrderCreate(BaseModel):
    user_id: str
    items: List[OrderItem]
    shipping_address: str

class OrderResponse(BaseModel):
    id: str
    user_id: str
    items: List[OrderItem]
    total_amount: float
    status: str
    shipping_address: str
    created_at: datetime
    updated_at: Optional[datetime] = None

# In-memory storage (replace with database in production)
orders = [
    {
        "id": "1",
        "user_id": "1",
        "items": [
            {"product_id": "prod-1", "quantity": 2, "price": 29.99}
        ],
        "total_amount": 59.98,
        "status": "pending",
        "shipping_address": "123 Main St, City, Country",
        "created_at": datetime.now(),
        "updated_at": None
    }
]

# Middleware for metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "order-service",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

# Readiness probe
@app.get("/ready")
async def readiness_check():
    return {
        "status": "ready",
        "service": "order-service"
    }

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    return Response(
        generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

# Get all orders
@app.get("/api/orders", response_model=List[OrderResponse])
async def get_orders():
    try:
        return orders
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

# Get order by ID
@app.get("/api/orders/{order_id}", response_model=OrderResponse)
async def get_order(order_id: str):
    try:
        order = next((o for o in orders if o["id"] == order_id), None)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        return order
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

# Create new order
@app.post("/api/orders", response_model=OrderResponse, status_code=201)
async def create_order(order_data: OrderCreate):
    try:
        # Calculate total amount
        total_amount = sum(item.price * item.quantity for item in order_data.items)
        
        new_order = {
            "id": str(uuid.uuid4()),
            "user_id": order_data.user_id,
            "items": [item.dict() for item in order_data.items],
            "total_amount": total_amount,
            "status": "pending",
            "shipping_address": order_data.shipping_address,
            "created_at": datetime.now(),
            "updated_at": None
        }
        
        orders.append(new_order)
        return new_order
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

# Update order status
@app.patch("/api/orders/{order_id}")
async def update_order_status(order_id: str, status: str):
    try:
        order = next((o for o in orders if o["id"] == order_id), None)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        valid_statuses = ["pending", "processing", "shipped", "delivered", "cancelled"]
        if status not in valid_statuses:
            raise HTTPException(status_code=400, detail="Invalid status")
        
        order["status"] = status
        order["updated_at"] = datetime.now()
        
        return {"success": True, "data": order}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

# Get orders by user
@app.get("/api/users/{user_id}/orders", response_model=List[OrderResponse])
async def get_user_orders(user_id: str):
    try:
        user_orders = [o for o in orders if o["user_id"] == user_id]
        return user_orders
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

# Delete order
@app.delete("/api/orders/{order_id}")
async def delete_order(order_id: str):
    try:
        order_index = next((i for i, o in enumerate(orders) if o["id"] == order_id), None)
        if order_index is None:
            raise HTTPException(status_code=404, detail="Order not found")
        
        deleted_order = orders.pop(order_index)
        return {"success": True, "data": deleted_order}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 3002))
    uvicorn.run(app, host="0.0.0.0", port=port) 