#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone


def aws_json(args):
    completed = subprocess.run(
        ["aws", *args, "--output", "json"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if not completed.stdout.strip():
        return None
    return json.loads(completed.stdout)


def aws_text(args, allow_failure=False):
    completed = subprocess.run(
        ["aws", *args, "--output", "text"],
        check=not allow_failure,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if completed.returncode != 0:
        return ""
    value = completed.stdout.strip()
    return "" if value == "None" else value


def aws_run(args, allow_failure=False):
    return subprocess.run(
        ["aws", *args],
        check=not allow_failure,
        text=True,
    )


def get_parameter(name):
    if not name:
        return ""
    return aws_text(
        ["ssm", "get-parameter", "--name", name, "--query", "Parameter.Value"],
        allow_failure=True,
    )


def tag_value(tags, key):
    for tag in tags or []:
        if tag.get("Key") == key:
            return tag.get("Value", "")
    return ""


def parse_stopped_at(instance):
    reason = instance.get("StateTransitionReason") or ""
    match = re.search(r"\(([^)]+) GMT\)", reason)
    if match:
        try:
            return datetime.strptime(match.group(1), "%Y-%m-%d %H:%M:%S").replace(
                tzinfo=timezone.utc
            )
        except ValueError:
            pass

    launch_time = instance.get("LaunchTime")
    if launch_time:
        return datetime.fromisoformat(launch_time.replace("Z", "+00:00"))
    return datetime.now(timezone.utc)


def discover_instances(prefix):
    payload = aws_json(
        [
            "ec2",
            "describe-instances",
            "--filters",
            f"Name=tag:Name,Values={prefix}*",
            "Name=instance-state-name,Values=stopped",
        ]
    )
    instances = []
    for reservation in payload.get("Reservations", []):
        instances.extend(reservation.get("Instances", []))
    return instances


def discover_available_volumes(prefixes):
    filters = ["Name=status,Values=available", "Name=volume-type,Values=gp3"]
    payload = aws_json(["ec2", "describe-volumes", "--filters", *filters])
    volumes = []
    for volume in payload.get("Volumes", []):
        name = tag_value(volume.get("Tags"), "Name")
        if any(name.startswith(prefix) for prefix in prefixes):
            volumes.append(
                {
                    "volume_id": volume["VolumeId"],
                    "name": name,
                    "size_gb": volume.get("Size"),
                    "state": volume.get("State"),
                    "volume_type": volume.get("VolumeType"),
                }
            )
    return volumes


def build_inventory(args):
    current_instance_id = get_parameter(args.current_instance_parameter)
    previous_instance_id = get_parameter(args.previous_instance_parameter)
    protected = {item for item in [current_instance_id, previous_instance_id] if item}
    now = datetime.now(timezone.utc)
    candidates = []

    for prefix in args.name_prefix:
        for instance in discover_instances(prefix):
            instance_id = instance["InstanceId"]
            stopped_at = parse_stopped_at(instance)
            stopped_hours = (now - stopped_at).total_seconds() / 3600
            block_devices = []

            for mapping in instance.get("BlockDeviceMappings", []):
                ebs = mapping.get("Ebs") or {}
                volume_id = ebs.get("VolumeId")
                if not volume_id:
                    continue
                block_devices.append(
                    {
                        "device_name": mapping.get("DeviceName"),
                        "volume_id": volume_id,
                        "delete_on_termination": ebs.get("DeleteOnTermination"),
                    }
                )

            if instance_id not in protected and stopped_hours >= args.min_stopped_hours:
                candidates.append(
                    {
                        "instance_id": instance_id,
                        "name": tag_value(instance.get("Tags"), "Name"),
                        "state": instance.get("State", {}).get("Name"),
                        "stopped_at": stopped_at.isoformat(),
                        "stopped_hours": round(stopped_hours, 2),
                        "launch_time": instance.get("LaunchTime"),
                        "instance_type": instance.get("InstanceType"),
                        "block_devices": block_devices,
                    }
                )

    available_volumes = discover_available_volumes(args.name_prefix)

    return {
        "tenant": args.tenant,
        "mode": args.mode,
        "region": args.region,
        "min_stopped_hours": args.min_stopped_hours,
        "protected": {
            "current_instance_id": current_instance_id,
            "previous_instance_id": previous_instance_id,
        },
        "candidate_instances": candidates,
        "candidate_available_volumes": available_volumes,
    }


def create_rollback_ami(args, current_instance_id):
    if not current_instance_id:
        return ""

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    name = f"chatwoot-{args.tenant}-rollback-{timestamp}-{current_instance_id}"
    image_id = aws_text(
        [
            "ec2",
            "create-image",
            "--instance-id",
            current_instance_id,
            "--name",
            name,
            "--description",
            f"Rollback AMI before Chatwoot EBS guard cleanup for {args.tenant}",
            "--no-reboot",
            "--tag-specifications",
            (
                "ResourceType=image,Tags="
                f"[{{Key=Name,Value={name}}},{{Key=Project,Value=chatwoot-autonomia}},"
                f"{{Key=Tenant,Value={args.tenant}}},{{Key=Purpose,Value=rollback-before-ebs-cleanup}}]"
            ),
            "--query",
            "ImageId",
        ]
    )
    aws_run(["ec2", "wait", "image-available", "--image-ids", image_id])
    return image_id


def cleanup(args, inventory):
    has_cleanup_candidates = bool(
        inventory["candidate_instances"] or inventory["candidate_available_volumes"]
    )
    rollback_ami_id = ""
    if has_cleanup_candidates:
        rollback_ami_id = create_rollback_ami(
            args, inventory["protected"]["current_instance_id"]
        )
    terminated_instances = []
    deleted_volumes = []

    for candidate in inventory["candidate_instances"]:
        instance_id = candidate["instance_id"]
        volume_ids = [
            item["volume_id"]
            for item in candidate.get("block_devices", [])
            if item.get("volume_id")
        ]
        aws_run(["ec2", "terminate-instances", "--instance-ids", instance_id])
        terminated_instances.append(instance_id)
        aws_run(["ec2", "wait", "instance-terminated", "--instance-ids", instance_id])

        for volume_id in volume_ids:
            state = aws_text(
                [
                    "ec2",
                    "describe-volumes",
                    "--volume-ids",
                    volume_id,
                    "--query",
                    "Volumes[0].State",
                ],
                allow_failure=True,
            )
            if state == "available":
                aws_run(["ec2", "delete-volume", "--volume-id", volume_id])
                deleted_volumes.append(volume_id)

    for volume in inventory["candidate_available_volumes"]:
        volume_id = volume["volume_id"]
        aws_run(["ec2", "delete-volume", "--volume-id", volume_id])
        deleted_volumes.append(volume_id)

    return {
        "rollback_ami_id": rollback_ami_id,
        "terminated_instances": terminated_instances,
        "deleted_volumes": sorted(set(deleted_volumes)),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tenant", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--mode", choices=["inventory", "cleanup"], default="inventory")
    parser.add_argument("--min-stopped-hours", type=float, default=24)
    parser.add_argument("--name-prefix", action="append", required=True)
    parser.add_argument("--current-instance-parameter", required=True)
    parser.add_argument("--previous-instance-parameter", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    os.environ["AWS_REGION"] = args.region
    os.environ["AWS_DEFAULT_REGION"] = args.region

    inventory = build_inventory(args)
    result = {"inventory": inventory, "cleanup": None}

    if args.mode == "cleanup":
        result["cleanup"] = cleanup(args, inventory)

    with open(args.output, "w", encoding="utf-8") as output:
        json.dump(result, output, indent=2, sort_keys=True)
        output.write("\n")

    summary = {
        "tenant": inventory["tenant"],
        "mode": args.mode,
        "region": inventory["region"],
        "protected": inventory["protected"],
        "candidate_instance_count": len(inventory["candidate_instances"]),
        "candidate_available_volume_count": len(
            inventory["candidate_available_volumes"]
        ),
        "cleanup": result["cleanup"],
        "output": args.output,
    }
    json.dump(summary, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
