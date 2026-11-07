import boto3
from datetime import datetime, timezone

OUTPUT_FILE = "aws_cost_report.txt"
SNAPSHOT_AGE_DAYS = 90
DEFAULT_REGION = "ap-south-1"


def get_all_regions():
    ec2 = boto3.client("ec2", region_name=DEFAULT_REGION)
    regions = ec2.describe_regions()["Regions"]
    return [r["RegionName"] for r in regions]


def calculate_age_days(date):
    return (datetime.now(timezone.utc) - date).days


def get_stopped_ec2(region):
    data = []

    ec2 = boto3.client("ec2", region_name=region)

    reservations = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": ["stopped"]}]
    )

    for reservation in reservations["Reservations"]:
        for instance in reservation["Instances"]:
            name = ""

            for tag in instance.get("Tags", []):
                if tag["Key"] == "Name":
                    name = tag["Value"]

            launch_time = instance["LaunchTime"]

            data.append({
                "InstanceId": instance["InstanceId"],
                "Name": name,
                "InstanceType": instance["InstanceType"],
                "LaunchTime": launch_time,
                "AgeDays": calculate_age_days(launch_time),
                "Region": region
            })

    return data


def get_detached_volumes(region):
    data = []

    ec2 = boto3.client("ec2", region_name=region)

    volumes = ec2.describe_volumes(
        Filters=[{"Name": "status", "Values": ["available"]}]
    )["Volumes"]

    for vol in volumes:
        data.append({
            "VolumeId": vol["VolumeId"],
            "SizeGB": vol["Size"],
            "VolumeType": vol["VolumeType"],
            "Created": vol["CreateTime"],
            "AgeDays": calculate_age_days(vol["CreateTime"]),
            "Region": region
        })

    return data


def get_old_snapshots(region):
    data = []

    ec2 = boto3.client("ec2", region_name=region)

    snapshots = ec2.describe_snapshots(
        OwnerIds=["self"]
    )["Snapshots"]

    for snap in snapshots:
        age = calculate_age_days(snap["StartTime"])

        if age >= SNAPSHOT_AGE_DAYS:
            data.append({
                "SnapshotId": snap["SnapshotId"],
                "VolumeId": snap.get("VolumeId"),
                "SizeGB": snap["VolumeSize"],
                "StartTime": snap["StartTime"],
                "AgeDays": age,
                "Description": snap.get("Description", ""),
                "Region": region
            })

    return data


def get_unattached_eips(region):
    data = []

    ec2 = boto3.client("ec2", region_name=region)

    addresses = ec2.describe_addresses()["Addresses"]

    for addr in addresses:
        if "AssociationId" not in addr:
            data.append({
                "PublicIp": addr.get("PublicIp"),
                "AllocationId": addr.get("AllocationId"),
                "Region": region
            })

    return data


def get_nat_gateways(region):
    data = []

    ec2 = boto3.client("ec2", region_name=region)

    try:
        ngws = ec2.describe_nat_gateways()["NatGateways"]

        for nat in ngws:
            data.append({
                "NatGatewayId": nat["NatGatewayId"],
                "State": nat["State"],
                "VpcId": nat["VpcId"],
                "SubnetId": nat["SubnetId"],
                "CreateTime": nat["CreateTime"],
                "AgeDays": calculate_age_days(nat["CreateTime"]),
                "Region": region
            })
    except Exception as e:
        print(f"NAT Gateway error in {region}: {e}")

    return data


def get_unused_albs(region):
    data = []

    try:
        elbv2 = boto3.client("elbv2", region_name=region)

        lbs = elbv2.describe_load_balancers()["LoadBalancers"]

        for lb in lbs:

            target_group_count = 0

            try:
                tgs = elbv2.describe_target_groups(
                    LoadBalancerArn=lb["LoadBalancerArn"]
                )["TargetGroups"]

                for tg in tgs:
                    health = elbv2.describe_target_health(
                        TargetGroupArn=tg["TargetGroupArn"]
                    )

                    target_group_count += len(
                        health["TargetHealthDescriptions"]
                    )

            except Exception:
                pass

            if target_group_count == 0:
                data.append({
                    "LoadBalancerName": lb["LoadBalancerName"],
                    "DNSName": lb["DNSName"],
                    "Type": lb["Type"],
                    "Region": region
                })

    except Exception as e:
        print(f"ALB error in {region}: {e}")

    return data


