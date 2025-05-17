FROM dolfinx/dolfinx:stable

ARG TRIAL_FILE

RUN apt-get update && apt-get install -y \
    time \
    && python3 -m pip install tqdm \
    && rm -rf /var/lib/apt/lists/*


COPY scripts/benchmark.sh /root/shared/benchmark.sh
COPY scripts/set_kernel_params.sh /root/shared/set_kernel_params.sh
COPY scripts/get_os_info.sh /root/shared/get_os_info.sh
COPY .env /root/shared/.env
COPY ${TRIAL_FILE} /root/shared/main.py
COPY dependencies/ /root/shared/

RUN chmod +x /root/shared/benchmark.sh /root/shared/get_os_info.sh /root/shared/set_kernel_params.sh

CMD ["/root/shared/benchmark.sh"]
