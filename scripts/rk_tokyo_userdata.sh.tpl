#!/bin/bash
set -e

# 도커 설치
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# 스왑 메모리 2GB
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab

# 현재 EC2 IP 가져오기 (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
MY_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

# 서울 Redis/Kafka IP (Terraform이 주입)
SEOUL_IP="${seoul_rk_ip}"

mkdir -p /opt/notecurve

cat > /opt/notecurve/docker-compose.yml << COMPOSE
version: '3.8'
services:
  redis:
    image: redis:7
    container_name: redis-replica
    restart: always
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - notecurve-network

  kafka:
    image: apache/kafka:3.7.0
    container_name: kafka
    restart: always
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      KAFKA_NODE_ID: 2
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://$${MY_IP}:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 2@kafka:9093
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xmx512m -Xms256m"
    networks:
      - notecurve-network

  mirrormaker:
    image: apache/kafka:3.7.0
    container_name: mirrormaker2
    restart: always
    depends_on:
      - kafka
    command: /opt/kafka/bin/connect-mirror-maker.sh /opt/notecurve/mm2.properties
    volumes:
      - /opt/notecurve/mm2.properties:/opt/notecurve/mm2.properties
    networks:
      - notecurve-network

volumes:
  redis-data:

networks:
  notecurve-network:
    driver: bridge
COMPOSE

cat > /opt/notecurve/mm2.properties << MM2
clusters = seoul, tokyo
seoul.bootstrap.servers = $SEOUL_IP:9092
tokyo.bootstrap.servers = localhost:9092
seoul->tokyo.enabled = true
seoul->tokyo.topics = .*
replication.factor = 1
MM2

# Redis + Kafka 먼저 실행 후 안정화 대기
cd /opt/notecurve && docker compose up -d redis kafka
echo "Docker 컨테이너 안정화 대기 중..."
sleep 30

# Redis Replica 연결
docker exec redis-replica redis-cli replicaof $SEOUL_IP 6379
echo "Redis Replica 연결 완료: $SEOUL_IP"

# MirrorMaker2 실행
cd /opt/notecurve && docker compose up -d mirrormaker
echo "MirrorMaker2 시작 완료"

# 장애 시 Master 승격 스크립트
cat > /opt/notecurve/promote-to-master.sh << SCRIPT
#!/bin/bash
echo "=== 도쿄 Redis Master 승격 ==="
docker exec redis-replica redis-cli replicaof no one
echo "Redis Master 승격 완료"
cd /opt/notecurve && docker compose stop mirrormaker
echo "MirrorMaker2 중단 완료"
echo "=== 도쿄가 Master로 전환됐습니다 ==="
SCRIPT
chmod +x /opt/notecurve/promote-to-master.sh
