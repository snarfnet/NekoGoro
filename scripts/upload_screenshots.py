"""Upload screenshots to App Store Connect"""
import os
import hashlib
import time
from pathlib import Path
from asc_api import api, find_app_id, get_or_create_version, get_localization_id

APP_VERSION = os.environ.get("APP_VERSION", "1.0")
SCREENSHOT_DIR = Path(__file__).resolve().parent.parent / "AppStoreScreenshots"

DISPLAY_TYPES = {
    "iphone_67": "APP_IPHONE_67",
    "iphone_65": "APP_IPHONE_65",
    "ipad_pro_129": "APP_IPAD_PRO_129",
}


def upload_screenshots():
    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)
    loc_id = get_localization_id(version_id)
    if not loc_id:
        print("No localization found")
        return

    screenshots = sorted(SCREENSHOT_DIR.glob("*.png"))
    if not screenshots:
        print(f"No screenshots found in {SCREENSHOT_DIR}")
        return

    print(f"Found {len(screenshots)} screenshots")

    existing_sets = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    for ss_set in existing_sets.get("data", []):
        ss_in_set = api("GET", f"/appScreenshotSets/{ss_set['id']}/appScreenshots")
        for item in ss_in_set.get("data", []):
            try:
                api("DELETE", f"/appScreenshots/{item['id']}")
            except RuntimeError:
                pass
    time.sleep(2)

    for display_key, display_type in DISPLAY_TYPES.items():
        for ss in screenshots:
            data = ss.read_bytes()
            md5 = hashlib.md5(data).hexdigest()

            reservation = api("POST", "/appScreenshots", json={
                "data": {
                    "type": "appScreenshots",
                    "attributes": {
                        "fileName": ss.name,
                        "fileSize": len(data),
                    },
                    "relationships": {
                        "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": get_or_create_screenshot_set(loc_id, display_type)}},
                    },
                }
            })

            upload_ops = reservation["data"]["attributes"].get("uploadOperations", [])
            for op in upload_ops:
                url = op["url"]
                headers_list = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
                offset = op["offset"]
                length = op["length"]
                chunk = data[offset:offset + length]
                import requests
                requests.put(url, headers=headers_list, data=chunk)

            ss_id = reservation["data"]["id"]
            api("PATCH", f"/appScreenshots/{ss_id}", json={
                "data": {
                    "type": "appScreenshots",
                    "id": ss_id,
                    "attributes": {"uploaded": True, "sourceFileChecksum": md5},
                }
            })
            print(f"  Uploaded {ss.name} for {display_type}")
            # Wait for screenshot processing
            for _ in range(30):
                time.sleep(5)
                status = api("GET", f"/appScreenshots/{ss_id}")
                state = status["data"]["attributes"].get("assetDeliveryState", {}).get("state", "")
                if state == "COMPLETE":
                    print(f"    Screenshot {ss.name} processing complete")
                    break
                elif state == "FAILED":
                    print(f"    Screenshot {ss.name} processing failed")
                    break
                print(f"    Screenshot state: {state}, waiting...")
            time.sleep(1)


def get_or_create_screenshot_set(loc_id, display_type):
    payload = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    for item in payload.get("data", []):
        if item["attributes"].get("screenshotDisplayType") == display_type:
            return item["id"]

    payload = api("POST", "/appScreenshotSets", json={
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}},
            },
        }
    })
    return payload["data"]["id"]


if __name__ == "__main__":
    upload_screenshots()
