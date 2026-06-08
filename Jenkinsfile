pipeline {
  agent any
  stages {
    stage('checkout')
           {
       steps {
            withVault(
          configuration: [
            vaultUrl: 'http://10.134.52.18:8200',
            vaultCredentialId: 'vault-cred-id'   // Jenkins credential ID from Step 5
          ],
          vaultSecrets: [[
            path: 'secret/jenkins/github',        // path you stored in Step 2
            engineVersion: 2,                     // because you enabled kv-v2
            secretValues: [[
              envVar: 'GITHUB_TOKEN',             // env var name in pipeline
              vaultKey: 'token'                   // key name you stored in Vault
            ]]
          ]]
        ) 
         {
      git branch: 'main',
          url: 'https://$GITHUB_TOKEN@github.com/Shrikant155/devsecops-project.git'
    }
         
          
       }
     }
    
     
     stage('sonarqube-test-code') {
            steps {
                withSonarQubeEnv('shrikant-sonar-scanner') {
                    sh '''
                        
                      /opt/sonar-scanner/bin/sonar-scanner 

                    '''
                }
            }
        }
       stage('build-image') {
        steps {
             sh 'docker build -t  k8s-app:v5 . '
           }
      }
         stage('trivy-scan') { 
         steps {
             sh '''
                trivy image --exit-code 1 --severity HIGH,CRITICAL k8s-app:v5
                '''  
             }
        }

      stage('docker push') { 
            steps {
                   steps {
            withVault(
          configuration: [
            vaultUrl: 'http://127.0.0.1:8200',
            vaultCredentialId: 'vault-cred-id'   // Jenkins credential ID from Step 5
          ],
          vaultSecrets: [[
            path: 'secret/jenkins/docker',        // path you stored in Step 2
            engineVersion: 2,                     // because you enabled kv-v2
            secretValues: [[
              envVar: 'GITHUB_TOKEN',             // env var name in pipeline
              vaultKey: 'token'                   // key name you stored in Vault
            ]]
          ]]
        )

         
               sh '''
                  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                  docker tag k8s-app:v5 shrikant155/k8s-app:v5
                  docker push  shrikant155/k8s-app:v5
                 '''
                }
              }
      }
stage('Start Minikube') {
    steps {
        sh '''
            minikube delete --all --purge || true
            minikube start --driver=docker --force --wait=all 
            minikube status
            kubectl apply -f deployment.yaml
            kubectl apply -f service.yaml
             # ✅ Fix 1 - correct deployment name
          kubectl rollout status deployment/k8s-project --timeout=120s

          # ✅ Fix 2 - wait until pod is READY
 kubectl wait --for=condition=ready pod \
        -l app=myproject1 \
        --timeout=120s
            kubectl get pods 
           kubectl get svc 
            minikube service k8s-service --url || true 
        '''
    }
  }
     stage('dast-scan') { 
      steps {
          sh '''
             # zap image install via docker 
               docker pull ghcr.io/zaproxy/zaproxy:stable
                #url of running app
               APP_URL=$(minikube service k8s-service --url)
                echo "Scanning app: $APP_URL"
 
          # Step 3 - Run ZAP scan and save report
       rm -rf zap-reports || true
      mkdir -p zap-reports

      chmod 777 zap-reports

 docker run --rm \
        --network=host \
        -v $(pwd)/zap-reports:/zap/wrk/:rw \
        -u root \
        ghcr.io/zaproxy/zaproxy:stable \
        zap-baseline.py \
        -t $APP_URL \
        -r zap-report.html \
        -I

      echo "ZAP Scan Done - Report saved in zap-reports/zap-report.html"
                 
       '''
     }
        post {
    always {
        publishHTML(target: [
        allowMissing: true,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: 'zap-reports',
        reportFiles: 'zap-report.html',
        reportName: 'ZAP Security Report'
      ])
    }
  }
     }
         stage('monitoring-check') {
      steps {
        sh '''
          echo "=== Checking Prometheus ==="
          curl -s http://localhost:9090/-/healthy && echo "Prometheus is UP" || echo "Prometheus is DOWN"

          echo "=== Checking Node Exporter ==="
          curl -s http://localhost:9100/metrics | head -5 && echo "Node Exporter is UP" || echo "Node Exporter is DOWN"

          echo "=== Checking Grafana ==="
          curl -s http://localhost:3000/api/health | grep ok && echo "Grafana is UP" || echo "Grafana is DOWN"

          echo "=== Prometheus Targets ==="
          curl -s http://localhost:9090/api/v1/targets | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data['data']['activeTargets']:
    print(t['labels']['job'], '-', t['health'])
"
        '''
      }
    }



    
 }

} 
        

