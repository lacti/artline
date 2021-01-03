FROM public.ecr.aws/lambda/python:3.8

RUN yum update -y && yum install -y gcc && \
  pip install -U pip setuptools wheel

COPY requirements.txt ./
RUN python3.8 -m pip install -r requirements.txt -t .

COPY ArtLine_500.pkl ./
COPY app.py art_line.py ./

# Command can be overwritten by providing a different command in the template directly.
CMD ["app.lambda_handler"]
