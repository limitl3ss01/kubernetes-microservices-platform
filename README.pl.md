# Platforma Microservices Kubernetes

## 🚀 Architektura Microservices na Poziomie Enterprise

Kompleksowa platforma microservices demonstrująca zaawansowaną orkiestrację Kubernetes, nowoczesne praktyki DevOps oraz architekturę cloud-native. Ten projekt pokazuje produkcyjną infrastrukturę z wielojęzycznymi microservices, automatycznym skalowaniem i kompleksowym monitoringiem.

## 📋 Przegląd Architektury

### Stack Microservices
- **User Service** - Zarządzanie użytkownikami i uwierzytelnianie (Node.js/Express)
- **Order Service** - Przetwarzanie zamówień i logika biznesowa (Python/FastAPI)  
- **Notification Service** - Powiadomienia w czasie rzeczywistym (Go/Gin)
- **API Gateway** - Kong dla routingu, bezpieczeństwa i rate limiting

### Komponenty Infrastruktury
- **Kubernetes** - Orkiestracja i zarządzanie kontenerami
- **Istio** - Service mesh dla zaawansowanego zarządzania ruchem
- **ArgoCD** - GitOps continuous delivery
- **Prometheus + Grafana** - Monitoring i observability
- **Jaeger** - Distributed tracing
- **Kiali** - Observability service mesh

## 🏗️ Kluczowe Funkcje

### Możliwości Produkcyjne
- ✅ **Auto-scaling** (HPA/VPA) z inteligentnym zarządzaniem zasobami
- ✅ **Load balancing** z Istio service mesh
- ✅ **Service discovery** i health checks
- ✅ **Circuit breaker patterns** dla fault tolerance
- ✅ **Distributed tracing** z Jaeger
- ✅ **Centralized logging** i monitoring
- ✅ **Security** z RBAC, network policies i mTLS

### Doskonałość DevOps
- ✅ **GitOps** z ArgoCD dla automatycznych deploymentów
- ✅ **CI/CD pipelines** z GitHub Actions
- ✅ **Infrastructure as Code** z manifestami Kubernetes
- ✅ **Monitoring** z Prometheus Operator
- ✅ **Alerting** z AlertManager
- ✅ **Multi-environment** deployment (dev/staging/prod)

## 📊 Metryki Wydajności

| Metryka | Cel | Implementacja |
|---------|-----|---------------|
| **Dostępność** | 99.9% | Health checks, auto-scaling, circuit breakers |
| **Czas Odpowiedzi** | <200ms p95 | Optymalizacja Istio, caching |
| **Przepustowość** | 1000+ RPS | Load balancing, horizontal scaling |
| **Współczynnik Błędów** | <0.1% | Monitoring, alerting, auto-recovery |
| **Czas Deploymentu** | <5 minut | GitOps, automatyczne pipeline'y |
| **Czas Rollback** | <2 minuty | ArgoCD, health checks |

## 🛠️ Szybki Start

### Wymagania
```bash
# Klaster Kubernetes
minikube start --cpus=4 --memory=7000 --disk-size=20g

# Wymagane narzędzia
kubectl, docker, make
```

### Deployment Jedną Komendą
```bash
# Sklonuj repozytorium
git clone https://github.com/limitl3ss01/kubernetes-microservices-platform.git
cd kubernetes-microservices-platform

# Wdróż platformę
make deploy-local
```

### Ręczny Deployment
```bash
# 1. Uruchom minikube
minikube start --cpus=4 --memory=7000 --disk-size=20g

# 2. Włącz dodatki
minikube addons enable ingress
minikube addons enable metrics-server

# 3. Utwórz namespace'y
kubectl create namespace microservices-platform
kubectl create namespace monitoring

# 4. Zbuduj i wdróż usługi
make build
make deploy

# 5. Skonfiguruj port forwarding
kubectl port-forward -n microservices-platform svc/user-service 3001:3001 &
kubectl port-forward -n microservices-platform svc/order-service 3002:3002 &
kubectl port-forward -n microservices-platform svc/notification-service 3003:3003 &
```

## 📈 Monitoring & Observability

- **Prometheus** - Metryki aplikacji i infrastruktury
- **Grafana** - Dashboards i wizualizacja
- **Jaeger** - Distributed tracing
- **Kiali** - Service mesh observability
- **AlertManager** - Alerting i powiadomienia

## 🔧 Development

### Lokalny Development
```bash
# Start minikube
minikube start

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# Deploy to local cluster
make deploy-local
```

### Production Deployment
```bash
# Deploy to production cluster
make deploy-prod
```

## 📈 Auto-scaling

- **HPA (Horizontal Pod Autoscaler)** - Auto-scaling based on CPU/memory
- **VPA (Vertical Pod Autoscaler)** - Resource optimization
- **Cluster Autoscaler** - Node scaling

## 🔒 Security

- **Network Policies** - Pod-to-pod communication
- **RBAC** - Role-based access control
- **Secrets Management** - Kubernetes secrets + external-secrets
- **Pod Security Standards** - PSP/PSS

## 📁 Struktura Projektu

```
├── k8s/                    # Kubernetes manifests
│   ├── base/              # Base configurations
│   ├── overlays/          # Environment-specific configs
│   └── helm/              # Helm charts
├── microservices/         # Application code
│   ├── api-gateway/
│   ├── user-service/
│   ├── order-service/
│   └── notification-service/
├── monitoring/            # Monitoring stack
│   ├── prometheus/
│   ├── grafana/
│   └── jaeger/
├── istio/                # Service mesh config
├── argocd/               # GitOps configuration
├── terraform/            # Infrastructure as Code
└── ci-cd/               # CI/CD pipelines
```

## 🎯 Metryki & KPI

- **Dostępność**: 99.9% uptime
- **Czas Odpowiedzi**: <200ms p95
- **Przepustowość**: 1000+ RPS
- **Współczynnik Błędów**: <0.1%

## 🔄 GitOps Workflow

1. **Code Push** → GitHub
2. **CI Pipeline** → Build & Test
3. **ArgoCD** → Auto-deploy to environments
4. **Monitoring** → Real-time observability

## 📚 Dokumentacja

- [Architecture Overview](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Monitoring Setup](docs/monitoring.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🌍 Wersje Językowe

- **English** - [README.md](README.md)
- **Polish** (current) - [README.pl.md](README.pl.md)

---

**Autor: zajaczek01** 