def write_txt_report(
    stopped_ec2,
    detached_vols,
    snapshots,
    eips,
    nat_gateways,
    albs
):
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:

        f.write("=" * 80 + "\n")
        f.write("AWS COST OPTIMIZATION REPORT\n")
        f.write("=" * 80 + "\n\n")

        f.write("SUMMARY\n")
        f.write("-" * 40 + "\n")
        f.write(f"Stopped EC2            : {len(stopped_ec2)}\n")
        f.write(f"Detached EBS Volumes   : {len(detached_vols)}\n")
        f.write(f"Old Snapshots          : {len(snapshots)}\n")
        f.write(f"Unused Elastic IPs     : {len(eips)}\n")
        f.write(f"Unused ALBs            : {len(albs)}\n")
        f.write(f"NAT Gateways           : {len(nat_gateways)}\n\n")

        f.write("=" * 80 + "\n")
        f.write("STOPPED EC2 INSTANCES\n")
        f.write("=" * 80 + "\n")

        for ec2 in stopped_ec2:
            f.write(
                f"{ec2['InstanceId']} | "
                f"{ec2['Name']} | "
                f"{ec2['InstanceType']} | "
                f"{ec2['AgeDays']} days | "
                f"{ec2['Region']}\n"
            )

        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("DETACHED EBS VOLUMES\n")
        f.write("=" * 80 + "\n")

        for vol in detached_vols:
            f.write(
                f"{vol['VolumeId']} | "
                f"{vol['SizeGB']} GB | "
                f"{vol['VolumeType']} | "
                f"{vol['AgeDays']} days | "
                f"{vol['Region']}\n"
            )

        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("OLD SNAPSHOTS (>90 DAYS)\n")
        f.write("=" * 80 + "\n")

        for snap in snapshots:
            f.write(
                f"{snap['SnapshotId']} | "
                f"{snap['SizeGB']} GB | "
                f"{snap['AgeDays']} days | "
                f"{snap['Region']}\n"
            )

        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("UNATTACHED ELASTIC IPS\n")
        f.write("=" * 80 + "\n")

        for eip in eips:
            f.write(
                f"{eip['PublicIp']} | "
                f"{eip['AllocationId']} | "
                f"{eip['Region']}\n"
            )

        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("NAT GATEWAYS\n")
        f.write("=" * 80 + "\n")

        for nat in nat_gateways:
            f.write(
                f"{nat['NatGatewayId']} | "
                f"{nat['State']} | "
                f"{nat['AgeDays']} days | "
                f"{nat['Region']}\n"
            )

        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("ALBS WITH NO TARGETS\n")
        f.write("=" * 80 + "\n")

        for alb in albs:
            f.write(
                f"{alb['LoadBalancerName']} | "
                f"{alb['Type']} | "
                f"{alb['Region']}\n"
            )
	

def main():

    stopped_ec2 = []
    detached_vols = []
    snapshots = []
    eips = []
    nat_gateways = []
    albs = []

    sts = boto3.client("sts", region_name=DEFAULT_REGION)
    account_id = sts.get_caller_identity()["Account"]
    print(f"Scanning AWS Account: {account_id}")
    
    regions = get_all_regions()
    print(f"Scanning {len(regions)} regions...")

    for region in regions:
        print(f"Scanning {region}")

        stopped_ec2.extend(get_stopped_ec2(region))
        detached_vols.extend(get_detached_volumes(region))
        snapshots.extend(get_old_snapshots(region))
        eips.extend(get_unattached_eips(region))
        nat_gateways.extend(get_nat_gateways(region))
        albs.extend(get_unused_albs(region))

    write_txt_report(
	stopped_ec2,
	detached_vols,
	snapshots,
	eips,
	nat_gateways,
	albs
	)
    
    print(f"\nReport generated: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
