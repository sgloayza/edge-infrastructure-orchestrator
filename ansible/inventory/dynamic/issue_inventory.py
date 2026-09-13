#!/usr/bin/env python3
"""
Dynamic Inventory Plugin: Issue-Driven Infrastructure Orchestrator
Inspired by Event-Driven Ansible (EDA) architectures.

This script demonstrates:
1. Dynamic host resolution from an external source (Issue Tracker / CMDB / API).
2. Dual-State Pattern: 'actual_state' (live telemetry/DB values) vs 'desired_state' (from ticket).
3. Concurrency Control: Mutex locking mechanism to avoid concurrent runs on the same node.
"""

import json
import argparse
from typing import Dict, Any


def get_simulated_cmdb_state() -> Dict[str, Any]:
    """Simulates real-world inventory data fetched from a CMDB / Platform API."""
    return {
        "gw-alpha-01": {
            "ansible_host": "192.168.10.11",
            "ansible_user": "edgeadmin",
            "arch": "aarch64",
            "device_model": "OrangePi Zero 3",
            "zone": "Sector-North",
            "status": "active",
            "current_firmware": "v2.1.4",
            "mqtt_broker": "mqtt.local.net",
        },
        "gw-beta-02": {
            "ansible_host": "192.168.10.12",
            "ansible_user": "edgeadmin",
            "arch": "aarch64",
            "device_model": "OrangePi Zero 3",
            "zone": "Sector-South",
            "status": "active",
            "current_firmware": "v2.1.0",
            "mqtt_broker": "mqtt.local.net",
        }
    }


def get_simulated_active_tickets() -> list[Dict[str, Any]]:
    """Simulates pending infrastructure tickets / desired state events."""
    return [
        {
            "ticket_id": "OPS-402",
            "target_host": "gw-alpha-01",
            "action": "upgrade_firmware",
            "stage": "Pending",  # Options: Pending, In-Progress, Review
            "desired_firmware": "v2.2.0",
            "enable_telemetry": True,
            "lock_acquired": False
        },
        {
            "ticket_id": "OPS-405",
            "target_host": "gw-beta-02",
            "action": "remediate_mqtt",
            "stage": "Pending",
            "desired_firmware": "v2.1.0",
            "enable_telemetry": True,
            "lock_acquired": False
        }
    ]


def build_inventory() -> Dict[str, Any]:
    """Generates the Ansible dynamic inventory JSON structure."""
    cmdb_hosts = get_simulated_cmdb_state()
    active_tickets = get_simulated_active_tickets()

    # Mutex check: prevent concurrent runs if any task is already 'In-Progress'
    in_progress = [t for t in active_tickets if t["stage"] == "In-Progress"]
    if in_progress:
        # Lock detected: return empty inventory to enforce mutual exclusion
        return {
            "_meta": {"hostvars": {}},
            "all": {"children": ["active_tickets", "edge_gateways"]},
            "active_tickets": {"hosts": []},
            "edge_gateways": {"hosts": []},
        }

    inventory: Dict[str, Any] = {
        "_meta": {"hostvars": {}},
        "all": {
            "children": ["active_tickets", "edge_gateways"]
        },
        "active_tickets": {"hosts": []},
        "edge_gateways": {"hosts": list(cmdb_hosts.keys())}
    }

    # Populate hostvars for regular edge nodes
    for hostname, host_data in cmdb_hosts.items():
        inventory["_meta"]["hostvars"][hostname] = host_data

    # Populate dual-state hostvars for orchestrated ticket hosts
    for ticket in active_tickets:
        ticket_host_alias = f"ticket_{ticket['ticket_id'].lower()}_{ticket['target_host']}"
        inventory["active_tickets"]["hosts"].append(ticket_host_alias)

        base_host_info = cmdb_hosts.get(ticket["target_host"], {})

        # Merge actual state (prefixed with actual_) and desired state (from ticket)
        dual_state_vars = {
            "ansible_host": base_host_info.get("ansible_host", "127.0.0.1"),
            "ansible_user": base_host_info.get("ansible_user", "edgeadmin"),
            # Actual state preservation:
            "actual_zone": base_host_info.get("zone"),
            "actual_firmware": base_host_info.get("current_firmware"),
            "actual_status": base_host_info.get("status"),
            # Desired state injection:
            "orchestrated_ticket_id": ticket["ticket_id"],
            "orchestrated_action": ticket["action"],
            "target_firmware": ticket["desired_firmware"],
            "enable_telemetry": ticket["enable_telemetry"],
            "concurrency_lock": "ACQUIRED"
        }

        inventory["_meta"]["hostvars"][ticket_host_alias] = dual_state_vars

    return inventory


def main():
    parser = argparse.ArgumentParser(description="Ansible Dynamic Inventory for Issue-Driven Orchestration")
    parser.add_argument("--list", action="store_true", help="List all hosts and variables (Ansible standard)")
    parser.add_argument("--host", action="store", help="Get host-specific variables")
    args = parser.parse_args()

    inventory_data = build_inventory()

    if args.host:
        host_vars = inventory_data.get("_meta", {}).get("hostvars", {}).get(args.host, {})
        print(json.dumps(host_vars, indent=2))
    else:
        print(json.dumps(inventory_data, indent=2))


if __name__ == "__main__":
    main()
