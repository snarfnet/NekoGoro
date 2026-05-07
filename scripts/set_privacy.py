"""Set App Privacy (appDataUsages) for AdMob apps via ASC API"""
import os
import sys
sys.path.insert(0, os.path.dirname(__file__))

from asc_api import api, find_app_id


def list_privacy_resources():
    """List available categories, groupings, purposes, data protections"""
    for resource in ["appDataUsageCategories", "appDataUsageGroupings", "appDataUsagePurposes", "appDataUsageDataProtections"]:
        print(f"\n=== {resource} ===")
        try:
            payload = api("GET", f"/{resource}?limit=50")
            for item in payload.get("data", []):
                print(f"  {item['id']}: {item.get('attributes', {})}")
        except RuntimeError as e:
            print(f"  Error: {e}")


def get_existing_usages(app_id):
    """Get existing app data usages"""
    try:
        payload = api("GET", f"/apps/{app_id}/appDataUsages?limit=50")
        return payload.get("data", [])
    except RuntimeError:
        return []


def create_data_usage(app_id, category_id, grouping_id, purpose_id, data_protection_id):
    """Create a single app data usage entry"""
    try:
        payload = api("POST", "/appDataUsages", json={
            "data": {
                "type": "appDataUsages",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "category": {"data": {"type": "appDataUsageCategories", "id": category_id}},
                    "grouping": {"data": {"type": "appDataUsageGroupings", "id": grouping_id}},
                    "purpose": {"data": {"type": "appDataUsagePurposes", "id": purpose_id}},
                    "dataProtection": {"data": {"type": "appDataUsageDataProtections", "id": data_protection_id}},
                },
            }
        })
        print(f"  Created: category={category_id} grouping={grouping_id} purpose={purpose_id}")
        return payload
    except RuntimeError as e:
        if "409" in str(e):
            print(f"  Already exists: category={category_id} grouping={grouping_id} purpose={purpose_id}")
        else:
            print(f"  Error: {e}")
        return None


def setup_admob_privacy(app_id):
    """Set up privacy declarations for an AdMob app"""
    # For AdMob, we need to declare:
    # 1. Device ID - Third-Party Advertising - Not Linked to You
    # 2. Advertising Data - Third-Party Advertising - Not Linked to You

    # Category IDs (from ASC API):
    # DEVICE_ID, ADVERTISING_DATA
    # Grouping: DATA_NOT_LINKED_TO_YOU, DATA_LINKED_TO_YOU, DATA_USED_TO_TRACK_YOU
    # Purpose: THIRD_PARTY_ADVERTISING, ANALYTICS
    # DataProtection: DATA_NOT_LINKED_TO_YOU, DATA_LINKED_TO_YOU

    usages = [
        # Device ID for third-party advertising, not linked
        ("DEVICE_ID", "DATA_NOT_LINKED_TO_YOU", "THIRD_PARTY_ADVERTISING", "DATA_NOT_LINKED_TO_YOU"),
        # Advertising Data for third-party advertising, not linked
        ("ADVERTISING_DATA", "DATA_NOT_LINKED_TO_YOU", "THIRD_PARTY_ADVERTISING", "DATA_NOT_LINKED_TO_YOU"),
    ]

    for category, grouping, purpose, protection in usages:
        create_data_usage(app_id, category, grouping, purpose, protection)


def main():
    app_id = find_app_id()
    print(f"App ID: {app_id}")

    existing = get_existing_usages(app_id)
    if existing:
        print(f"Found {len(existing)} existing data usages")
        for item in existing:
            print(f"  {item['id']}: {item.get('attributes', {})}")

    if "--list" in sys.argv:
        list_privacy_resources()
        return

    print("\nSetting up AdMob privacy declarations...")
    setup_admob_privacy(app_id)
    print("\nDone. You may need to verify in App Store Connect.")


if __name__ == "__main__":
    main()
