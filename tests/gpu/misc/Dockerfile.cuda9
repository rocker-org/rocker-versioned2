FROM rocker/ml-gpu

RUN apt-get update && apt-get install -y --no-install-recommends \
  cuda-samples-9-0 \
  python3-dev \
  python3-pip \
  python3-venv

RUN pip install --upgrade tensorflow

WORKDIR /usr/local/cuda-9.0/samples
RUN make

COPY ./test-gpu.sh /test-gpu.sh
RUN chmod +x /test-gpu.sh

ENTRYPOINT ["tail"]
CMD ["-f","/dev/null"]
