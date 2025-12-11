from datetime import datetime, timedelta
import boto3
import os

rds = boto3.client('rds')
cloudwatch = boto3.client('cloudwatch')

PRIMARY_ID = os.environ['PRIMARY_ID']
MAX_REPLICAS = int(os.environ.get('MAX_REPLICAS', 5))
MIN_REPLICAS = int(os.environ.get('MIN_REPLICAS', 1))
CPU_THRESHOLD_UP = float(os.environ.get('CPU_THRESHOLD_UP', 70.0))  # % 이상이면 Replica 추가
CPU_THRESHOLD_DOWN = float(os.environ.get('CPU_THRESHOLD_DOWN', 30.0))  # % 이하이면 Replica 삭제

def get_primary_cpu():
    # CloudWatch에서 최근 CPUUtilization 평균 값 조회 (마지막 5분)
    metrics = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        MetricName='CPUUtilization',
        Dimensions=[{'Name':'DBInstanceIdentifier','Value':PRIMARY_ID}],
        StartTime=datetime.utcnow() - timedelta(minutes=5),
        EndTime=datetime.utcnow(),
        Period=300,
        Statistics=['Average']
    )
    datapoints = metrics.get('Datapoints', [])
    if datapoints:
        return datapoints[-1]['Average']
    return 0.0

def lambda_handler(event, context):
    cpu = get_primary_cpu()
    
    # 현재 Read Replica 목록 조회
    instances = rds.describe_db_instances()['DBInstances']

    current_replicas = [
        i['DBInstanceIdentifier']
        for i in instances
        if i.get('ReadReplicaSourceDBInstanceIdentifier') == PRIMARY_ID
    ]
    
    desired_replicas = len(current_replicas)
    
    # CPU가 높으면 Replica 추가
    if cpu > CPU_THRESHOLD_UP and len(current_replicas) < MAX_REPLICAS:
        new_id = f"{PRIMARY_ID}-read-{len(current_replicas)+1}"
        rds.create_db_instance_read_replica(
            DBInstanceIdentifier=new_id,
            SourceDBInstanceIdentifier=PRIMARY_ID,
            DBInstanceClass='db.t3.medium',
            PubliclyAccessible=False
        )
        desired_replicas += 1
        print(f"Creating Read Replica: {new_id}")
    
    # CPU가 낮으면 Replica 삭제
    elif cpu < CPU_THRESHOLD_DOWN and len(current_replicas) > MIN_REPLICAS:
        del_id = current_replicas[-1]  # 가장 마지막 Replica 제거
        rds.delete_db_instance(DBInstanceIdentifier=del_id, SkipFinalSnapshot=True)
        desired_replicas -= 1
        print(f"Deleting Read Replica: {del_id}")
    
    return {
        "status": "Success",
        "cpu": cpu,
        "current_replicas": current_replicas,
        "desired_replicas": desired_replicas
    }
