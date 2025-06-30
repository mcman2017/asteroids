# Asteroids Game - Kubernetes Deployment

A classic Asteroids game built with HTML5 Canvas and JavaScript, featuring a Node.js API backend with PostgreSQL for high score persistence. Designed for containerized deployment on Kubernetes using Podman and Helm.

## 🎮 Features

- ✅ **Classic Asteroids Gameplay** with HTML5 Canvas and JavaScript
- ✅ **High Score System** with PostgreSQL persistence
- ✅ **Sound Effects** with Web Audio API (user-activated)
- ✅ **Responsive Design** with modern web standards
- ✅ **Containerized Architecture** using Podman for security
- ✅ **Production-Ready Deployment** with Helm charts
- ✅ **HTTPS Support** with automatic SSL certificates
- ✅ **Database Persistence** with configurable storage
- ✅ **Health Monitoring** and graceful shutdown

## 🏗️ Architecture

```
Internet → Nginx Ingress → Frontend (Nginx) → Backend API (Node.js) → PostgreSQL
                ↓
            Static Game Files (HTML/JS/CSS)
                ↓
            High Score API (/api/highscores)
                ↓
            Persistent Database Storage
```

## 📋 Prerequisites

- **Kubernetes Cluster** (tested on MicroK8s)
- **Helm 3.x** installed
- **kubectl** configured for your cluster
- **Podman** installed (for container building)
- **Ingress Controller** (nginx recommended)
- **Cert-Manager** (for SSL certificates)
- **Storage Class** available for PostgreSQL

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <your-private-repo>
cd asteroids-k8s
```

### 2. Install Dependencies
```bash
# Install Podman (macOS)
brew install podman
podman machine init
podman machine start

# Or use the setup script
./scripts/setup-podman.sh
```

### 3. Build Container Images
```bash
# Build all images
./scripts/build-images.sh

# Or build individually
./scripts/build-images.sh --frontend-only
./scripts/build-images.sh --backend-only
```

### 4. Configure Deployment
```bash
# Copy example configuration
cp examples/values-production.yaml my-values.yaml

# Edit configuration
nano my-values.yaml
```

### 5. Deploy Asteroids Game
```bash
# Deploy with default configuration
./scripts/deploy-asteroids.sh

# Or deploy with custom values
./scripts/deploy-asteroids.sh my-values.yaml
```

## 📁 Directory Structure

```
asteroids-k8s/
├── README.md                          # This file
├── CHANGELOG.md                       # Version history
├── helm-chart/                        # Helm chart for deployment
│   └── asteroids/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── scripts/                           # Management scripts
│   ├── build-images.sh               # Container image building
│   ├── deploy-asteroids.sh           # Main deployment script
│   ├── setup-podman.sh               # Podman installation
│   └── manage-database.sh            # Database management
├── src/                              # Source code
│   ├── frontend/                     # Game frontend files
│   │   ├── asteroids.html
│   │   ├── asteroids.js
│   │   └── styles.css
│   └── backend/                      # API backend files
│       ├── api-server.js
│       ├── package.json
│       └── database/
├── docker/                           # Container definitions
│   ├── frontend/
│   │   └── Dockerfile
│   └── backend/
│       └── Dockerfile
├── examples/                         # Configuration examples
│   ├── values-production.yaml
│   └── values-development.yaml
└── docs/                            # Documentation
    ├── CONFIGURATION.md
    ├── TROUBLESHOOTING.md
    └── GAME_FEATURES.md
```

## ⚙️ Configuration

### Basic Configuration (values.yaml)

```yaml
# Domain Configuration
ingress:
  enabled: true
  hosts:
  - host: asteroids.yourdomain.com
    paths:
    - path: /
      pathType: Prefix

# Database Configuration
postgresql:
  enabled: true
  persistence:
    enabled: true
    size: 5Gi
    storageClass: "your-storage-class"

# Frontend Configuration
frontend:
  image:
    repository: your-registry/asteroids-frontend
    tag: "latest"

# Backend Configuration
backend:
  image:
    repository: your-registry/asteroids-backend
    tag: "latest"
```

## 🎮 Game Features

### Gameplay
- **Classic Asteroids Mechanics**: Ship rotation, thrust, shooting
- **Progressive Difficulty**: Increasing asteroid count per level
- **Lives System**: 3 lives with respawn mechanics
- **Score System**: Points for destroying asteroids and UFOs
- **Hyperspace**: Emergency teleportation (risky!)

### Controls
- **Arrow Keys**: Ship movement and rotation
- **Spacebar**: Fire weapons
- **Up Arrow**: Thrust forward
- **Down Arrow**: Hyperspace jump
- **Mouse Click**: Sound toggle activation

### Audio
- **Sound Effects**: Shooting, explosions, thrust, UFO sounds
- **User-Activated**: Complies with browser autoplay policies
- **Toggle Control**: Easy sound on/off switching

### High Scores
- **Persistent Storage**: PostgreSQL database backend
- **Top 20 Scores**: Automatic cleanup of lower scores
- **3-Character Initials**: Classic arcade-style entry
- **Real-time Updates**: Immediate score submission

## 🔧 Management Scripts

### Build Container Images
```bash
./scripts/build-images.sh [OPTIONS]

