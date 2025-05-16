FROM dolfinx/dolfinx:stable

RUN apt-get update && apt-get install -y \
    time \
    && rm -rf /var/lib/apt/lists/*


COPY benchmark.sh /root/shared/benchmark.sh
COPY set_kernel_params.sh /root/set_kernel_params.sh
COPY get_os_info.sh /root/shared/get_os_info.sh
copy .env /root/shared/.env

RUN chmod +x /root/shared/benchmark.sh /root/shared/get_os_info.sh /root/shared/set_kernel_params.sh

CMD ["root/shared/benchmark.sh"]
