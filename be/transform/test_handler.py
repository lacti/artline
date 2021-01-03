import json

import pytest
import os.path

from app import lambda_handler


@pytest.fixture()
def apigw_event():
    event_file = os.path.join(os.path.dirname(__file__), "..", "events", "with-image.json")
    print("event_file", event_file)
    with open(event_file, "r") as f:
        return json.loads(f.read().encode("utf8"))


def test_lambda_handler(apigw_event, mocker):
    ret = lambda_handler(apigw_event, "")
    assert ret["statusCode"] == 200
    assert len(ret["body"]) > 0
