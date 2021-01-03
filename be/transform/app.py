import base64
import os.path
import shutil
import tempfile

import numpy as np
import PIL.Image
import torchvision.transforms as T
from fastai.utils.mem import Path
from fastai.vision import load_learner, torch
from fastai.vision.image import Image
from art_line import FeatureLoss  # For pickle


# Copy from https://github.com/vijishmadhavan/ArtLine
learn = load_learner(Path(os.path.dirname(__file__)), 'ArtLine_500.pkl')


def _artline_apply(input_path: str, output_path: str):
    img = PIL.Image.open(input_path).convert("RGB")
    img_t = T.ToTensor()(img)
    img_fast = Image(img_t)

    p, img_hr, b = learn.predict(img_fast)

    # Thanks for https://github.com/vijishmadhavan/ArtLine/issues/10
    output = img_hr.cpu().data[0]
    o = output.numpy()
    o[np.where(o < 0)] = 0.0
    o[np.where(o > 1)] = 1.0
    output = torch.from_numpy(o)
    output = T.ToPILImage()(output)
    output.save(output_path)


def lambda_handler(event, context):
    if not "body" in event or len(event["body"]) == 0:
        return _response(400, "")

    temp_root = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_root, "input.jpg")
        output_path = os.path.join(temp_root, "output.jpg")

        with open(input_path, "wb") as f:
            body_bytes = event["body"].encode('utf8')
            f.write(base64.decodebytes(body_bytes))
        _artline_apply(input_path, output_path)
        with open(output_path, "rb") as f:
            return _response(200, base64.encodebytes(f.read()))
    except:
        import sys
        import traceback
        print("Exception in user code:")
        print("-"*60)
        traceback.print_exc(file=sys.stdout)
        print("-"*60)
        return _response(500, "Internal Server Error")
    finally:
        shutil.rmtree(temp_root)


def _response(status_code: int, body: str):
    return {
        "statusCode": status_code,
        "body": body
    }


if __name__ == '__main__':
    _artline_apply('input.jpg', 'output.jpg')
