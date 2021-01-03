build:
	sam build --debug

deploy:
	sam deploy --debug

start:
	sam local invoke --debug --event events/with-image.json

start-api:
	sam local start-api --debug

test:
	PYTHONPATH=transform pytest

