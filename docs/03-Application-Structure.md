# Application Structure

This document provides a detailed overview of each microservice in the e-commerce application.

## Project Structure

```
ecommerce-microservices-k8s/
├── offers-microservice-spring-boot/    # Offers management service
├── shoes-microservice-spring-boot/     # Product catalog service
├── cart-microservice-nodejs/           # Shopping cart service
├── wishlist-microservice-python/       # Wishlist management service
├── zuul-api-gateway/                   # API Gateway
├── ui-web-app-reactjs/                 # Frontend application
├── helm-charts/                        # Helm deployment charts
│   └── ecommerce-app/
├── docker-compose.yaml                 # Local development setup
└── docs/                              # Documentation
```

## Microservices Details

### 1. Offers Microservice (Spring Boot)

**Technology**: Java 11, Spring Boot  
**Port**: 1001  
**Purpose**: Manages product offers and promotional content

#### Directory Structure
```
offers-microservice-spring-boot/
├── src/
│   ├── main/
│   │   ├── java/com/microservices/offers/
│   │   │   ├── OffersApplication.java          # Main application class
│   │   │   └── controllers/
│   │   │       └── OffersController.java       # REST API endpoints
│   │   └── resources/
│   │       └── application.properties          # Configuration
│   └── test/                                   # Unit tests
├── Dockerfile                                  # Container image definition
├── pom.xml                                     # Maven dependencies
└── README.md
```

#### Key Features
- RESTful API for offers management
- CORS enabled for cross-origin requests
- Runs on port 1001
- Provides endpoints:
  - `GET /api/offers` - List all offers
  - `GET /api/offers/{id}` - Get specific offer

#### Configuration (application.properties)
```properties
server.port=1001
spring.application.name=offers-service
```

#### API Examples
```bash
# Get all offers
curl http://localhost:1001/api/offers

# Get specific offer
curl http://localhost:1001/api/offers/1
```

---

### 2. Shoes Microservice (Spring Boot)

**Technology**: Java 11, Spring Boot  
**Port**: 1002  
**Purpose**: Product catalog management for shoes

#### Directory Structure
```
shoes-microservice-spring-boot/
├── src/
│   ├── main/
│   │   ├── java/com/microservices/shoes/
│   │   │   ├── ShoesApplication.java           # Main application class
│   │   │   └── controllers/
│   │   │       └── ShoeController.java         # REST API endpoints
│   │   └── resources/
│   │       └── application.properties          # Configuration
│   └── test/                                   # Unit tests
├── Dockerfile                                  # Container image definition
├── pom.xml                                     # Maven dependencies
└── README.md
```

#### Key Features
- Product catalog REST API
- CORS enabled
- Runs on port 1002
- Provides endpoints:
  - `GET /api/shoes` - List all shoes
  - `GET /api/shoes/{id}` - Get shoe details
  - `POST /api/shoes` - Add new shoe (if implemented)

#### Configuration (application.properties)
```properties
server.port=1002
spring.application.name=shoes-service
```

#### API Examples
```bash
# Get all shoes
curl http://localhost:1002/api/shoes

# Get specific shoe
curl http://localhost:1002/api/shoes/1
```

---

### 3. Cart Microservice (Node.js)

**Technology**: Node.js, Express  
**Port**: 1004  
**Purpose**: Shopping cart management

#### Directory Structure
```
cart-microservice-nodejs/
├── src/
│   └── routes/
│       ├── index.js                            # Route definitions
│       └── cart/
│           └── cart.js                         # Cart logic
├── index.js                                    # Application entry point
├── package.json                                # npm dependencies
├── Dockerfile                                  # Container image definition
└── README.md
```

#### Key Features
- Express.js REST API
- Shopping cart operations
- Runs on port 1004
- Provides endpoints:
  - `GET /api/cart` - Get cart items
  - `POST /api/cart` - Add item to cart
  - `DELETE /api/cart/{id}` - Remove item from cart
  - `PUT /api/cart/{id}` - Update cart item

#### Dependencies (package.json)
```json
{
  "name": "cart-microservice",
  "dependencies": {
    "express": "^4.x",
    "cors": "^2.x",
    "body-parser": "^1.x"
  }
}
```

#### API Examples
```bash
# Get cart
curl http://localhost:1004/api/cart

# Add to cart
curl -X POST http://localhost:1004/api/cart \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}'
```

---

### 4. Wishlist Microservice (Python)

**Technology**: Python 3, Flask  
**Port**: 1003  
**Purpose**: User wishlist management

#### Directory Structure
```
wishlist-microservice-python/
├── index.py                                    # Flask application
├── Dockerfile                                  # Container image definition
└── README.md
```

#### Key Features
- Flask REST API
- Wishlist CRUD operations
- CORS enabled (flask_cors)
- Runs on port 1003
- Provides endpoints:
  - `GET /api/wishlist` - Get wishlist items
  - `POST /api/wishlist` - Add item to wishlist
  - `DELETE /api/wishlist/{id}` - Remove from wishlist

#### Dependencies
```python
# Requirements
flask
flask_cors
```

