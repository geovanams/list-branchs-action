# Imagem do Container que executa o código da action
FROM python:3.8-alpine

RUN pip install requests
RUN pip install sys

COPY main.py /main.py

ENTRYPOINT ["python", "/main.py"]
