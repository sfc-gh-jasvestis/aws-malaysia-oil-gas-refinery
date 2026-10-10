"""Publish simulated process-unit telemetry to AWS IoT Core (topic my/refinery/telemetry).

The IoT rule lands each message in S3; Snowpipe loads it into RAW.LIVE_TELEMETRY.
Unit IDs come from RAW.UNITS (RU-0000..RU-0023). Values are seeded random.
"""
import argparse
import json
import random
from datetime import datetime, timezone


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--region', default='us-west-2')
    ap.add_argument('--count', type=int, default=40)
    ap.add_argument('--seed', type=int)
    args = ap.parse_args()
    import boto3
    iot = boto3.client('iot', region_name=args.region)
    endpoint = iot.describe_endpoint(endpointType='iot:Data-ATS')['endpointAddress']
    data = boto3.client('iot-data', region_name=args.region, endpoint_url=f'https://{endpoint}')
    rng = random.Random(args.seed)
    for _ in range(args.count):
        unit = f'RU-{rng.randint(0, 23):04d}'
        alarm = rng.random() < 0.1
        msg = {'unit_id': unit,
               'event_ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3],
               'setpoint_dev_pct': round(rng.gauss(6.5 if alarm else 1.8, 0.6), 2),
               'outlet_temp_c': round(rng.gauss(400 if alarm else 360, 12), 1),
               'status': 'ALARM' if alarm else 'RUNNING'}
        data.publish(topic='my/refinery/telemetry', qos=1, payload=json.dumps(msg))
    print(f'published {args.count} messages to my/refinery/telemetry via {endpoint}')


if __name__ == '__main__':
    main()
