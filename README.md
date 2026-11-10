# Rails Task Manager - Docker, Kubernetes & Load Testing

Built a Ruby on Rails 8.1.4.1, PostgreSQL 16, Task Manager CRUD Web Application and JSON API. The application is packed in a multi-stage Docker build, executed locally as a multi-container application using Docker Compose, deployed with NGINX Ingress and Horizontal Pod Autoscaling (HPA) to a cluster of Kubernetes (Minikube) and stress-tested using Grafana k6 with 500 concurrent users.

## Tech Stack

- **Language:** Ruby 3.3 (`ruby:3.3` builder stage, `ruby:3.3-slim` runtime stage)
- **Framework:** Ruby on Rails 8.1.4.1
- **Web Server:** Puma 6.6.1 (Port 3000, configurable threads and workers)
- **Database:** PostgreSQL 16 (`postgres:16`)
- **Containerization:** Docker & Docker Compose
- **Orchestration:** Kubernetes (Minikube, NGINX Ingress, Metrics Server, HPA v2)
- **Testing & Monitoring:** Bash (`curl`), Grafana k6, and Python (`kubectl top` AUC visualizer)

## Repository Structure

```text
DevOps_Final_Project/
├── app/                        # Rails MVC controllers, models, and HTML views
├── bin/
│   └── docker-entrypoint       # Container startup script (runs db:prepare before Puma)
├── config/
│   ├── database.yml            # PostgreSQL connection settings and pool configuration
│   ├── puma.rb                 # Puma server port (3000), threads (5), and worker config
│   └── routes.rb               # Defines /up health check and /tasks CRUD routes
├── db/
│   └── migrate/                # PostgreSQL schema migration for the tasks table
├── k8s/
│   ├── deployment.yaml         # Rails Deployment, probes, resource limits, Postgres & 1Gi PVC
│   ├── service.yaml            # Two ClusterIP services (rails-crud-service & postgres-service)
│   ├── ingress.yaml            # NGINX Ingress routing HTTP port 80 to rails-crud-service
│   └── hpa.yaml                # HorizontalPodAutoscaler (1 to 5 pods at 50% CPU / 75% RAM)
├── tests/
│   ├── functional_test.sh      # Automated end-to-end CRUD API validation script
│   ├── load_test.js            # Grafana k6 load test (500 virtual users for 200 seconds)
│   ├── auc_visualizer.py       # Terminal Area Under the Curve (AUC) monitor for CPU & RAM
│   └── pod_metrics.log         # Recorded pod CPU and memory usage during load testing
├── .dockerignore               # Excludes git, logs, tmp, k8s, and test files from image build
├── Dockerfile                  # Multi-stage build running as non-root user (rails, UID 1000)
├── docker-compose.yaml         # Local setup for web and db with persistent volume & healthcheck
└── Gemfile                     # Ruby gem dependencies locked to Rails 8.1.4.1
```

## Application Endpoints

- `GET /` - Browser HTML interface for creating, editing, completing, and deleting tasks
- `GET /up` - Built-in Rails health check endpoint (returns `HTTP 200 OK` when healthy)
- `GET /tasks.json` - List all tasks in JSON format
- `POST /tasks.json` - Create a new task
- `PATCH /tasks/:id.json` - Update an existing task
- `DELETE /tasks/:id.json` - Delete a task

---

## Running Locally with Docker Compose

1. Build the multi-stage Docker image and start the Rails and PostgreSQL containers in the background:

```bash
docker compose up --build -d
```

2. Check that both containers are running and marked as `(healthy)`:

```bash
docker compose ps
```

3. Verify the health endpoint and open the application in your browser:

```bash
curl -i http://localhost:3000/up
```

- Web UI: `http://localhost:3000`

4. Stop the containers when finished:

```bash
docker compose down
```

---

## Deploying to Kubernetes (Minikube)

1. Start Minikube and enable the NGINX Ingress and Metrics Server addons:

```bash
minikube start
minikube addons enable metrics-server
minikube addons enable ingress
```

2. Build the production image locally and load it into the Minikube cluster:

```bash
docker build -t rails-crud-app:latest .
minikube image load rails-crud-app:latest
```

3. Apply all Kubernetes manifests in the `k8s/` folder:

```bash
kubectl apply -f k8s/
```

4. Check the status of deployments, pods, services, ingress, HPA, and persistent volume claims:

```bash
kubectl get deployments,pods,svc,ingress,hpa,pvc
```

5. Forward port 3000 to access the web interface locally in a browser:

```bash
kubectl port-forward svc/rails-crud-service 3000:3000
```

---

## Functional Validation & Load Testing

### 1. Automated Functional CRUD Test

With the service accessible on port 3000, run the functional validation script to test health, create, read, update, and delete operations:

```bash
BASE_URL=http://localhost:3000 ./tests/functional_test.sh
```

### 2. High-Concurrency Load Test (Grafana k6)

Run the k6 stress test (500 concurrent virtual users for 200 seconds) inside the Minikube Docker network against the cluster Ingress IP:

```bash
docker run -i --rm --net minikube -e BASE_URL=http://$(minikube ip) grafana/k6 run - < tests/load_test.js
```

### 3. Live Pod Resource Monitoring & HPA Scaling

While the load test is running, open a second terminal to watch live CPU/Memory usage and Horizontal Pod Autoscaler replicas scaling up:

```bash
kubectl top pods && kubectl get hpa && kubectl get pods
```

To record live metrics and print the terminal Area Under the Curve (AUC) charts for CPU and RAM:

```bash
python3 tests/auc_visualizer.py --record
```

## Summary of Load Test Findings

- **Single-Pod Concurrency Limit:** By default, Puma is configured to run in single process mode (`workers = 0`) (in this mode, no Ruby processes run). In addition it has by default single threaded operation: `RAILS_MAX_THREADS = 5` and `connection pool to PostgreSQL = 5`. While < 500 virtual users are running the CPU usage is close to 50% of the hardware limits (pod CPU (~133m / 500m)) and the RAM usage is well below the limits (pod RAM (~92Mi / 512Mi)), 495 virtual users are waiting in the TCP socket queue and the queue timeouts.
- **Autoscaling & Tuning:** When the CPU usage of a pod surpasses the `50m` threshold ( 50% of the `100m` CPU request level), the Horizontal Pod Autoscaler (`k8s/hpa.yaml`) automatically increases the number of pods from 1 to 3-5. This enables the cluster to contain more concurrent threads (`WEB_CONCURRENCY=4` workers + RAILS_MAX_THREADS=16) and eliminates queue contention.