#### API Examples
```bash
# Get wishlist
curl http://localhost:1003/api/wishlist

# Add to wishlist
curl -X POST http://localhost:1003/api/wishlist \
  -H "Content-Type: application/json" \
  -d '{"productId": 1}'
```

---

### 5. Zuul API Gateway (Spring Boot)

**Technology**: Java 11, Spring Boot, Netflix Zuul  
**Port**: 9999  
**Purpose**: API Gateway for routing and load balancing

#### Directory Structure
```
zuul-api-gateway/
├── src/
│   ├── main/
│   │   ├── java/com/apigateway/zuul/
│   │   │   └── ZuulApplication.java            # Main application with @EnableZuulProxy
│   │   └── resources/
│   │       ├── application.properties          # Basic configuration
│   │       └── application.yml                 # Routing rules
│   └── test/
├── Dockerfile
├── pom.xml
└── README.md
```

#### Key Features
- Central entry point for all API requests
- Request routing to appropriate microservices
- Load balancing
- Cross-cutting concerns (logging, security, etc.)

#### Configuration (application.yml)
```yaml
server:
  port: 9999

zuul:
  routes:
    offers:
      path: /api/offers/**
      url: http://offers:1001
    shoes:
      path: /api/shoes/**
      url: http://shoes:1002
    cart:
      path: /api/cart/**
      url: http://cart:1004
    wishlist:
      path: /api/wishlist/**
      url: http://wishlist:1003
```

#### Routing Examples
```bash
# All requests go through the gateway
# Client -> Gateway -> Service

# Get offers (routed to offers service)
curl http://localhost:9999/api/offers

# Get shoes (routed to shoes service)
curl http://localhost:9999/api/shoes

# Cart operations (routed to cart service)
curl http://localhost:9999/api/cart
```

---

### 6. UI Web App (React.js)

**Technology**: React.js, Webpack  
**Port**: 8080  
**Purpose**: Frontend user interface

#### Directory Structure
```
ui-web-app-reactjs/
├── src/
│   ├── components/
│   │   └── App.jsx                             # Main React component
│   ├── helpers/
│   │   └── index.js                            # Utility functions
│   ├── styles/
│   │   ├── _global.scss                        # Global styles
│   │   └── styles.scss                         # Component styles
│   ├── entry.jsx                               # Application entry point
│   └── index.ejs                               # HTML template
├── webpack.config.js                           # Webpack configuration
├── package.json                                # npm dependencies
├── Dockerfile
└── README.md
```

#### Key Features
- Single Page Application (SPA)
- React components for UI
- Webpack bundling
- Communicates with API Gateway
- Responsive design

#### Dependencies (package.json)
```json
{
  "name": "ui-web-app",
  "dependencies": {
    "react": "^17.x",
    "react-dom": "^17.x",
    "axios": "^0.x"
  },
  "devDependencies": {
    "webpack": "^5.x",
    "babel-loader": "^8.x"
  }
}
```

#### Build Process
```bash
# Install dependencies
npm install

# Build for production
npm run build

# Development mode
npm start
```

---

## Service Communication Flow

### Request Flow Diagram

```
User Browser
     │
     ▼
UI Web App (React) :8080
     │
     ▼
Zuul Gateway :9999
     │
     ├─────────────┬─────────────┬──────────────┐
     ▼             ▼             ▼              ▼
Offers :1001   Shoes :1002   Cart :1004   Wishlist :1003
(Spring Boot)  (Spring Boot)  (Node.js)    (Python)
```

### Communication Patterns

1. **Client → UI**: User interacts with React application
2. **UI → Gateway**: All API calls go through Zuul Gateway
3. **Gateway → Services**: Gateway routes requests to appropriate microservice
4. **Services → Gateway → UI**: Responses flow back through gateway

### Example Complete Flow

```
1. User opens browser → UI App loads (React)
2. UI requests products → GET http://ui:8080/
3. UI calls API → GET http://gateway:9999/api/shoes
4. Gateway routes → GET http://shoes:1002/api/shoes
5. Shoes service responds → JSON data
6. Gateway forwards response → UI App
7. UI displays products → User sees products
```

## Port Mapping Summary

| Service | Internal Port | External Port (NodePort/LoadBalancer) |
|---------|--------------|--------------------------------------|
| UI Web App | 8080 | 30080 (NodePort) |
| Zuul Gateway | 9999 | 30999 (if exposed) |
| Offers | 1001 | Internal only |
| Shoes | 1002 | Internal only |
| Wishlist | 1003 | Internal only |
| Cart | 1004 | Internal only |

## Environment Variables

Each service can be configured using environment variables:

### Common Variables
```bash
# Spring Boot services
JAVA_OPTS="-Xmx512m -Xms256m"
SERVER_PORT=1001

# Node.js services
NODE_ENV=production
PORT=1004

# Python services
FLASK_ENV=production
FLASK_APP=index.py
```

## Health Checks

Each service should implement health check endpoints:

```bash
# Spring Boot (auto-configured with Actuator)
GET /actuator/health

# Node.js (custom implementation)
GET /health

# Python Flask (custom implementation)
GET /health
```

## Next Steps

Proceed to [04-Containerization.md](./04-Containerization.md) to learn how to containerize these microservices with Docker.
