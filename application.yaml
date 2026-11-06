application:
  name: payments-api
  image: myacr.azurecr.io/payments-api:1.2.0
  replicas: 3
  environment: production
  ports:
    - containerPort: 8080
  secrets:
    - name: DB_PASSWORD
      source: keyvault
      key: payments-db-password
    - name: API_KEY
      source: keyvault
      key: payments-api-key
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: "2"
      memory: 1Gi
  hpa:
    minReplicas: 3
    maxReplicas: 10
    targetCPU: 70   