Options:
  --frontend-only    Build only frontend image
  --backend-only     Build only backend image
  --push            Push images to registry
  --tag TAG         Use specific tag (default: latest)
```

### Deploy Game
```bash
./scripts/deploy-asteroids.sh [VALUES_FILE]

Examples:
  ./scripts/deploy-asteroids.sh                    # Default values
  ./scripts/deploy-asteroids.sh my-values.yaml     # Custom values
  ./scripts/deploy-asteroids.sh --upgrade          # Upgrade existing
```

### Database Management
```bash
./scripts/manage-database.sh [COMMAND]

Commands:
  backup     Create database backup
  restore    Restore from backup
  reset      Reset high scores
  status     Show database status
```

## 🐛 Troubleshooting

### Common Issues

#### Game Won't Load
```bash
# Check frontend pod
kubectl logs -n asteroids -l app=asteroids-frontend

# Check ingress
kubectl get ingress -n asteroids
```

#### High Scores Not Saving
```bash
# Check backend API
kubectl logs -n asteroids -l app=asteroids-backend

# Check database connection
kubectl exec -n asteroids deployment/asteroids-backend -- nc -zv postgres-service 5432
```

#### Sound Not Working
- **Browser Policy**: User must interact with page first
- **Click Sound Toggle**: The 🔇 icon to enable audio
- **Check Console**: Browser developer tools for audio errors

#### Container Build Issues
```bash
# Check Podman status
podman --version
podman machine list

# Test basic build
podman build -t test-image docker/frontend/
```

## 🔒 Security Features

### Container Security
- **Rootless Containers**: Podman runs without root privileges
- **Minimal Base Images**: Alpine Linux for smaller attack surface
- **Non-root User**: Application runs as non-privileged user
- **Read-only Filesystem**: Where possible

### Network Security
- **HTTPS Only**: Automatic SSL certificate management
- **Security Headers**: HSTS, CSP, and other protective headers
- **Network Policies**: Restrict pod-to-pod communication
- **Ingress Protection**: Rate limiting and DDoS protection

### Database Security
- **Credential Management**: Kubernetes secrets for passwords
- **Connection Encryption**: TLS for database connections
- **Input Validation**: SQL injection prevention
- **Backup Encryption**: Encrypted database backups

## 📊 Monitoring

### Health Checks
```bash
# Check all components
kubectl get all -n asteroids

# Monitor logs
kubectl logs -n asteroids -l app=asteroids-frontend -f
kubectl logs -n asteroids -l app=asteroids-backend -f
kubectl logs -n asteroids -l app=postgresql -f
```

### Performance Metrics
- **Response Time**: API endpoint performance
- **Database Queries**: High score retrieval speed
- **Resource Usage**: CPU and memory consumption
- **Error Rates**: Application and database errors

## 🔄 Updates

### Update Game Version
1. Update source code in `src/` directory
2. Build new container images: `./scripts/build-images.sh --push`
3. Update image tags in values file
4. Deploy update: `./scripts/deploy-asteroids.sh --upgrade`

### Update Configuration
1. Edit your values file
2. Run deployment script
3. Verify changes: `kubectl get all -n asteroids`

## 🎯 Development

### Local Development
```bash
# Run frontend locally
cd src/frontend
python3 -m http.server 8000

# Run backend locally
cd src/backend
npm install
npm start
```

### Testing
```bash
# Test container builds
./scripts/build-images.sh --test

# Test deployment
./scripts/deploy-asteroids.sh --dry-run
```

## 📚 Additional Resources

- [HTML5 Canvas Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
- [Web Audio API Guide](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Podman Documentation](https://podman.io/docs)

## 🤝 Contributing

This is a private repository for personal/organizational use. For improvements:

1. Test changes thoroughly in development environment
2. Update documentation as needed
3. Follow container security best practices
4. Maintain backward compatibility

## 📄 License

Private repository - All rights reserved.

## 🆘 Support

For support with this deployment:
1. Check troubleshooting documentation
2. Review pod logs and status
3. Verify configuration files
4. Test with minimal configuration

---

**🎮 Ready to play?** Deploy your asteroids game and enjoy the classic arcade experience on your Kubernetes cluster!
