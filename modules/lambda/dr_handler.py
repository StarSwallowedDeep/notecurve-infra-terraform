import boto3
import os
import json

# 환경변수에서 설정값 가져오기
GLOBAL_CLUSTER_ID     = os.environ['GLOBAL_CLUSTER_ID']
SECONDARY_CLUSTER_ID  = os.environ['SECONDARY_CLUSTER_ID']
TOKYO_EC2_ID          = os.environ['TOKYO_RK_EC2_ID']
REGION_PRIMARY        = 'ap-northeast-2'  # 서울
REGION_SECONDARY      = 'ap-northeast-1'  # 도쿄

def lambda_handler(event, context):
    print(f"DR 자동화 시작. 이벤트: {json.dumps(event)}")

    results = {}

    # 1. Aurora Global DB 도쿄 승격
    try:
        rds = boto3.client('rds', region_name=REGION_PRIMARY)
        rds.failover_global_cluster(
            GlobalClusterIdentifier=GLOBAL_CLUSTER_ID,
            TargetDbClusterIdentifier=f'arn:aws:rds:{REGION_SECONDARY}:{get_account_id()}:cluster:{SECONDARY_CLUSTER_ID}'
        )
        print("Aurora 도쿄 승격 요청 완료")
        results['aurora'] = 'success'
    except Exception as e:
        print(f"Aurora 승격 실패: {e}")
        results['aurora'] = f'failed: {e}'

    # 2. 도쿄 Redis/Kafka EC2에 SSM으로 promote 스크립트 실행
    try:
        ssm = boto3.client('ssm', region_name=REGION_SECONDARY)
        response = ssm.send_command(
            InstanceIds=[TOKYO_EC2_ID],
            DocumentName='AWS-RunShellScript',
            Parameters={
                'commands': [
                    'sudo bash /opt/notecurve/promote-to-master.sh'
                ]
            }
        )
        command_id = response['Command']['CommandId']
        print(f"Redis/Kafka 승격 SSM 명령 전송 완료. CommandId: {command_id}")
        results['redis_kafka'] = 'success'
    except Exception as e:
        print(f"Redis/Kafka 승격 실패: {e}")
        results['redis_kafka'] = f'failed: {e}'

    # 3. SNS로 알림 전송
    try:
        sns = boto3.client('sns', region_name=REGION_PRIMARY)
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject='[DR 알림] 서울 장애 감지 - 도쿄 전환 시작',
            Message=f'''
서울 리전 장애가 감지되어 도쿄 리전으로 자동 전환을 시작했습니다.

처리 결과:
- Aurora 도쿄 승격: {results.get('aurora')}
- Redis/Kafka 승격: {results.get('redis_kafka')}

Route 53이 자동으로 트래픽을 도쿄로 전환합니다.
Aurora 승격 완료까지 약 1분 소요됩니다.

이벤트: {json.dumps(event, indent=2)}
            '''
        )
        print("SNS 알림 전송 완료")
        results['sns'] = 'success'
    except Exception as e:
        print(f"SNS 알림 실패: {e}")
        results['sns'] = f'failed: {e}'

    return {
        'statusCode': 200,
        'body': json.dumps(results)
    }

def get_account_id():
    sts = boto3.client('sts')
    return sts.get_caller_identity()['Account']
