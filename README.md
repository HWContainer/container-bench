create config.env from config.env.tpl


docker login cmd from swr service


sudo make base_image

make server

make metrics

make deploy1

make fortio

python fortio_parser.py  # will parser fortio output from logs

python envparser.py xxx  # wiil parser pod with prefix xxx, default xxx is perf-test


url=perf-test-1 make test

